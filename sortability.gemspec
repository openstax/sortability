$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'sortability/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'sortability'
  s.version     = Sortability::VERSION
  s.authors     = ['Dante Soares', 'JP Slavinsky']
  s.email       = ['Dante.M.Soares@rice.edu']
  s.homepage    = 'https://github.com/openstax/sortability'
  s.summary     = 'Rails gem that provides easy to use ordered records'
  s.description = 'Provides ActiveRecord methods that make it easy to allow users to sort and reorder records in a list'
  s.license     = 'MIT'

  s.files = Dir['{lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['spec/**/*']

  s.add_dependency 'rails', '>= 5', '< 7'

  s.add_development_dependency 'sqlite3', '< 2.0'
  s.add_development_dependency 'rspec-rails'
end
