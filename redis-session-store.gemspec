Gem::Specification.new do |gem|
  gem.name = 'redis-session-store'
  gem.authors = ['Mathias Meyer']
  gem.email = ['meyer@paperplanes.de']
  gem.summary = 'A drop-in replacement for e.g. MemCacheStore to ' \
                'store Rails sessions (and Rails sessions only) in Redis.'
  gem.description = gem.summary + ' For great glory!'
  gem.homepage = 'https://github.com/roidrage/redis-session-store'
  gem.license = 'MIT'

  gem.extra_rdoc_files = %w(LICENSE AUTHORS.md CONTRIBUTING.md)

  gem.files = `git ls-files -z`.split("\x0")
  gem.require_paths = %w(lib)
  gem.version = File.read('lib/redis-session-store.rb')
                    .match(/^  VERSION = '(.*)'/)[1]

  gem.add_runtime_dependency 'actionpack', '>= 3', '< 8'
  gem.add_runtime_dependency 'redis', '>= 3', '< 5'

  gem.add_development_dependency 'fakeredis', '~> 0.8'
  gem.add_development_dependency 'rake', '~> 13'
  gem.add_development_dependency 'rspec', '~> 3'
  gem.add_development_dependency 'rubocop', '~> 0.81'
  gem.add_development_dependency 'simplecov', '~> 0.17'
end
