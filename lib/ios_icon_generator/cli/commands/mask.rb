# frozen_string_literal: true

require 'fileutils'
require 'base64'
require 'colored2'
require 'parallel'
require 'ruby-progressbar'
require 'ios_icon_generator/helpers/mask_icon'
require 'hanami/cli'

module IOSIconGenerator
  module CLI
    module Commands
      module Build
        class Icon < Hanami::CLI::Command
          desc 'Generate app icons'
          argument :appiconset_path, required: true, desc: 'The unmasked pdf icon. The icon must be at least 1024x1024'
          argument :output_path, default: '.', desc: "The path to your .xcassets folder. \
            If not specified, the appiconsets will be generated in the current folder and can be draged\'n\'dropped there in xcode"
          option :suffix, default: 'Beta', desc: 'The prefix to add to the original app icon set'
          option :background_color, default: '#AD0000', desc: 'The background color of the mask'
          option :symbol, default: 'b', desc: 'The symbol to use to generate the mask.'
          option :font, default: 'Helvetica', desc: 'The font to use to generate the symbol.'
          option :file, default: nil, desc: 'The path to an image representing the symbol to use to generate the mask.'
          option :x_size_ratio, type: :float, default: 0.5478515625, desc: 'The x offset of the size of the mask.'
          option :y_size_ratio, type: :float, default: 0.5478515625, desc: 'The y offset of the size of the mask.'
          option :size_offset, type: :float, default: 0.12, desc: 'The size offset to use when applying the symbol. 0.0 means it\'s scale to the full image, 1.0 means the symbol has the full size of the logo.'
          option :x_offset, type: :float, default: 0.11, desc: 'The x offset to use when applying the symbol. 0.0 means bottom, 1.0 means top.'
          option :y_offset, type: :float, default: 0.11, desc: 'The y offset to use when applying the symbol. 0.0 means left, 1.0 means top.'
          option :mask_shape, default: 'triangle', desc: 'The shape of the form. Can only be either of \'triangle\' or \'square\'.'
          option :parallel_processes, type: :integer, default: -1, desc: 'Number of processes to use to process the files. Defaults to -1, meaning the number of cores the machine. \
            Set to 0 to disable parallel processing.'
          def call(appiconset_path:, output_path:, **options)
            raise "#{'ImageMagick'.blue.bold} is required. It can be installed via #{'homebrew'.bold.underlined} using #{'brew install imagemagick'.blue.bold.underlined}" unless Library.which('magick')

            raise 'There is no App icon set at the path specified.' unless Dir.exist?(appiconset_path)

            progress_bar = ProgressBar.create(total: nil)
            parallel_processes = options.fetch(:parallel_processes).to_i
            parallel_processes = nil if parallel_processes == -1
            Helpers.mask_icon(
              appiconset_path: appiconset_path,
              output_folder: output_path,
              mask: {
                background_color: options.fetch(:background_color),
                suffix: options.fetch(:suffix),
                symbol: options.fetch(:symbol),
                font: options.fetch(:font),
                file: options[:file],
                x_size_ratio: options.fetch(:x_size_ratio)&.to_f,
                y_size_ratio: options.fetch(:y_size_ratio)&.to_f,
                size_offset: options.fetch(:size_offset)&.to_f,
                x_offset: options.fetch(:x_offset)&.to_f,
                y_offset: options.fetch(:y_offset)&.to_f,
                shape: options.fetch(:mask_shape)&.to_sym,
              },
              parallel_processes: parallel_processes,
              progress: lambda do |progress, total|
                progress_bar.total = total unless progress_bar.total
                progress_bar.increment if progress
              end
            )
            puts 'Completed!'.green
          end
        end
      end

      register 'mask', Build::Icon
    end
  end
end
