# frozen_string_literal: true

require 'colored2'
require 'parallel'
require 'ruby-progressbar'
require 'icon_generator/helpers/generate_icon'
require 'icon_generator/helpers/which'
require 'hanami/cli'

module IconGenerator
  module CLI
    module Commands
      class Generate < Hanami::CLI::Command
        desc 'Generate app icons'
        argument :icon_path, required: true, desc: 'The unmasked pdf icon. The icon must be at least 1024x1024'
        argument :xcasset_folder, default: '.', desc: "The path to your .xcassets folder. \
          If not specified, the appiconsets will be generated in the current folder and can be draged\'n\'dropped there in xcode"
        option :type, type: :array, default: %w[iphone ipad imessage], desc: 'Which target to generate the icons for. Can be "iphone", "ipad", "iphone,ipad" or "imessage"'
        option :parallel_processes, type: :integer, default: -1, desc: 'Number of processes to use to process the files. Defaults to -1, meaning the number of cores the machine. \
          Set to 0 to disable parallel processing.'
        def call(icon_path:, xcasset_folder:, type:, **options)
          raise "#{'ImageMagick'.blue.bold} is required. It can be installed via #{'homebrew'.bold.underlined} using #{'brew install imagemagick'.blue.bold.underlined}" unless Library.which('magick')

          raise 'There is no icon at the path specified.' unless File.exist?(icon_path)

          FileUtils.mkdir_p xcasset_folder
          raise 'The icon specified must be .pdf.' if File.extname(icon_path) != '.pdf'

          if type.nil? || type.empty? || (type.include?('iphone') && type.include?('ipad'))
            type = :iphoneipad
          elsif type.include?('iphone')
            type = :iphone
          elsif type.include?('ipad')
            type = :ipad
          elsif type.include?('imessage')
            type = :imessage
          else
            raise "Unknown type(s) specified: #{type}"
          end
          matches = /(\d+)x(\d+)/.match(`magick identify "#{icon_path}"`)
          raise 'Unable to verify icon. Please make sure it\'s a valid pdf file and try again.' if matches.nil?

          width, height = matches.captures
          raise 'Invalid pdf specified.' if width.nil? || height.nil?

          raise "The icon must at least be 1024x1024, it currently is #{width}x#{height}." if width.to_i < 1024 || height.to_i < 1024

          progress_bar = ProgressBar.create(total: nil)

          parallel_processes = options.fetch(:parallel_processes).to_i
          parallel_processes = nil if parallel_processes == -1
          Helpers.generate_icon(
            icon_path: icon_path,
            output_folder: xcasset_folder,
            type: type,
            parallel_processes: parallel_processes,
            progress: lambda do |progress, total|
              progress_bar.total = total unless progress_bar.total
              progress_bar.increment if progress
            end
          )
          puts "\nCompleted!".green
        end
      end

      register 'generate', Commands::Generate
    end
  end
end
