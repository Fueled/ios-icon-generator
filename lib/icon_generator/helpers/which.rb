# frozen_string_literal: true

module IconGenerator
  module Library
    ##
    # Cross-platform way of finding an executable in the +$PATH+.
    #
    # From http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
    #
    # == Parameters:
    # +cmd+::
    #   The name of the command to search the path for.
    #
    # == Returns:
    # The full path to the command if found, and +nil+ otherwise.
    def self.which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end
      nil
    end
  end
end
