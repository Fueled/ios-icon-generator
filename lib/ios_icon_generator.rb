# frozen_string_literal: true

require 'ios_icon_generator/version'
require 'rubygems'
require 'colored2'
require 'hanami/cli'

# The IOSIconGenerator module
module IOSIconGenerator
  # :nodoc:
  module CLI
    # :nodoc:
    module Commands
      extend Hanami::CLI::Registry
    end
  end

  ##
  # The helpers used by the commands of IOSIconGenerator.
  module Helpers
  end
end

require 'ios_icon_generator/cli/commands/generate'
require 'ios_icon_generator/cli/commands/mask'
require 'ios_icon_generator/cli/commands/stub'
