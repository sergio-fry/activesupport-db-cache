# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require File.expand_path('../lib/activesupport-db-cache', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Sergei O. Udalov"]
  gem.email         = ["sergei.udalov@gmail.com"]
  gem.description   = %q{ActiveRecord DB Store engine for ActiveSupport::Cache}
  gem.summary       = %q{ActiveRecord DB Store engine for ActiveSupport::Cache}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "activesupport-db-cache"
  gem.require_paths = ["lib"]
  gem.version       = ActiveSupport::Cache::ActiveRecordStore::VERSION

  gem.add_dependency "activesupport", ">=3.0.0"
  gem.add_dependency "activerecord", ">=3.0.0"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency "timecop"
end
