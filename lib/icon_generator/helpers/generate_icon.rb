# frozen_string_literal: true

require 'json'
require 'base64'
require 'fileutils'

module IconGenerator
  module Helpers
    def self.generate_icon(icon_path:, output_folder:, type:, parallel_processes: nil, progress: nil)
      matches = /(\d+)x(\d+)/.match(`magick identify "#{icon_path}"`)
      raise 'Unable to verify icon. Please make sure it\'s a valid pdf file and try again.' if matches.nil?

      width, height = matches.captures
      raise 'Invalid pdf specified.' if width.nil? || height.nil?

      raise "The icon must at least be 1024x1024, it currently is #{width}x#{height}." unless width.to_i >= 1024 && height.to_i >= 1024

      appiconset_path = File.join(output_folder, "#{type == :imessage ? 'iMessage App Icon' : 'AppIcon'}.#{type == :imessage ? 'stickersiconset' : 'appiconset'}")

      FileUtils.mkdir_p(appiconset_path)

      generate_icon = lambda { |base_path, width, height|
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
          File.join(appiconset_path, "App-Icon-#{width}x#{height}.png")
        )
      }

      case type
      when :iphoneipad
        smaller_sizes = [[20, 20], [29, 29], [40, 40], [58, 58], [60, 60], [76, 76], [80, 80], [87, 87], [120, 120], [152, 152], [167, 167], [180, 180]]
      when :iphone
        smaller_sizes = [[40, 40], [58, 58], [60, 60], [80, 80], [87, 87], [120, 120], [180, 180]]
      when :ipad
        smaller_sizes = [[20, 20], [29, 29], [40, 40], [58, 58], [76, 76], [80, 80], [152, 152], [167, 167]]
      when :imessage
        generate_icon.call(icon_path, 1024, 768)
        smaller_sizes = [[58, 58], [87, 87], [120, 90], [180, 135], [134, 100], [148, 110], [54, 40], [81, 60], [64, 48], [96, 72]]
      end

      total = smaller_sizes.count + 3
      progress&.call(nil, total)

      generate_icon.call(icon_path, 1024, 1024)
      progress&.call(0, total)

      max_size = smaller_sizes.flatten.max
      temp_icon_path = File.join(output_folder, '.temp_icon.pdf')
      begin
        system('magick', 'convert', '-density', '400', icon_path, '-colorspace', 'sRGB', '-type', 'truecolor', '-scale', "#{max_size}x#{max_size}", temp_icon_path)
        progress&.call(1, total)
        Parallel.each(
          smaller_sizes,
          in_processes: parallel_processes,
          finish: lambda do |_item, i, _result|
            progress&.call(i + 2, total)
          end
        ) do |width, height|
          generate_icon.call(temp_icon_path, width, height)
        end
      ensure
        FileUtils.rm(temp_icon_path) if File.exist?(temp_icon_path)
      end

      File.open("#{appiconset_path}/Contents.json", 'w') do |file|
        case type
        when :iphoneipad
          file.write("{\n  \"images\" : [\n    {\n      \"size\" : \"20x20\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-40x40.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"20x20\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-60x60.png\",\n      \"scale\" : \"3x\"\n    },\n    {\n      \"size\" : \"29x29\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-58x58.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"29x29\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-87x87.png\",\n      \"scale\" : \"3x\"\n    },\n    {\n      \"size\" : \"40x40\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-80x80.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"40x40\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-120x120.png\",\n      \"scale\" : \"3x\"\n    },\n    {\n      \"size\" : \"60x60\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-120x120.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"60x60\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-180x180.png\",\n      \"scale\" : \"3x\"\n    },\n    {\n      \"size\" : \"20x20\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-20x20.png\",\n      \"scale\" : \"1x\"\n    },\n    {\n      \"size\" : \"20x20\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-40x40.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"29x29\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-29x29.png\",\n      \"scale\" : \"1x\"\n    },\n    {\n      \"size\" : \"29x29\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-58x58.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"40x40\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-40x40.png\",\n      \"scale\" : \"1x\"\n    },\n    {\n      \"size\" : \"40x40\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-80x80.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"76x76\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-76x76.png\",\n      \"scale\" : \"1x\"\n    },\n    {\n      \"size\" : \"76x76\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-152x152.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"83.5x83.5\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-167x167.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"1024x1024\",\n      \"idiom\" : \"ios-marketing\",\n      \"filename\" : \"App-Icon-1024x1024.png\",\n      \"scale\" : \"1x\"\n    }\n  ],\n  \"info\" : {\n    \"version\" : 1,\n    \"author\" : \"xcode\"\n  }\n}") # rubocop:disable Metrics/LineLength
        when :iphone
          file.write("{\n  \"images\" : [\n    {\n      \"size\" : \"20x20\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-40x40.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"20x20\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-60x60.png\",\n      \"scale\" : \"3x\"\n    },\n    {\n      \"size\" : \"29x29\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-58x58.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"29x29\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-87x87.png\",\n      \"scale\" : \"3x\"\n    },\n    {\n      \"size\" : \"40x40\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-80x80.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"40x40\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-120x120.png\",\n      \"scale\" : \"3x\"\n    },\n    {\n      \"size\" : \"60x60\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-120x120.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"60x60\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-180x180.png\",\n      \"scale\" : \"3x\"\n    },\n    {\n      \"size\" : \"1024x1024\",\n      \"idiom\" : \"ios-marketing\",\n      \"filename\" : \"App-Icon-1024x1024.png\",\n      \"scale\" : \"1x\"\n    }\n  ],\n  \"info\" : {\n    \"version\" : 1,\n    \"author\" : \"xcode\"\n  }\n}") # rubocop:disable Metrics/LineLength
        when :ipad
          file.write("{\n  \"images\" : [\n    {\n      \"size\" : \"20x20\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-20x20.png\",\n      \"scale\" : \"1x\"\n    },\n    {\n      \"size\" : \"20x20\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-40x40.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"29x29\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-29x29.png\",\n      \"scale\" : \"1x\"\n    },\n    {\n      \"size\" : \"29x29\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-58x58.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"40x40\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-40x40.png\",\n      \"scale\" : \"1x\"\n    },\n    {\n      \"size\" : \"40x40\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-80x80.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"76x76\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-76x76.png\",\n      \"scale\" : \"1x\"\n    },\n    {\n      \"size\" : \"76x76\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-152x152.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"83.5x83.5\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-167x167.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"1024x1024\",\n      \"idiom\" : \"ios-marketing\",\n      \"filename\" : \"App-Icon-1024x1024.png\",\n      \"scale\" : \"1x\"\n    }\n  ],\n  \"info\" : {\n    \"version\" : 1,\n    \"author\" : \"xcode\"\n  }\n}") # rubocop:disable Metrics/LineLength
        when :imessage
          file.write("{\n  \"images\" : [\n    {\n      \"size\" : \"29x29\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-58x58.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"29x29\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-87x87.png\",\n      \"scale\" : \"3x\"\n    },\n    {\n      \"size\" : \"60x45\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-120x90.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"60x45\",\n      \"idiom\" : \"iphone\",\n      \"filename\" : \"App-Icon-180x135.png\",\n      \"scale\" : \"3x\"\n    },\n    {\n      \"size\" : \"29x29\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-58x58.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"67x50\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-134x100.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"74x55\",\n      \"idiom\" : \"ipad\",\n      \"filename\" : \"App-Icon-148x110.png\",\n      \"scale\" : \"2x\"\n    },\n    {\n      \"size\" : \"1024x1024\",\n      \"idiom\" : \"ios-marketing\",\n      \"filename\" : \"App-Icon-1024x1024.png\",\n      \"scale\" : \"1x\"\n    },\n    {\n      \"size\" : \"27x20\",\n      \"idiom\" : \"universal\",\n      \"filename\" : \"App-Icon-54x40.png\",\n      \"scale\" : \"2x\",\n      \"platform\" : \"ios\"\n    },\n    {\n      \"size\" : \"27x20\",\n      \"idiom\" : \"universal\",\n      \"filename\" : \"App-Icon-81x60.png\",\n      \"scale\" : \"3x\",\n      \"platform\" : \"ios\"\n    },\n    {\n      \"size\" : \"32x24\",\n      \"idiom\" : \"universal\",\n      \"filename\" : \"App-Icon-64x48.png\",\n      \"scale\" : \"2x\",\n      \"platform\" : \"ios\"\n    },\n    {\n      \"size\" : \"32x24\",\n      \"idiom\" : \"universal\",\n      \"filename\" : \"App-Icon-96x72.png\",\n      \"scale\" : \"3x\",\n      \"platform\" : \"ios\"\n    },\n    {\n      \"size\" : \"1024x768\",\n      \"idiom\" : \"ios-marketing\",\n      \"filename\" : \"App-Icon-1024x768.png\",\n      \"scale\" : \"1x\",\n      \"platform\" : \"ios\"\n    }\n  ],\n  \"info\" : {\n    \"version\" : 1,\n    \"author\" : \"xcode\"\n  }\n}") # rubocop:disable Metrics/LineLength
        end
      end

      progress&.call(total - 1, total)
    end
  end
end
