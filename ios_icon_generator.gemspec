# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ios_icon_generator/version'

Gem::Specification.new do |spec|
  spec.name = 'ios_icon_generator'
  spec.version       = IOSIconGenerator::VERSION
  spec.authors       = ['Stéphane Copin']
  spec.email         = ['stephane@fueled.com']

  spec.summary       = 'Generates icons based and apply masks to them easily.'
  spec.homepage      = 'https://github.com/Fueled/ios-icon-generator'

  spec.files         = Dir['lib/**/*.rb'] + Dir['vendor/**/*.json'] + %w[bin/icongen README.md]
  spec.executables   = %w[icongen]
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'colored2'
  spec.add_runtime_dependency 'hanami-cli'
  spec.add_runtime_dependency 'parallel'
  spec.add_runtime_dependency 'ruby-progressbar'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'danger'
  spec.add_development_dependency 'danger-rubocop'
  spec.add_development_dependency 'debase'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.64.0'
  spec.add_development_dependency 'ruby-debug-ide'
end
