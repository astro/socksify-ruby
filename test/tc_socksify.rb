#!/usr/bin/ruby

require_relative 'test_helper'

# test class
class SocksifyTest < Test::Unit::TestCase
  include HelperMethods
  include TorProjectHelperMethods
  include YandexHelperMethods

  def setup
    Socksify.debug = true
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

  def test_resolve
    enable_socks

    assert_includes ['8.8.8.8', '8.8.4.4'], Socksify.resolve('dns.google.com')

    assert_raise SOCKSError::HostUnreachable do
      Socksify.resolve('nonexistent.spaceboyz.net')
    end
  end

  def test_resolve_reverse
    enable_socks

    assert_equal('dns.google', Socksify.resolve('8.8.8.8'))

    assert_raise SOCKSError::HostUnreachable do
      Socksify.resolve('0.0.0.0')
    end
  end

  def test_proxy
    enable_socks

    default_server = TCPSocket.socks_server
    default_port = TCPSocket.socks_port

    Socksify.proxy('localhost.example.com', 60_001) do
      assert_equal TCPSocket.socks_server, 'localhost.example.com'
      assert_equal TCPSocket.socks_port, 60_001
    end

    assert_equal TCPSocket.socks_server, default_server
    assert_equal TCPSocket.socks_port, default_port
  end

  def test_proxy_failback
    enable_socks

    default_server = TCPSocket.socks_server
    default_port = TCPSocket.socks_port

    assert_raise StandardError do
      Socksify.proxy('localhost.example.com', 60_001) do
        raise StandardError, 'error'
      end
    end

    assert_equal TCPSocket.socks_server, default_server
    assert_equal TCPSocket.socks_port, default_port
  end
end
