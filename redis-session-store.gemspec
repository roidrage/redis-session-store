# vim:fileencoding=utf-8

Gem::Specification.new do |gem|
  gem.authors      = ['Mathias Meyer']
  gem.email        = ['meyer@paperplanes.de']
  gem.summary      = 'A drop-in replacement for e.g. MemCacheStore to store Rails sessions (and Rails sessions only) in Redis.'
  gem.description  = gem.summary
  gem.homepage     = 'https://github.com/roidrage/redis-session-store'
  gem.license      = 'MIT'

  gem.has_rdoc         = true
  gem.extra_rdoc_files = %w(LICENSE AUTHORS.md CONTRIBUTING.md)

  gem.files = %w(
    AUTHORS.md
    CONTRIBUTING.md
    Gemfile
    LICENSE
    README.md
    Rakefile
    lib/redis-session-store.rb
    test/fake_action_dispatch_session_abstract_store.rb
    test/redis_session_store_test.rb
  )

  gem.name          = 'redis-session-store'
  gem.require_paths = ['lib']
  gem.version       = '0.2.1'

  gem.add_dependency 'redis'
end
