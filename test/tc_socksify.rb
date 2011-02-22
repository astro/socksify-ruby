#!/usr/bin/ruby

require 'test/unit'
require 'net/http'
require 'uri'

$:.unshift "#{File::dirname($0)}/../lib/"
require 'socksify'
require 'socksify/http'


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

  def http_tor_proxy
    Net::HTTP::SOCKSProxy("127.0.0.1", 9050)
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

  def test_check_tor_via_net_http
    disable_socks

    [['Hostname', :check_tor],
     ['IPv4', :check_tor_ip]].each do |f_name, f|
      tor_direct, ip_direct = send(f)
      assert_equal(false, tor_direct)

      tor_socks, ip_socks = send(f, http_tor_proxy)
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

  def check_tor(http_klass = Net::HTTP)
    url = URI::parse('http://check.torproject.org/')
    parse_check_response(http_klass.start(url.host, url.port) do |http|
                           http.get('/', "User-Agent"=>"ruby-socksify test").body
                         end)
  end

  def check_tor_ip(http_klass = Net::HTTP)
    url = URI::parse('http://38.229.70.31/')  # "check.torproject.org"
    parse_check_response(http_klass.start(url.host, url.port) do |http|
                           http.get('/',
                                    "Host"=>"check.torproject.org",
                                    "User-Agent"=>"ruby-socksify test").body
                         end)
  end

  def parse_check_response(body)
    if body.include? 'Your browser is configured to use Tor.'
      true
    elsif body.include? 'You are not using Tor.'
      false
    else
      raise 'Bogus response'
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
