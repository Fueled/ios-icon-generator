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

require 'ios_icon_generator'

module IOSIconGenerator
  module CLI
    class Runner
      def initialize(argv, stdin = STDIN, stdout = STDOUT, stderr = STDERR, kernel = Kernel)
        @argv = argv
        @trace_enabled = argv.include?('--trace')
        @argv.reject! { |v| v == '--trace' }
        @argv = argv
        @stdin = stdin
        @stdout = stdout
        @stderr = stderr
        @kernel = kernel
      end

      def execute!
        exit_code =
          begin
            $stderr = @stderr
            $stdin = @stdin
            $stdout = @stdout

            Hanami::CLI.new(IOSIconGenerator::CLI::Commands).call(arguments: @argv)

            0
          rescue StandardError => e
            if @trace_enabled
              @stderr.puts "ERROR: #{e.message}".red
            else
              @stderr.puts("#{e.backtrace.shift}: #{e.message} (#{e.class})")
              @stderr.puts(e.backtrace.map { |s| "\tfrom #{s}" }.join("\n"))
            end
            1
          rescue SystemExit => e
            e.status
          ensure
            $stderr = STDERR
            $stdin = STDIN
            $stdout = STDOUT
          end

        # Proxy our exit code back to the injected kernel.
        @kernel.exit(exit_code)
      end
    end
  end
end
