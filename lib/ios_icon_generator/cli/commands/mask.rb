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

require 'fileutils'
require 'base64'
require 'colored2'
require 'parallel'
require 'ruby-progressbar'
require 'ios_icon_generator/helpers/mask_icon'
require 'ios_icon_generator/helpers/check_dependencies'
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
          option :background_color, default: '#FFFFFF', desc: 'The background color of the mask'
          option :stroke_color, default: '#000000', desc: 'The stroke color of the mask'
          option :stroke_width_offset, type: :float, default: 0.01, desc: 'The width of the stroke used when generating the mask\'s background.'
          option :symbol, default: 'b', desc: 'The symbol to use to generate the mask.'
          option :symbol_color, default: '#7F0000', desc: 'The color of the symbol to use to generate the mask.'
          option :font, default: 'Helvetica', desc: 'The font to use to generate the symbol.'
          option :file, default: nil, desc: 'The path to an image representing the symbol to use to generate the mask.'
          option :x_size_ratio, type: :float, default: 0.54, desc: 'The x offset of the size of the mask.'
          option :y_size_ratio, type: :float, default: 0.54, desc: 'The y offset of the size of the mask.'
          option :size_offset, type: :float, default: 0.12, desc: 'The size offset to use when applying the symbol. 0.0 means it\'s scale to the full image, 1.0 means the symbol has the full size of the logo.'
          option :x_offset, type: :float, default: 0.11, desc: 'The x offset to use when applying the symbol. 0.0 means bottom, 1.0 means top.'
          option :y_offset, type: :float, default: 0.11, desc: 'The y offset to use when applying the symbol. 0.0 means left, 1.0 means top.'
          option :mask_shape, default: 'triangle', desc: 'The shape of the form. Can only be either of \'triangle\' or \'square\'.'
          option :parallel_processes, type: :integer, default: -1, desc: 'Number of processes to use to process the files. Defaults to -1, meaning the number of cores the machine. \
            Set to 0 to disable parallel processing.'
          def call(appiconset_path:, output_path:, **options)
            raise 'There is no App icon set at the path specified.' unless Dir.exist?(appiconset_path)

            progress_bar = ProgressBar.create(total: nil)
            parallel_processes = options.fetch(:parallel_processes).to_i
            parallel_processes = nil if parallel_processes == -1
            Helpers.mask_icon(
              appiconset_path: appiconset_path,
              output_folder: output_path,
              mask: {
                background_color: options.fetch(:background_color),
                stroke_color: options.fetch(:stroke_color),
                stroke_width_offset: options.fetch(:stroke_width_offset)&.to_f,
                suffix: options.fetch(:suffix),
                symbol: options.fetch(:symbol),
                symbol_color: options.fetch(:symbol_color),
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
