Gem::Specification.new do |gem|
  gem.name = 'redis-session-store'
  gem.authors = ['Mathias Meyer']
  gem.email = ['meyer@paperplanes.de']
  gem.summary = 'A drop-in replacement for e.g. MemCacheStore to ' \
                'store Rails sessions (and Rails sessions only) in Redis.'
  gem.description = "#{gem.summary} For great glory!"
  gem.homepage = 'https://github.com/roidrage/redis-session-store'
  gem.license = 'MIT'

  gem.extra_rdoc_files = %w(LICENSE AUTHORS.md CONTRIBUTING.md)

  gem.files = `git ls-files -z`.split("\x0")
  gem.require_paths = %w(lib)
  gem.version = File.read('lib/redis-session-store.rb')
                    .match(/^  VERSION = '(.*)'/)[1]

  gem.add_runtime_dependency 'actionpack', '>= 5.2.4.1', '< 9'
  gem.add_runtime_dependency 'redis', '>= 3', '< 6'

  gem.add_development_dependency 'fakeredis', '~> 0.8'
  gem.add_development_dependency 'rake', '~> 13'
  gem.add_development_dependency 'rspec', '~> 3'
  gem.add_development_dependency 'rubocop', '~> 1.25'
  gem.add_development_dependency 'rubocop-rake', '~> 0.6'
  gem.add_development_dependency 'rubocop-rspec', '~> 2.8'
  gem.add_development_dependency 'simplecov', '~> 0.21'
end
