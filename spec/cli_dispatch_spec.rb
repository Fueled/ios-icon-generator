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
require 'stringio'

# Regression coverage for the CLI dispatch layer.
#
# Ruby 3 stopped converting a trailing Hash into keyword arguments, so a CLI
# framework that invokes `command.call(args)` no longer binds the commands'
# keyword parameters and every command dies with an ArgumentError before its
# body runs. See https://github.com/Fueled/ios-icon-generator/issues/22.
#
# These drive the runner through the IO and kernel it already accepts for
# injection rather than through aruba, so they exercise dispatch on its own:
# no subprocess, and no ImageMagick required.
RSpec.describe IOSIconGenerator::CLI::Runner do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:exit_statuses) { [] }
  let(:kernel) do
    statuses = exit_statuses
    Class.new { define_method(:exit) { |status| statuses << status } }.new
  end

  def run_cli(*argv)
    described_class.new(argv, StringIO.new, stdout, stderr, kernel).execute!
    stdout.string + stderr.string
  end

  it 'dispatches a command that declares no arguments' do
    output = run_cli('version')

    expect(exit_statuses).to eq([0])
    expect(output).to include(IOSIconGenerator::VERSION)
  end

  it 'binds declared arguments as keywords on the command' do
    # `mask` guards on `appiconset_path` as the very first thing it does, so
    # reaching that error proves the argument arrived as a keyword rather than
    # as a positional Hash.
    output = run_cli('mask', '/this/path/does/not/exist')

    expect(output).to include('There is no App icon set at the path specified.')
    expect(output).to_not include('wrong number of arguments')
  end

  it 'reports usage instead of raising when a required argument is missing' do
    output = run_cli('generate')

    expect(output).to include('was called with no arguments')
    expect(output).to_not include('wrong number of arguments')
  end

  it 'registers every documented command' do
    # The program name comes from $0, so match on the command names only.
    output = run_cli

    expect(output).to include('generate ICON_PATH', 'mask APPICONSET_PATH', 'stub TEXT', 'version')
  end
end
