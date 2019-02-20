# frozen_string_literal: true

require 'json'

module IOSIconGenerator
  module Helpers
    def self.images_sets(types)
      types.flat_map do |type|
        contents_path = File.expand_path(File.join(File.dirname(__FILE__), "../../../vendor/Contents-#{type}.json"))
        raise "Unknown type #{type}" unless File.exist?(contents_path)

        contents_json = JSON.parse(File.read(contents_path))
        contents_json['images']
      end
    end

    def self.type_incompatible?(lhs, rhs)
      (lhs == :imessage && rhs != :imessage || lhs != :imessage && rhs == :imessage)
    end
  end
end
