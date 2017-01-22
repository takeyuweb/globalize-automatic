$:.push File.expand_path('../lib', __FILE__)

require 'globalize/automatic/version'

Gem::Specification.new do |s|
  s.name        = 'globalize-automatic'
  s.version     = Globalize::Automatic::VERSION
  s.authors     = ['Yuichi Takeuchi']
  s.email       = ['info@takeyu-web.com']
  s.homepage    = 'htts://github.com/takeyuweb/globalize-automatic/'
  s.summary     = 'Adapter for using automatic translation gems with Globalize'
  s.description = 'Provides support for using automatic translation gems with Globalize.'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'globalize', '~> 5.0'
  s.add_dependency 'globalize-accessors'
  s.add_dependency 'easy_translate'

  s.add_development_dependency 'rails', '~> 4.2.0'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rspec-rails'
end
