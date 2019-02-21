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

require 'colored2'
require 'parallel'
require 'ruby-progressbar'
require 'ios_icon_generator/helpers/generate_icon'
require 'ios_icon_generator/helpers/which'
require 'hanami/cli'

module IOSIconGenerator
  module CLI
    module Commands
      class Generate < Hanami::CLI::Command
        desc 'Generate app icons'
        argument :icon_path, required: true, desc: 'The unmasked pdf icon. The icon must be at least 1024x1024'
        argument :xcasset_folder, default: '.', desc: "The path to your .xcassets folder. \
          If not specified, the appiconsets will be generated in the current folder and can be draged\'n\'dropped there in xcode"
        option :type, type: :array, default: %w[iphone], desc: 'Which target to generate the icons for. Can be "iphone", "ipad", "watch", "mac" or "carplay" or a combination of any of them, or "imessage"'
        option :parallel_processes, type: :integer, default: -1, desc: 'Number of processes to use to process the files. Defaults to -1, meaning the number of cores the machine. \
          Set to 0 to disable parallel processing.'
        def call(icon_path:, xcasset_folder:, type:, **options)
          raise "#{'ImageMagick'.blue.bold} is required. It can be installed via #{'homebrew'.bold.underlined} using #{'brew install imagemagick'.blue.bold.underlined}" unless Helpers.which('magick')

          types = type.map(&:to_sym)

          progress_bar = ProgressBar.create(total: nil)

          parallel_processes = options.fetch(:parallel_processes).to_i
          parallel_processes = nil if parallel_processes == -1
          Helpers.generate_icon(
            icon_path: icon_path,
            output_folder: xcasset_folder,
            types: types,
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
