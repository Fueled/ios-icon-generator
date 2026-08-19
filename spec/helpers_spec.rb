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


require 'spec_helper.rb'
require 'tmpdir'
require 'ios_icon_generator/helpers/execute'
require 'ios_icon_generator/helpers/generate_icon'
require 'ios_icon_generator/helpers/which'

RSpec.describe IOSIconGenerator::Helpers do
  describe '.execute' do
    it 'returns quietly when the command succeeds' do
      expect { described_class.execute('true') }.to_not raise_error
    end

    it 'raises when the command exits non-zero' do
      # Previously the return value of `system` was dropped, so a failed
      # ImageMagick call left an empty icon set behind a "Completed!" message.
      expect { described_class.execute('false') }.to raise_error(RuntimeError, /failed/)
    end

    it 'raises when the command does not exist' do
      expect { described_class.execute('no-such-binary-8f3a1c') }.to raise_error(RuntimeError, /failed/)
    end

    it 'names the failing command in the message' do
      expect { described_class.execute('false', '--flag') }.to raise_error(/false --flag/)
    end
  end

  describe '.image_dimensions', if: IOSIconGenerator::Helpers.which('magick') do
    around do |example|
      Dir.mktmpdir { |dir| @dir = dir and example.run }
    end

    it 'reads the dimensions out of the image, not out of the file name' do
      # Regression test for #21: parsing the default `identify` output matched
      # the file name first, so this 64x64 icon reported itself as 512x512.
      path = File.join(@dir, 'logo-512x512.png')
      described_class.execute('magick', '-size', '64x64', 'xc:red', path)

      expect(described_class.image_dimensions(path)).to eq([64, 64])
    end

    it 'raises on a file that is not an image' do
      path = File.join(@dir, 'not-an-image.png')
      File.write(path, 'certainly not a png')

      expect { described_class.image_dimensions(path) }.to raise_error(RuntimeError)
    end
  end
end
