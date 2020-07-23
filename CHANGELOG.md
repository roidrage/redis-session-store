# Change Log

**ATTN**: This project uses [semantic versioning](http://semver.org/).

## [Unreleased]

## [0.11.3] - 2020-07-23
### Fixed
- https://github.com/roidrage/redis-session-store/issues/121

## [0.11.2] - 2020-07-22
### Changed
- Silence deprecation warning when using with redis gem v4.2+

## [0.11.1] - 2019-08-22
### Changed
- Remove the `has_rdoc` parameter from the `.gemspec` file as it has been deprecated.
- Actionpack to '>= 3', remove upper dependency

## [0.11.0] - 2018-08-13
### Changed
- JRuby to jruby-9.2.0.0
- Travis Ruby support: 2.3.7, 2.4.4, 2.5.1

### Added
- :ttl configuration option

## [0.10.0] - 2018-04-14
### Changed
- JRuby to jruby-9.1.15.0
- Redis to '>= 3', '< 5'
- Actionpack to '>= 3', '< 6'
- Rake to 12

### Added
- with_indifferent_access if defined ActiveSupport

## [0.9.2] - 2017-10-31
### Changed
- Actionpack to 5.1
- Travis use jruby 9.1.13.0

## [0.9.1] - 2016-07-03
### Added
- More specific runtime dependencies

### Changed
- Documentation and whitespace

## [0.9.0] - 2016-07-02
### Added
- [`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md)
- Method alias for `#delete_session` -&gt; `#destroy_session`

### Changed
- Tested version of Ruby 2 up to 2.3.1
- Session config examples to use `redis: { url: '...' }`

### Removed
- Ruby 1.9.3 support due to Rack 2 requirements

## [0.8.1] - 2016-01-25
### Added
- Support for Rails 5 and Rack 2

### Changed
- Error support for redis-rb v3 gem

## [0.8.0] - 2014-08-28
### Added
- Allow for injection of custom redis client
- Explicitly declare actionpack dependency

### Changed
- Spec updates for rspec 3

## [0.7.0] - 2014-04-22
### Fixed
- Issue #38, we now delay writing to redis until a session exists. This is a
  backwards-incompatible change, as it removes the `on_sid_collision` option.
  There is now no checking for sid collisions, however that is very unlikely.

## [0.6.6] - 2014-04-08
### Fixed
- Issue #37, use correct constant for `ENV_SESSION_OPTIONS_KEY` if not passed.

## [0.6.5] - 2014-04-04
### Fixed
- Issue #36, use setnx to get a new session id instead of get. This prevents a
  very rare id collision.

## [0.6.4] - 2014-04-04
### Removed
- `#setnx` usage in v0.6.3 so we can change our sessions

## [0.6.3] - 2014-04-01
### Changed
- Setting session ID with a multi-call `#setnx` and `#expire` instead of
  `#setex`.

### Removed
- `#setnx` change in v0.6.2 as it behaved badly under load, hitting yet another
  race condition issue and pegging the CPU.

## [0.6.2] - 2014-03-31
### Changed
- Use `#setnx` instead of `#get` when checking for session ID collisions, which
  is slightly more paranoid and should help avoid a particularly nasty edge
  case.

## [0.6.1] - 2014-03-17
### Fixed
- Compatibility with `ActionDispatch::Request::Session::Options` when destroying
  sessions.

## [0.6.0] - 2014-03-17
### Added
- Custom serializer configuration
- Custom handling capability for session load errors

### Changed
- Always destroying sessions that cannot be loaded

## [0.5.0] - 2014-03-16
### Added
- Support for `on_sid_collision` handler option
- Support for `on_redis_down` handler option

### Changed
- Keep generating session IDs until one is found that doesn't collide
  with existing session IDs

### Removed
- **BACKWARD INCOMPATIBLE** Drop support for `:raise_errors` option

## [0.4.2] - 2014-03-14
### Changed
- Renaming `load_session` method to not conflict with AbstractStore

## [0.4.1] - (2014-03-13) [YANKED]
### Changed
- Regenerate session ID when session is missing

## [0.4.0] - 2014-02-19
### Added
- Support for `ENV_SESSION_OPTIONS_KEY` rack env option
- Support for `:raise_errors` session option (kinda like Dalli)

### Changed
- Increasing test coverage

## [0.3.1] - 2014-02-19
### Added
- `#destroy_session` method

### Changed
- Clean up remaining RuboCop offenses
- Documentation updates

## [0.3.0] - 2014-02-13
### Added
- Rails 3 compatibility
- Add test coverage

### Changed
- Switch from minitest to rspec
- RuboCop cleanup

## [0.2.4] - 2014-03-16
### Changed
- Keep generating session IDs until one is found that doesn't collide
  with existing session IDs

## [0.2.3] - 2014-03-14
### Changed
- Renaming `load_session` method to not conflict with AbstractStore

## [0.2.2] - 2014-03-13 [YANKED]
### Changed
- Regenerate session ID when session is missing

## [0.2.1] - 2013-09-17
### Added
- Explicit MIT license metadata in gemspec

## [0.2.0] - 2013-09-13
### Added
- Gemfile, gemspec, and git updates
- `#destroy` method
- Travis integration
- Some minimal tests to ensure backward compatibility session options

### Changed
- Nest redis-specific options inside a `:redis` key of session options
- Rescue only `Errno::ECONNREFUSED` exceptions
- Handle `nil` cookies during `#destroy`

## [0.1.9] - 2012-03-06
### Changed
- Use `@redis.setex` when expiry provided, else `@redis.set`
- gemification
- Options hash to no longer expect redis options at same level

## [0.1.8] - 2010-12-09
### Removed
- Use of `@redis.pipelined`

## 0.1.7 - 2010-12-08
### Changed
- Using latest redis gem API

## 0.1.6 - 2010-04-18
### Changed
- Using pipelined format with `set` and `expire`
- Changing default port from 6370 to 6379

## 0.1.5 - 2010-04-07

## 0.1.4 - 2010-03-26
### Changed
- Redis parameter from `:server` to `:host`

## 0.1.3 - 2009-12-30
### Changed
- Documentation updates

## 0.1.2 - 2009-12-30
### Changed
- Documentation updates

## 0.1.1 - 2009-12-30
### Changed
- library file renamed to `redis-session-store.rb` to play nicely with
  rails require

## 0.1 - 2009-12-30
### Added
- first working version

[Unreleased]: https://github.com/roidrage/redis-session-store/compare/v0.11.1...HEAD
[0.11.1]: https://github.com/roidrage/redis-session-store/compare/v0.11.0...v0.11.1
[0.11.0]: https://github.com/roidrage/redis-session-store/compare/v0.10.0...v0.11.0
[0.10.0]: https://github.com/roidrage/redis-session-store/compare/v0.9.2...v0.10.0
[0.9.2]: https://github.com/roidrage/redis-session-store/compare/v0.9.1...v0.9.2
[0.9.1]: https://github.com/roidrage/redis-session-store/compare/v0.9.0...v0.9.1
[0.9.0]: https://github.com/roidrage/redis-session-store/compare/v0.8.1...v0.9.0
[0.8.1]: https://github.com/roidrage/redis-session-store/compare/v0.8.0...v0.8.1
[0.8.0]: https://github.com/roidrage/redis-session-store/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/roidrage/redis-session-store/compare/v0.6.6...v0.7.0
[0.6.6]: https://github.com/roidrage/redis-session-store/compare/v0.6.5...v0.6.6
[0.6.5]: https://github.com/roidrage/redis-session-store/compare/v0.6.4...v0.6.5
[0.6.4]: https://github.com/roidrage/redis-session-store/compare/v0.6.3...v0.6.4
[0.6.3]: https://github.com/roidrage/redis-session-store/compare/v0.6.2...v0.6.3
[0.6.2]: https://github.com/roidrage/redis-session-store/compare/v0.6.1...v0.6.2
[0.6.1]: https://github.com/roidrage/redis-session-store/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/roidrage/redis-session-store/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/roidrage/redis-session-store/compare/v0.4.2...v0.5.0
[0.4.2]: https://github.com/roidrage/redis-session-store/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/roidrage/redis-session-store/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/roidrage/redis-session-store/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/roidrage/redis-session-store/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/roidrage/redis-session-store/compare/v0.2.4...v0.3.0
[0.2.4]: https://github.com/roidrage/redis-session-store/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/roidrage/redis-session-store/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/roidrage/redis-session-store/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/roidrage/redis-session-store/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/roidrage/redis-session-store/compare/v0.1.9...v0.2.0
[0.1.9]: https://github.com/roidrage/redis-session-store/compare/v0.1.8...v0.1.9
[0.1.8]: https://github.com/roidrage/redis-session-store/compare/v0.1.7...v0.1.8
