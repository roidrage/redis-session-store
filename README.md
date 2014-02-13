Redis Session Store
===================

[![Build Status](https://travis-ci.org/roidrage/redis-session-store.png?branch=master)](https://travis-ci.org/roidrage/redis-session-store)

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

Compatibility
-------------

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
  :key          => 'your_session_key',
  :redis        => {
    :db => 2,
    :expire_after => 120.minutes,
    :key_prefix => "myapp:session:",
    :host    => 'host', # Redis host name, default is localhost
    :port    => 12345   # Redis port, default is 6379
  }
}
```
    

Contributing, Authors, & License
--------------------------------

See [CONTRIBUTING.md](CONTRIBUTING.md), [AUTHORS.md](AUTHORS.md), and
[LICENSE](LICENSE), respectively.
