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

require 'json'

module IOSIconGenerator
  module Helpers
    ##
    # Get the image sets for the given types.
    #
    # @param [Symbol, #read] types The types to return the sets of image for.
    #        This method won't fail if the types aren't compatible as defined by +type_incompatible?+
    #
    # @return [Array<Hash<String, String>>] The sets of image for the given types.
    #         Each hash will at least contain a +size+ [String] key, that has the format +<width>x<height>+
    def self.image_sets(types)
      types.flat_map do |type|
        contents_path = File.expand_path(File.join(File.dirname(__FILE__), "../../../vendor/Contents-#{type}.json"))
        raise "Unknown type #{type}" unless File.exist?(contents_path)

        contents_json = JSON.parse(File.read(contents_path))
        contents_json['images']
      end
    end

    ##
    # Check if the given types are compatible (if they can be used in the same set)
    #
    # @param [Symbol, #read] lhs The first type to check against the second type.
    # @param [Symbol, #read] rhs The second type to check against the first type.
    #
    # @return [Boolean] +true+ if the given are compatible together, +false+ otherwise
    def self.type_incompatible?(lhs, rhs)
      (lhs == :imessage && rhs != :imessage) || (lhs != :imessage && rhs == :imessage)
    end
  end
end
