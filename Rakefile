require 'rubygems'
require 'rake/gempackagetask'
require 'rubygems/specification'

spec = Gem::Specification.new do |s|
  s.name = 'redis-session-store'
  s.version = '0.1.6'
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["LICENSE"]
  s.summary = "A drop-in replacement for e.g. MemCacheStore to store Rails sessions (and Rails sessions only) in Redis."
  s.description = s.summary
  s.authors = "Mathias Meyer"
  s.email = "meyer@paperplanes.de"
  s.homepage = "http://github.com/mattmatt/redis-session-store"
  s.add_dependency "redis"
  s.require_path = 'lib'
  s.files = %w(README.md Rakefile) + Dir.glob("{lib}/**/*")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end
