# frozen_string_literal: true

require 'hanami/cli'

module IOSIconGenerator
  module CLI
    module Commands
      class Version < Hanami::CLI::Command
        desc 'Print version'
        def call(*)
          puts IOSIconGenerator::VERSION
        end
      end

      register 'version', Version, aliases: ['v', '-v', '--version']
    end
  end
end