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
require 'phashion'
require 'fileutils'
require 'json'

resources_path = File.expand_path(File.join(File.dirname(__FILE__), 'resources'))

RSpec.shared_examples :icon_generation_examples do |command, parameter, options = nil, result_folder = nil|
  it('executes successfully') do
    FileUtils.rm_rf(File.join(resources_path, 'generated'))
    run_command(
      "icongen \
        #{command} '#{parameter}' \
        '#{File.join(resources_path, "generated/#{result_folder || command}.xcassets")}' \
        #{options} \
        --parallel-processes=0"
    )
    expect(last_command_started).to be_successfully_executed
  end
  it('has the right file structure') do
    generated_relative_paths = Dir.glob(File.join(resources_path, "generated/#{result_folder || command}.xcassets/**/*")).map do |path|
      Pathname.new(path).relative_path_from(Pathname.new(File.join(resources_path, 'generated'))).to_s
    end
    expected_relative_paths = Dir.glob(File.join(resources_path, "expected/#{result_folder || command}.xcassets/**/*")).map do |path|
      Pathname.new(path).relative_path_from(Pathname.new(File.join(resources_path, 'expected'))).to_s
    end
    expect(generated_relative_paths.sort).to match_array(expected_relative_paths.sort)
  end
  it('creates the proper icons') do
    icons = Dir.glob(File.join(resources_path, "expected/#{result_folder || command}.xcassets/**/*.png"))
    expect(icons).to_not match_array([])
    icons.each do |expected_path|
      relative_path = Pathname.new(expected_path).relative_path_from(Pathname.new(File.join(resources_path, 'expected'))).to_s
      generated_path = File.join(resources_path, 'generated', relative_path)
      expect(File).to exist(generated_path)
      generated_image = Phashion::Image.new(generated_path)
      expected_image = Phashion::Image.new(expected_path)
      expect(generated_image.duplicate?(expected_image, threshold: 1)).to be true # Not sure if it should be 1 (a very small difference) or 0 (identical), this will be determined by how the CLI evolves
    end
  end
  it('generate a valid contents.json') do
    generated_contents_json = Dir.glob(File.join(resources_path, "generated/#{result_folder || command}.xcassets/**/Contents.json")).first
    expected_contents_json = Dir.glob(File.join(resources_path, "expected/#{result_folder || command}.xcassets/**/Contents.json")).first
    expect(JSON.parse(File.read(generated_contents_json))).to match_array(JSON.parse(File.read(expected_contents_json)))
  end
  it('generate a pretty printed contents.json') do
    generated_contents_json = Dir.glob(File.join(resources_path, "generated/#{result_folder || command}.xcassets/**/Contents.json")).first
    content = File.read(generated_contents_json)
    expect(content).to be == JSON.pretty_generate(JSON.parse(content))
  end
end

RSpec.describe IOSIconGenerator, type: :aruba do
  it 'has a version number' do
    expect(IOSIconGenerator::VERSION).not_to be nil
  end
  describe 'version' do
    before(:each) do
      run_command('icongen version')
    end
    it('print the right version') do
      expect(last_command_started.stdout.strip).to start_with(IOSIconGenerator::VERSION)
    end
  end

  describe 'generate' do
    it('fails if the icon is unknown') do
      FileUtils.rm_rf(File.join(resources_path, 'generated'))
      run_command(
        "icongen \
          generate '' \
          '#{File.join(resources_path, 'generated/error.xcassets')}'"
      )
      expect(last_command_started).to_not be_successfully_executed
    end
    it('fails if the icon is invalid') do
      FileUtils.rm_rf(File.join(resources_path, 'generated'))
      run_command(
        "icongen \
          generate '/test.pdf' \
          '#{File.join(resources_path, 'generated/error.xcassets')}'"
      )
      expect(last_command_started).to_not be_successfully_executed
    end
    context 'a stub' do
      include_examples :icon_generation_examples, 'stub', 'A', '--type=iphone,ipad,watch,mac,carplay'
    end
    context 'an icon' do
      include_examples :icon_generation_examples, 'generate', File.join(resources_path, 'generate.pdf'), '--type=iphone,ipad,watch,mac,carplay'
    end
  end
  describe 'mask' do
    context 'a triangle mask from a stub' do
      include_examples :icon_generation_examples,
                       'mask',
                       File.join(resources_path, 'expected/stub.xcassets/AppIcon.appiconset'),
                       nil,
                       'mask-triangle-stub'
    end
    context 'a triangle mask from a generated icon' do
      include_examples :icon_generation_examples,
                       'mask',
                       File.join(resources_path, 'expected/generate.xcassets/AppIcon.appiconset'),
                       nil,
                       'mask-triangle-generated'
    end
    context 'a square mask from a stub' do
      include_examples :icon_generation_examples,
                       'mask',
                       File.join(resources_path, 'expected/stub.xcassets/AppIcon.appiconset'),
                       '--mask-shape=square \
                         --x-size-ratio=0.30 \
                         --y-size-ratio=0.30 \
                         --size-offset=0.11 \
                         --x-offset=0.1 \
                         --y-offset=0.1 \
                         --background-color=\'#A36AE9\' \
                         --stroke-width-offset=0 \
                         --font=Symbol \
                         --symbol-color=\'#FFFFFF\'',
                       'mask-square-stub'
    end
    context 'a square mask from a generated icon' do
      include_examples :icon_generation_examples,
                       'mask',
                       File.join(resources_path, 'expected/generate.xcassets/AppIcon.appiconset'),
                       '--mask-shape=square \
                         --x-size-ratio=0.30 \
                         --y-size-ratio=0.30 \
                         --size-offset=0.11 \
                         --x-offset=0.1 \
                         --y-offset=0.1 \
                         --background-color=\'#A36AE9\' \
                         --stroke-width-offset=0 \
                         --font=Symbol \
                         --symbol-color=\'#FFFFFF\'',
                       'mask-square-generated'
    end
  end
end
