[![Gem Version](https://badge.fury.io/rb/socksify.svg)](https://badge.fury.io/rb/socksify)
[![Actions Status](https://github.com/astro/socksify-ruby/workflows/CI/badge.svg?branch=master)](https://github.com/astro/socksify-ruby/actions?query=workflow%3ACI)

SOCKSify Ruby
=============

What is it?
-----------

**SOCKSify Ruby** redirects any TCP connection initiated by a Ruby script through a SOCKS5 proxy. It serves as a small drop-in alternative to [tsocks](http://tsocks.sourceforge.net/), except that it handles Ruby programs only and doesn't leak DNS queries.

### How does it work?

```rb
require 'socksify/http'
```
This adds a new class method `Net::HTTP.socks_proxy` which takes the host and port address of a socks proxy. Once set, all requests will be routed via socks. This is acheived by patching a private method in `Net::HTTP`, as sadly Ruby no longer has native socks proxy support out of the box.

Additionally, `Socksify.resolve` can be used to resolve hostnames to IPv4 addresses via SOCKS.

Installation
------------

`$ gem install socksify`

Usage
-----

### Redirect all TCP connections of a Ruby program

Run a Ruby script with redirected TCP through a local [Tor](https://www.torproject.org/) anonymizer:

`$ socksify_ruby localhost 9050 script.rb`

### Explicit SOCKS usage in a Ruby program (Deprecated in Ruby 3.1 onwards)

Set up SOCKS connections for a local [Tor](https://www.torproject.org/) anonymizer, TCPSockets can be used as usual:

```rb
require 'socksify'

TCPSocket.socks_server = "127.0.0.1"
TCPSocket.socks_port = 9050
rubyforge_www = TCPSocket.new("rubyforge.org", 80)
# => #<TCPSocket:0x...>
```

### Use Net::HTTP explicitly via SOCKS

Require the additional library `socksify/http` and use the `Net::HTTP.socks_proxy` method. It is similar to `Net::HTTP.Proxy` from the Ruby standard library:
```rb
require 'socksify/http'

uri = URI.parse('http://ipecho.net/plain')
Net::HTTP.socks_proxy('127.0.0.1', 9050).start(uri.host, uri.port) do |http|
  req = Net::HTTP::Get.new uri
  resp = http.request(req)
  puts resp.inspect
  puts resp.body
end
# => #<Net::HTTPOK 200 OK readbody=true>
# => <A tor exit node ip address>
```
Note that `Net::HTTP.socks_proxy` never relies on `TCPSocket.socks_server`/`socks_port`. You should either set `socks_proxy` arguments explicitly or use `Net::HTTP` directly.

### Resolve addresses via SOCKS
```rb
Socksify.resolve("spaceboyz.net")
# => "87.106.131.203"
```
### Testing and Debugging

A tor proxy is required before running the tests. Install tor from your usual package manager, check it is running with `pidof tor` then run the tests with:

`ruby test/test_socksify.rb` (uses minitest, `gem install minitest` if you don't have it)

Colorful diagnostic messages are enabled by default via:
```rb
Socksify::debug = true`
```
Development
-----------

The [repository](https://github.com/astro/socksify-ruby/) can be checked out with:

`$ git-clone git@github.com:astro/socksify-ruby.git`

Send patches via pull requests. Please run `rubcop` & correct any errors first.

### Further ideas

*   `Resolv` replacement code, so that programs which resolve by themselves don't leak DNS queries
*   IPv6 address support
*   UDP as soon as [Tor](https://www.torproject.org/) supports it
*   Perhaps using standard exceptions for better compatibility when acting as a drop-in?

Author
------

*   [Stephan Maka](mailto:stephan@spaceboyz.net)

License
-------

SOCKSify Ruby is distributed under the terms of the GNU General Public License version 3 (see file `COPYING`) or the Ruby License (see file `LICENSE`) at your option.