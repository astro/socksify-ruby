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
    disable_socks

    is_tor_direct, ip_direct = check_tor
    assert_equal(false, is_tor_direct)

    enable_socks

    is_tor_socks, ip_socks = check_tor
    assert_equal(true, is_tor_socks)

    assert(ip_direct != ip_socks)
  end

  def test_check_tor_with_service_as_a_string
    disable_socks

    is_tor_direct, ip_direct = check_tor_with_service_as_string
    assert_equal(false, is_tor_direct)

    enable_socks

    is_tor_socks, ip_socks = check_tor_with_service_as_string
    assert_equal(true, is_tor_socks)

    assert(ip_direct != ip_socks)
  end

  def test_check_tor_via_net_http
    disable_socks

    tor_direct, ip_direct = check_tor
    assert_equal(false, tor_direct)

    tor_socks, ip_socks = check_tor(http_tor_proxy)
    assert_equal(true, tor_socks)

    assert(ip_direct != ip_socks)
  end

  def test_connect_to_ip
    disable_socks

    ip_direct = internet_yandex_com_ip

    enable_socks

    ip_socks = internet_yandex_com_ip

    assert(ip_direct != ip_socks)
  end

  def test_connect_to_ip_via_net_http
    disable_socks

    ip_direct = internet_yandex_com_ip
    ip_socks = internet_yandex_com_ip(http_tor_proxy)

    assert(ip_direct != ip_socks)
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

  def _get_http(http_klass, scheme, host, port, path, host_header)
    body = nil
    http_klass.start(host, port,
                     :use_ssl => scheme == 'https',
                     :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      req = Net::HTTP::Get.new path
      req['Host'] = host_header
      req['User-Agent'] = "ruby-socksify test"
      body = http.request(req).body
    end
    body
  end

  def get_http(http_klass, url, host_header)
    uri = URI(url)
    _get_http(http_klass, uri.scheme, uri.host, uri.port, uri.request_uri, host_header)
  end

  def check_tor(http_klass = Net::HTTP)
    parse_check_response get_http(http_klass, 'https://check.torproject.org/', 'check.torproject.org')
  end

  def check_tor_with_service_as_string(http_klass = Net::HTTP)
    parse_check_response _get_http(http_klass, 'https', 'check.torproject.org', 'https', '/', 'check.torproject.org')
  end

  def internet_yandex_com_ip(http_klass = Net::HTTP)
    parse_internet_yandex_com_response get_http(http_klass, 'https://213.180.204.62/internet/', 'yandex.com') # "http://yandex.com/internet"
  end

  def parse_check_response(body)
    if body.include? 'This browser is configured to use Tor.'
      is_tor = true
    elsif body.include? 'You are not using Tor.'
      is_tor = false
    else
      raise 'Bogus response'
    end

    if body =~ /Your IP address appears to be:\s*<strong>(\d+\.\d+\.\d+\.\d+)<\/strong>/
      ip = $1
    else
      raise 'Bogus response, no IP'
    end
    [is_tor, ip]
  end

  def parse_internet_yandex_com_response(body)
    if body =~ /<strong>IPv4 address<\/strong>: <span[^>]*>(\d+\.\d+\.\d+\.\d+)/
      ip = $1
    else
      raise 'Bogus response, no IP'+"\n"+body.inspect
    end
    ip
  end

  def test_resolve
    enable_socks

    assert_equal("8.8.8.8", Socksify::resolve("google-public-dns-a.google.com"))

    assert_raise SOCKSError::HostUnreachable do
      Socksify::resolve("nonexistent.spaceboyz.net")
    end
  end

  def test_resolve_reverse
    enable_socks

    assert_equal("google-public-dns-a.google.com", Socksify::resolve("8.8.8.8"))

    assert_raise SOCKSError::HostUnreachable do
      Socksify::resolve("0.0.0.0")
    end
  end

  def test_proxy
    enable_socks 

    default_server = TCPSocket.socks_server
    default_port = TCPSocket.socks_port

    Socksify.proxy('localhost.example.com', 60001) {
      assert_equal TCPSocket.socks_server, 'localhost.example.com'
      assert_equal TCPSocket.socks_port, 60001
    }

    assert_equal TCPSocket.socks_server, default_server
    assert_equal TCPSocket.socks_port, default_port
  end

  def test_proxy_failback
    enable_socks 

    default_server = TCPSocket.socks_server
    default_port = TCPSocket.socks_port

    assert_raise StandardError do
      Socksify.proxy('localhost.example.com', 60001) {
        raise StandardError.new('error')
      }
    end

    assert_equal TCPSocket.socks_server, default_server
    assert_equal TCPSocket.socks_port, default_port
  end
end



