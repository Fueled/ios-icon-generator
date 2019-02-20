# frozen_string_literal: true

require 'json'
require 'base64'
require 'fileutils'

module IOSIconGenerator
  module Helpers
    def self.mask_icon(
      appiconset_path:,
      output_folder:,
      mask: {
        background_color: '#AD0000',
        suffix: 'Beta',
        symbol: 'b',
        font: 'Helvetica',
        x_size_ratio: 0.5478515625,
        y_size_ratio: 0.5478515625,
        size_offset: 0.0,
        x_offset: 0.0,
        y_offset: 0.0,
      },
      parallel_processes: nil,
      progress: nil
    )
      extension = File.extname(appiconset_path)
      output_folder = File.join(output_folder, "#{File.basename(appiconset_path, extension)}-#{mask[:suffix]}#{extension}")

      FileUtils.mkdir_p(output_folder)

      contents_path = File.join(appiconset_path, 'Contents.json')
      raise "Contents.json file not found in #{appiconset_path}" unless File.exist?(contents_path)

      images = JSON.parse(File.read(contents_path))['images']
      progress&.call(nil, images.count)
      Parallel.each(
        images,
        in_processes: parallel_processes,
        finish: lambda do |_item, i, _result|
          progress&.call(i, images.count)
        end
      ) do |image|
        width, height = /(\d+(?:\.\d)?)x(\d+(?:\.\d)?)/.match(image['size'])&.captures
        scale, = /(\d+(?:\.\d)?)x/.match(image['scale'])&.captures
        raise "Invalid size parameter in Contents.json: #{image['size']}" if width.nil? || height.nil? || scale.nil?

        scale = scale.to_f
        width = width.to_f * scale
        height = height.to_f * scale

        mask_size_width = width * mask[:x_size_ratio].to_f
        mask_size_height = height * mask[:y_size_ratio].to_f

        extension = File.extname(image['filename'])
        icon_output = "#{File.basename(image['filename'], extension)}-#{mask[:suffix]}#{extension}"
        icon_output_path = File.join(output_folder, icon_output)

        command =
          if mask[:file]
            "convert '#{File.join(appiconset_path, image['filename'])}' -strokewidth 0 -fill '#{mask[:background_color]}' -draw \"polyline 0,#{height - mask_size_height} 0,#{height} #{mask_size_width},#{height}\" \\( -background none -density 1536 -resize #{width * mask[:size_offset]}x#{height} \"#{mask[:file]}\" -geometry +#{width * mask[:x_offset]}+#{height * mask[:y_offset]} \\) -gravity southwest -composite '#{icon_output_path}'" # rubocop:disable Metrics/LineLength
          else
            "convert '#{File.join(appiconset_path, image['filename'])}' -strokewidth 0 -fill '#{mask[:background_color]}' -draw \"polyline 0,#{height - mask_size_height} 0,#{height} #{mask_size_width},#{height}\" -fill '#FFFFFF' -font '#{mask[:font]}' -pointsize #{height * mask[:size_offset] * 2.0} -annotate +#{width * mask[:x_offset]}+#{height - height * mask[:y_offset]} '#{mask[:symbol]}' '#{icon_output_path}'" # rubocop:disable Metrics/LineLength
          end
        system(command)

        image['filename'] = icon_output
      end
    end
  end
end
