# encoding: utf-8

Gem::Specification.new do |gem|
  gem.name    = 'audited-activerecord'
  gem.version = '3.1'

  gem.authors     = ['Brandon Keepers', 'Kenneth Kalmer', 'Daniel Morrison', 'Brian Ryckbost', 'Steve Richert', 'Ryan Glover']
  gem.email       = 'info@collectiveidea.com'
  gem.description = 'Log all changes to your ActiveRecord models'
  gem.summary     = gem.description
  gem.homepage    = 'https://github.com/collectiveidea/audited'

  gem.add_dependency 'audited', gem.version
  gem.add_dependency 'activerecord', '~> 3.0'

  gem.files         = `git ls-files lib`.split($\).grep(/(active_?record|generators)/)
  gem.require_paths = ['lib']
end

