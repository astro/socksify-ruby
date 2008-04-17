#!/usr/bin/ruby

require 'test/unit'
require 'net/http'
require 'uri'

$:.unshift "#{File::dirname($0)}/../lib/"
require 'socksify'


class SocksifyTest < Test::Unit::TestCase
  def setup
    Socksify::debug = true
  end

  def disable_socks
    TCPSocket.socks_server = nil
    TCPSocket.socks_port = nil
  end
  def enable_socks
    TCPSocket.socks_server = "127.0.0.1"
    TCPSocket.socks_port = 9050
  end

  def test_whatismyip
    [['Hostname', :whatismyip],
     ['IPv4', :whatismyip_ip]].each do |f_name, f|
      disable_socks

      ip_direct = send(f)
      puts "By #{f_name} directly: #{ip_direct}"

      enable_socks

      ip_socks = send(f)
      puts "By #{f_name} over SOCKS: #{ip_socks}"

      assert(ip_direct != ip_socks)
    end
  end

  def test_ignores
    disable_socks

    ip_direct = whatismyip

    enable_socks
    TCPSocket.ignores << 'www.whatismyip.org'

    ip_socks_ignored = whatismyip

    assert(ip_direct == ip_socks_ignored)
  end

  def whatismyip
    url = URI::parse('http://www.whatismyip.org/')
    Net::HTTP.start(url.host, url.port) do |http|
      http.get('/', "User-Agent"=>"ruby-socksify test").body
    end
  end

  def whatismyip_ip
    url = URI::parse('http://206.176.224.3/')
    Net::HTTP.start(url.host, url.port) do |http|
      http.get('/',
               "Host"=>"www.whatismyip.org",
               "User-Agent"=>"ruby-socksify test").body
    end
  end

  def test_resolve
    enable_socks

    assert_equal("87.106.131.203", Socksify::resolve("spaceboyz.net"))

    assert_raise SOCKSError::HostUnreachable do
      Socksify::resolve("nonexistent.spaceboyz.net")
    end
  end

  def test_resolve_reverse
    enable_socks

    assert_equal("spaceboyz.net", Socksify::resolve("87.106.131.203"))

    assert_raise SOCKSError::HostUnreachable do
      Socksify::resolve("0.0.0.0")
    end
  end
end
