# frozen_string_literal: true

require 'icon_generator/version'
require 'rubygems'
require 'colored2'
require 'hanami/cli'

# The IconGenerator module
module IconGenerator
  # :nodoc:
  module CLI
    # :nodoc:
    module Commands
      extend Hanami::CLI::Registry
    end
  end

  ##
  # The helpers used by the commands of IconGenerator.
  module Helpers
  end
end

require 'icon_generator/cli/commands/generate'
