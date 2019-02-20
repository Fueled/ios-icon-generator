# frozen_string_literal: true

require 'colored2'
require 'parallel'
require 'ruby-progressbar'
require 'ios_icon_generator/helpers/generate_icon'
require 'ios_icon_generator/helpers/which'
require 'hanami/cli'

module IOSIconGenerator
  module CLI
    module Commands
      class Stub < Hanami::CLI::Command
        desc 'Generate stub app icons'
        argument :text, required: true, desc: 'The text to use when generating the icon.'
        argument :xcasset_folder, default: '.', desc: "The path to your .xcassets folder. \
          If not specified, the appiconsets will be generated in the current folder and can be draged\'n\'dropped there in xcode"
        option :background_color, default: '#FFFFFF', desc: 'The background color of the mask'
        option :symbol, default: 'b', desc: 'The symbol to use.'
        option :font, default: 'Helvetica', desc: 'The font to use to generate the symbol.'
        option :symbol_color, default: '#7F0000', desc: 'The color of the symbol to use to generate the mask.'
        option :stroke_color, default: '#000000', desc: 'The stroke color of the mask'
        option :stroke_width_offset, type: :float, default: 0.1, desc: 'The width of the stroke used when generating the symbol.'
        option :size_offset, type: :float, default: 0.5, desc: 'The point size used for the symbol, relative to the height of the icon. Values over 0.5 are not recommended.'
        option :x_offset, type: :float, default: 0.0, desc: 'The x offset to use when applying the symbol. 0.0 means bottom, 1.0 means top.'
        option :y_offset, type: :float, default: 0.0, desc: 'The y offset to use when applying the symbol. 0.0 means left, 1.0 means top.'
        option :type, type: :array, default: %w[iphone], desc: 'Which target to generate the icons for. Can be "iphone", "ipad", "watch", "mac" or "carplay" or a combination of any of them, or "imessage"'
        option :parallel_processes, type: :integer, default: -1, desc: 'Number of processes to use to process the files. Defaults to -1, meaning the number of cores the machine. \
          Set to 0 to disable parallel processing.'
        def call(text:, xcasset_folder:, type:, **options)
          raise "#{'ImageMagick'.blue.bold} is required. It can be installed via #{'homebrew'.bold.underlined} using #{'brew install imagemagick'.blue.bold.underlined}" unless Library.which('magick')

          types = type.map(&:to_sym)

          progress_bar = ProgressBar.create(total: nil)

          parallel_processes = options.fetch(:parallel_processes).to_i
          parallel_processes = nil if parallel_processes == -1
          Helpers.generate_icon(
            icon_path: nil,
            output_folder: xcasset_folder,
            types: types,
            parallel_processes: parallel_processes,
            generate_icon: lambda do |_base_path, target_path, width, height|
              system(
                'magick',
                '-size',
                "#{width}x#{height}",
                "xc:#{options.fetch(:background_color)}",
                '-strokewidth',
                (options.fetch(:stroke_width_offset).to_f * [width, height].min).to_s,
                '-stroke',
                (options.fetch(:stroke_width_offset).to_f.zero? ? 'none' : options.fetch(:stroke_color)).to_s,
                '-fill',
                options.fetch(:symbol_color),
                '-gravity',
                'center',
                '-font',
                options.fetch(:font),
                '-pointsize',
                (height * options.fetch(:size_offset).to_f).to_s,
                '-annotate',
                "+#{width * options.fetch(:x_offset).to_f}+#{height * -options.fetch(:y_offset).to_f}",
                text,
                target_path
              )
            end,
            progress: lambda do |progress, total|
              progress_bar.total = total unless progress_bar.total
              progress_bar.increment if progress
            end
          )
          puts "\nCompleted!".green
        end
      end

      register 'stub', Commands::Stub
    end
  end
end
