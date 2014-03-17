Redis Session Store
===================

[![Build Status](https://travis-ci.org/roidrage/redis-session-store.png?branch=master)](https://travis-ci.org/roidrage/redis-session-store)
[![Code Climate](https://codeclimate.com/github/roidrage/redis-session-store.png)](https://codeclimate.com/github/roidrage/redis-session-store)

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
[redis-store](http://github.com/jodosha/redis-store/)

Rails 2 Compatibility
---------------------

This gem is currently only compatible with Rails 3+.  If you need
Rails 2 compatibility, be sure to pin to a lower version like so:

``` ruby
gem 'redis-session-store', '< 0.3'
```

Installation
------------

``` bash
gem install redis-session-store
```

Configuration
-------------

See `lib/redis-session-store.rb` for a list of valid options.
In your Rails app, throw in an initializer with the following contents:

``` ruby
My::Application.config.session_store = :redis_session_store, {
  key: 'your_session_key',
  redis: {
    db: 2,
    expire_after: 120.minutes,
    key_prefix: 'myapp:session:',
    host: 'host', # Redis host name, default is localhost
    port: 12345   # Redis port, default is 6379
  }
}
```

### Session ID collision handling

If you want to handle cases where the generated session ID (sid)
collides with an existing session ID, a custom callable handler may be
provided as `on_sid_collision`:

``` ruby
My::Application.config.session_store = :redis_session_store, {
  # ... other options ...
  on_sid_collision: ->(sid) { Rails.logger.warn("SID collision! #{sid}") }
}
```

### Redis unavailability handling

If you want to handle cases where Redis is unavailable, a custom
callable handler may be provided as `on_redis_down`:

``` ruby
My::Application.config.session_store = :redis_session_store, {
  # ... other options ...
  on_redis_down: ->(e, env, sid) { do_something_will_ya!(e) }
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
My::Application.config.session_store = :redis_session_store, {
  # ... other options ...
  serializer: :hybrid
}
```

**Note**: Rails 4 is required for using the `:json` and `:hybrid` serializers
because the `Flash` object doesn't serializer well in 3.2. See [Rails
#13945](https://github.com/rails/rails/pull/13945) for more info.

### Session load error handling

If you want to handle cases where the session data cannot be loaded, a
custom callable handler may be provided as `on_session_load_error` which
will be given the error, the session ID, and the session store itself.
In this way, the session store may be used directly to remove the
session without having to reach through `ActionWhatever`:

``` ruby
My::Application.config.session_store = :redis_session_store, {
  # ... other options ...
  on_session_load_error: ->(e, sid, store) { do_something_will_ya!(e) }
}
```

Contributing, Authors, & License
--------------------------------

See [CONTRIBUTING.md](CONTRIBUTING.md), [AUTHORS.md](AUTHORS.md), and
[LICENSE](LICENSE), respectively.
