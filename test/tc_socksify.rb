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

  def test_check_tor
    [['Hostname', :check_tor],
     ['IPv4', :check_tor_ip]].each do |f_name, f|
      disable_socks

      tor_direct, ip_direct = send(f)
      assert_equal(false, tor_direct)

      enable_socks

      tor_socks, ip_socks = send(f)
      assert_equal(true, tor_socks)

      assert(ip_direct != ip_socks)
    end
  end

  def test_ignores
    disable_socks

    tor_direct, ip_direct = check_tor
    assert_equal(false, tor_direct)

    enable_socks
    TCPSocket.socks_ignores << 'check.torproject.org'

    tor_socks_ignored, ip_socks_ignored = check_tor
    assert_equal(false, tor_socks_ignored)

    assert(ip_direct == ip_socks_ignored)
  end

  def check_tor
    url = URI::parse('http://check.torproject.org/')
    parse_check_response(Net::HTTP.start(url.host, url.port) do |http|
                           http.get('/', "User-Agent"=>"ruby-socksify test").body
                         end)
  end

  def check_tor_ip
    url = URI::parse('http://209.237.247.84/')
    parse_check_response(Net::HTTP.start(url.host, url.port) do |http|
                           http.get('/',
                                    "Host"=>"www.whatismyip.org",
                                    "User-Agent"=>"ruby-socksify test").body
                         end)
  end

  def parse_check_response(body)
    if body.include? 'You are (probably) using Tor.'
      is_tor = true
    elsif body.include? 'You are (probably) not using Tor.'
      is_tor = false
    else
      raise 'Bogus response'
    end

    if body =~ /Your IP appears to be: <b>(\d+\.\d+\.\d+\.\d+)<\/b>/
      ip = $1
    else
      raise 'Bogus response, no IP'
    end

    [is_tor, ip]
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
