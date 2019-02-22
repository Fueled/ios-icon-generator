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

require 'simplecov'
require 'simplecov-console'

formatters = [
  SimpleCov::Formatter::Console,
  SimpleCov::Formatter::HTMLFormatter,
]

if ENV['CI'] == 'true'
  require 'codecov'
  formatters << SimpleCov::Formatter::Codecov
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(formatters)

SimpleCov.start do
  add_filter %r{^/spec/}
end

require 'bundler/setup'
require 'aruba/rspec'
require 'ios_icon_generator/cli/runner'

RSpec.configure do |config|
  config.include Aruba::Api

  config.example_status_persistence_file_path = '.rspec_status'

  config.disable_monkey_patching!

  config.expect_with :rspec do |config|
    config.syntax = :expect
  end

  config.before :each do
    setup_aruba
  end
end

Aruba.configure do |config|
  config.exit_timeout = 120.0
  config.io_wait_timeout = 1.0
  config.command_launcher = :in_process
  config.main_class = IOSIconGenerator::CLI::Runner
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

::Dir.glob(::File.expand_path('../support/*.rb', __FILE__)).each { |f| require_relative f }
::Dir.glob(::File.expand_path('../support/**/*.rb', __FILE__)).each { |f| require_relative f }
