redis-session-store history
===========================

## v0.6.2 (2014-03-31)

* Use `#setnx` instead of `#get` when checking for session ID
  collisions, which is slightly more paranoid and should help avoid a
  particularly nasty edge case.

## v0.6.1 (2014-03-17)

* Fix compatibility with `ActionDispatch::Request::Session::Options`
  when destroying sessions.

## v0.6.0 (2014-03-17)

* Add custom serializer configuration
* Add custom handling capability for session load errors
* Always destroying sessions that cannot be loaded

## v0.5.0 (2014-03-16)

* Keep generating session IDs until one is found that doesn't collide
  with existing session IDs
* Add support for `on_sid_collision` handler option
* Add support for `on_redis_down` handler option
* **BACKWARD INCOMPATIBLE** Drop support for `:raise_errors` option

## v0.4.2 (2014-03-14)

* Renaming `load_session` method to not conflict with AbstractStore

## v0.4.1 (yanked) (2014-03-13)

* Regenerate session ID when session is missing

## v0.4.0 (2014-02-19)

* Add support for `ENV_SESSION_OPTIONS_KEY` rack env option
* Add support for `:raise_errors` session option (kinda like Dalli)
* Increasing test coverage

## v0.3.1 (2014-02-19)

* Add `#destroy_session` method
* Clean up remaining RuboCop offenses
* Documentation updates

## v0.3.0 (2014-02-13)

* Rails 3 compatibility
* Switch from minitest to rspec
* Add test coverage
* RuboCop cleanup

## v0.2.4 (2014-03-16)

* Keep generating session IDs until one is found that doesn't collide
  with existing session IDs

## v0.2.3 (2014-03-14)

* Renaming `load_session` method to not conflict with AbstractStore

## v0.2.2 (yanked) (2014-03-13)

* Regenerate session ID when session is missing

## v0.2.1 (2013-09-17)

* Add explicit MIT license metadata in gemspec

## v0.2.0 (2013-09-13)

* Use `@redis.setex` when expiry provided, else `@redis.set`
* Gemfile, gemspec, and git updates
* Nest redis-specific options inside a `:redis` key of session options
* Add `#destroy` method
* Rescue only `Errno::ECONNREFUSED` exceptions
* Handle `nil` cookies during `#destroy`
* Add Travis integration
* Add some minimal tests to ensure backward compatibility session options

## v0.1.9 (2012-03-06)

## v0.1.8 (2010-12-09)

* Remove use of `@redis.pipelined`

## v0.1.7 (2010-12-08)

* Using latest redis gem API

## v0.1.6 (2010-04-18)

* Using pipelined format with `set` and `expire`
* Changing default port from 6370 to 6379

## v0.1.5 (2010-04-07)

## v0.1.4 (2010-03-26)

* Changed redis parameter from `:server` to `:host`

## v0.1.3 (2009-12-30)

* Documentation updates

## v0.1.2 (2009-12-30)

* Documentation updates

## v0.1.1 (2009-12-30)

* library file renamed to `redis-session-store.rb` to play nicely with
  rails require

## v0.1 (2009-12-30)

* first working version
