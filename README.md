# Redis Session Store

[![Code Climate](https://codeclimate.com/github/roidrage/redis-session-store.svg)](https://codeclimate.com/github/roidrage/redis-session-store)
[![Gem Version](https://badge.fury.io/rb/redis-session-store.svg)](http://badge.fury.io/rb/redis-session-store)

A simple Redis-based session store for Rails.  But why, you ask,
when there's [redis-store](http://github.com/jodosha/redis-store/)?
redis-store is a one-size-fits-all solution, and I found it not to work
properly with Rails, mostly due to a problem that seemed to lie in
Rack's `Abstract::ID` class. I wanted something that worked, so I
blatantly stole the code from Rails' `MemCacheStore` and turned it
into a Redis version. No support for fancy stuff like distributed
storage across several Redis instances. Feel free to add what you
see fit.

This library doesn't offer anything related to caching, and is
only suitable for Rails applications. For other frameworks or
drop-in support for caching, check out
[redis-store](http://github.com/jodosha/redis-store/).

## Installation

For Rails 3+, adding this to your `Gemfile` will do the trick.

``` ruby
gem 'redis-session-store'
```

## Configuration

See `lib/redis-session-store.rb` for a list of valid options.
In your Rails app, throw in an initializer with the following contents:

``` ruby
Rails.application.config.session_store :redis_session_store,
  key: 'your_session_key',
  redis: {
    expire_after: 120.minutes,  # cookie expiration
    ttl: 120.minutes,           # Redis expiration, defaults to 'expire_after'
    key_prefix: 'myapp:session:',
    url: 'redis://localhost:6379/0',
  }
```

### Redis unavailability handling

If you want to handle cases where Redis is unavailable, a custom
callable handler may be provided as `on_redis_down`:

``` ruby
Rails.application.config.session_store :redis_session_store,
  # ... other options ...
  on_redis_down: ->(e, env, sid) { do_something_will_ya!(e) }
  redis: {
    # ... redis options ...
  }
```

### Serializer

By default the Marshal serializer is used. With Rails 4, you can use JSON as a
custom serializer:

* `:json` - serialize cookie values with `JSON` (Requires Rails 4+)
* `:marshal` - serialize cookie values with `Marshal` (Default)
* `:hybrid` - transparently migrate existing `Marshal` cookie values to `JSON` (Requires Rails 4+)
* `CustomClass` - You can just pass the constant name of any class that responds to `.load` and `.dump`

``` ruby
Rails.application.config.session_store :redis_session_store,
  # ... other options ...
  serializer: :hybrid
  redis: {
    # ... redis options ...
  }
```

**Note**: Rails 4 is required for using the `:json` and `:hybrid` serializers
because the `Flash` object doesn't serialize well in 3.2. See [Rails #13945](https://github.com/rails/rails/pull/13945) for more info.

### Session load error handling

If you want to handle cases where the session data cannot be loaded, a
custom callable handler may be provided as `on_session_load_error` which
will be given the error and the session ID.

``` ruby
Rails.application.config.session_store :redis_session_store,
  # ... other options ...
  on_session_load_error: ->(e, sid) { do_something_will_ya!(e) }
  redis: {
    # ... redis options ...
  }
```

**Note** The session will *always* be destroyed when it cannot be loaded.

### Other notes

It returns with_indifferent_access if ActiveSupport is defined.

## Rails 2 Compatibility

This gem is currently only compatible with Rails 3+.  If you need
Rails 2 compatibility, be sure to pin to a lower version like so:

``` ruby
gem 'redis-session-store', '< 0.3'
```

## Contributing, Authors, & License

See [CONTRIBUTING.md](CONTRIBUTING.md), [AUTHORS.md](AUTHORS.md), and
[LICENSE](LICENSE), respectively.
