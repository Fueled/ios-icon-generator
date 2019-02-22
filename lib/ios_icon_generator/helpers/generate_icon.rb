# frozen_string_literal: true

# Copyright (c) 2019 Fueled Digital Media, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'json'
require 'fileutils'
require 'ios_icon_generator/helpers/image_sets_definition'

module IOSIconGenerator
  module Helpers
    ##
    # Generate an icon using the base icon provided.
    #
    # If +icon_path+ is set to +nil+, the function expects +generate_icon+ to be set or the function will raise.
    #
    # @param [String, #read] icon_path The path to the icon to use as the base icon.
    #        If specified, it must point to a valid pdf file (with a .pdf extension), with a resolution over 1024x1024.
    #        If not specified, +generate_icon+ must be specified.
    # @param [String, #read] output_folder The folder to create the app icon set in.
    # @param [Array<Symbol>, #read] types The types to generate the sets of images for. Each type must be one of +:iphone+, +:ipad+, +:watch+, +mac+ or +carplay+, or it can be an array of just +:imessage+.
    # @param [Symbol, #read] parallel_processes The number of processes to use when generating the icons.
    #        +nil+ means it'll use as many processes as they are cores on the machine.
    #        +0+ will disables spawning any processes.
    # @param [Lambda(base_path [String], target_path [String], width [Float], height [Float]), #read] generate_icon The lambda that actually generates the icon.
    #        If none is specified, and default one will be used.
    #        It should take four parameters:
    #        - +base_path+: The base path to the reference image to use to generate the new icon. If +icon_path+ is set to +nil+, the +base_path+ parameter will +nil+ as well.
    #        - +target_path+: The path to generate the icon at.
    #        - +width+: The width of the icon to generate.
    #        - +height+: The height of the icon to generate.
    # @param [Lambda(progress [Int], total [Int]), #read] progress An optional progress block called when progress has been made generating the icons.
    #        It should take two parameters:
    #        - +progress+: An integer indicating the current progress out of +total+
    #        - +total+: An integer indicating the total progress
    #
    # @return [String] Return the path to the generated app icon set.
    def self.generate_icon(icon_path:, output_folder:, types:, parallel_processes: nil, generate_icon: nil, progress: nil)
      if icon_path
        raise "There is no icon at #{icon_path}." unless File.exist?(icon_path)

        raise 'The icon specified must be .pdf.' if File.extname(icon_path) != '.pdf'

        matches = /(\d+)x(\d+)/.match(`magick identify "#{icon_path}"`)
        raise 'Unable to verify icon. Please make sure it\'s a valid pdf file and try again.' if matches.nil?

        width, height = matches.captures
        raise 'Invalid pdf specified.' if width.nil? || height.nil?

        raise "The icon must at least be 1024x1024, it currently is #{width}x#{height}." unless width.to_i >= 1024 && height.to_i >= 1024
      elsif generate_icon.nil?
        raise 'icon_path has been set to nil, generate_icon must be specified'
      end
      appiconset_path = File.join(output_folder, "#{types.include?(:imessage) ? 'iMessage App Icon' : 'AppIcon'}.#{types.include?(:imessage) ? 'stickersiconset' : 'appiconset'}")

      FileUtils.mkdir_p(appiconset_path)

      get_icon_path = lambda { |width, height|
        return File.join(appiconset_path, "Icon-#{width.to_i}x#{height.to_i}.png")
      }

      generate_icon ||= lambda { |base_path, target_path, width, height|
        size = [width, height].max
        system(
          'magick',
          'convert',
          '-density',
          '400',
          base_path,
          '-colorspace',
          'sRGB',
          '-type',
          'truecolor',
          '-resize', "#{size}x#{size}",
          '-gravity',
          'center',
          '-crop',
          "#{width}x#{height}+0+0",
          '+repage',
          target_path
        )
      }

      types.each do |type1|
        types.each do |type2|
          raise "Incompatible types used together: #{type1} and #{type2}. These types cannot be added to the same sets; please call the command twice with each different type." if Helpers.type_incompatible?(type1, type2)
        end
      end

      images_sets = Helpers.image_sets(types)

      smaller_sizes = []
      images_sets.each do |image|
        width, height = /(\d+(?:\.\d)?)x(\d+(?:\.\d)?)/.match(image['size'])&.captures
        scale, = /(\d+(?:\.\d)?)x/.match(image['scale'])&.captures
        raise "Invalid size parameter in Contents.json: #{image['size']}" if width.nil? || height.nil? || scale.nil?

        scale = scale.to_f
        width = width.to_f * scale
        height = height.to_f * scale

        target_path = get_icon_path.call(width, height)
        image['filename'] = File.basename(target_path)
        if width > 512 || height > 512
          generate_icon.call(
            icon_path,
            target_path,
            width,
            height
          )
        else
          smaller_sizes << [width, height]
        end
      end

      total = smaller_sizes.count + 2
      progress&.call(nil, total)

      max_size = smaller_sizes.flatten.max
      temp_icon_path = File.join(output_folder, '.temp_icon.pdf')
      begin
        system('magick', 'convert', '-density', '400', icon_path, '-colorspace', 'sRGB', '-type', 'truecolor', '-scale', "#{max_size}x#{max_size}", temp_icon_path) if icon_path
        progress&.call(1, total)
        Parallel.each(
          smaller_sizes,
          in_processes: parallel_processes,
          finish: lambda do |_item, i, _result|
            progress&.call(i + 1, total)
          end
        ) do |width, height|
          generate_icon.call(
            temp_icon_path,
            get_icon_path.call(width, height),
            width,
            height
          )
        end
      ensure
        FileUtils.rm(temp_icon_path) if File.exist?(temp_icon_path)
      end

      contents_json = {
        images: images_sets,
        info: {
          version: 1,
          author: 'xcode',
        },
      }

      File.write(File.join(appiconset_path, 'Contents.json'), JSON.pretty_generate(contents_json))

      progress&.call(total - 1, total)

      appiconset_path
    end
  end
end
