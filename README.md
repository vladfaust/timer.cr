# Timer

[![Built with Crystal](https://img.shields.io/badge/built%20with-crystal-000000.svg?style=flat-square)](https://crystal-lang.org/)
[![Build status](https://img.shields.io/travis/vladfaust/timer.cr/master.svg?style=flat-square)](https://travis-ci.org/vladfaust/timer.cr)
[![API Docs](https://img.shields.io/badge/api_docs-online-brightgreen.svg?style=flat-square)](https://github.vladfaust.com/timer.cr)
[![Releases](https://img.shields.io/github/release/vladfaust/timer.cr.svg?style=flat-square)](https://github.com/vladfaust/timer.cr/releases)
[![Awesome](https://awesome.re/badge-flat2.svg)](https://github.com/veelenga/awesome-crystal)
[![vladfaust.com](https://img.shields.io/badge/style-.com-lightgrey.svg?longCache=true&style=flat-square&label=vladfaust&colorB=0a83d8)](https://vladfaust.com)
[![Patrons count](https://img.shields.io/badge/dynamic/json.svg?label=patrons&url=https://www.patreon.com/api/user/11296360&query=$.included[0].attributes.patron_count&style=flat-square&colorB=red&maxAge=86400)](https://www.patreon.com/vladfaust)
[![Gitter chat](https://img.shields.io/badge/chat%20on-gitter-green.svg?colorB=ED1965&logo=gitter&style=flat-square)](https://gitter.im/vladfaust/timer.cr)

A versatile timer module utilizing Crystal scheduler.

[![Become Patron](https://vladfaust.com/img/patreon-small.svg)](https://www.patreon.com/vladfaust)

## About

`Timer` class makes it easy to execute code at some later moment of time. It is fast, performant and reliable.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  timer:
    github: vladfaust/timer.cr
    version: ~> 0.1.0
```

2. Run `shards install`

This shard follows [Semantic Versioning v2.0.0](http://semver.org/), so check [releases](https://github.com/vladfaust/timer.cr/releases) and change the `version` accordingly. Note that until Crystal is officially released, this shard would be in beta state (`0.*.*`), with every **minor** release considered breaking. For example, `0.1.0` → `0.2.0` is breaking and `0.1.0` → `0.1.1` is not.

## Usage

Basic example:

```crystal
require "timer"

Timer.new(1.second) do
  puts "Triggered"
end

sleep # Will print "Triggered" after 1 second
```

Example with `select`:

```crystal
channel = Channel(Nil).new

select
when channel.receive
  puts "Never happens"
when Timer.new(1.second)
  puts "Timeout!"
end

sleep # Will print "Timeout!" after 1 second
```

You can `#postpone` and `#reschedule` a timer. The latter has bigger
performance impact if rescheduling at an earlier moment of time.

```
at = Time.utc_now + 5.minutes

timer = Timer.new(at) do
  puts "Triggered"
end

# OK, will trigger in 6 minutes from now
timer.postpone(1.minute)

# ditto
timer.reschedule(Time.utc_now + 6.minutes)

# Worse performance but still acceptable
timer.reschedule(Time.utc_now + 1.minute)
```

Note that a timer can be scheduled at a moment in the past, which means that it
would run immediately after given control by the Crystal scheduler.

You can also `#trigger` a timer (still calling the block in another fiber) or
`#cancel` it completely.

## Development

`crystal spec` and you're good to go.

## Contributing

1. Fork it (<https://github.com/vladfaust/timer.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'feat: some feature'`) using [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0-beta.3/) specs
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Vlad Faust](https://github.com/vladfaust) - creator and maintainer
