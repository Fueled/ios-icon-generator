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

module IOSIconGenerator
  module Helpers
    ##
    # Run an external command, raising if it does not succeed.
    #
    # +system+ returns +false+ on a non-zero exit and +nil+ when the binary is
    # missing. Ignoring that lets an ImageMagick failure pass for success, so
    # the CLI reports +Completed!+ over an empty icon set.
    #
    # @param [Array<String>] command The command and its arguments.
    #
    # @raise [RuntimeError] If the command exits non-zero or cannot be run.
    def self.execute(*command)
      return if system(*command)

      raise "The command `#{command.join(' ')}` failed. Re-run with --trace for the full backtrace."
    end
  end
end
