# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|

  gem.authors       = ["Mathias Meyer"]
  gem.email         = ["meyer@paperplanes.de"]
  gem.summary       = "A drop-in replacement for e.g. MemCacheStore to store Rails sessions (and Rails sessions only) in Redis."
  gem.description   = gem.summary
  gem.homepage      = "http://github.com/mattmatt/redis-session-store"

  gem.has_rdoc         = true
  gem.extra_rdoc_files = ["LICENSE"]

  gem.files         = %w(README.md Rakefile) + ['lib/redis-session-store.rb']
  gem.name          = "redis-session-store"
  gem.require_paths = ["lib"]
  gem.version       = '0.1.9'

  gem.add_dependency "redis"
end
