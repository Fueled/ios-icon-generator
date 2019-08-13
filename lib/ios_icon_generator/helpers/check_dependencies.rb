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

require 'ios_icon_generator/helpers/which'

module IOSIconGenerator
  module Helpers
    def self.check_dependencies(requires_ghostscript: false)
      raise "#{'ImageMagick'.blue.bold} is required. It can be installed via #{'homebrew'.bold.underlined} using #{'brew install imagemagick'.blue.bold.underlined}" unless Helpers.which('magick')
      raise "#{'GhostScript'.blue.bold} is required. It can be installed via #{'homebrew'.bold.underlined} using #{'brew install ghostscript'.blue.bold.underlined}" \
        if requires_ghostscript && !Helpers.which('gs')
    end
  end
end
