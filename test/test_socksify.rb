# frozen_string_literal: true

require_relative 'test_helper'

# test class
class SocksifyTest < Minitest::Test
  include HelperMethods
  include TorProjectHelperMethods
  include YandexHelperMethods

  def self.test_order
    :alpha # until state between tests is fixed
  end

  if RUBY_VERSION.to_f < 3.1 # test legacy methods TCPSocket.socks_server= and TCPSocket.socks_port=
    def test_check_tor
      disable_socks
      is_tor_direct, ip_direct = check_tor

      refute is_tor_direct

      enable_socks
      is_tor_socks, ip_socks = check_tor

      assert is_tor_socks
      refute_equal ip_direct, ip_socks
    end

    def test_check_tor_with_service_as_a_string
      disable_socks
      is_tor_direct, ip_direct = check_tor_with_service_as_string

      refute is_tor_direct
      enable_socks
      is_tor_socks, ip_socks = check_tor_with_service_as_string

      assert is_tor_socks

      refute_equal ip_direct, ip_socks
    end

    def test_connect_to_ip
      disable_socks
      ip_direct = internet_yandex_com_ip
      enable_socks
      ip_socks = internet_yandex_com_ip

      refute_equal ip_direct, ip_socks
    end
  end
  # end legacy method tests

  def test_check_tor_via_net_http
    disable_socks
    tor_direct, ip_direct = check_tor

    refute tor_direct
    tor_socks, ip_socks = check_tor(http_tor_proxy)

    assert tor_socks
    refute_equal ip_direct, ip_socks
  end

  def test_connect_to_ip_via_net_http
    disable_socks
    ip_direct = internet_yandex_com_ip
    ip_socks = internet_yandex_com_ip(http_tor_proxy)

    refute_equal ip_direct, ip_socks
  end

  def test_ignores
    disable_socks
    tor_direct, ip_direct = check_tor

    refute tor_direct
    enable_socks
    TCPSocket.socks_ignores << 'check.torproject.org'
    tor_socks_ignored, ip_socks_ignored = check_tor

    refute tor_socks_ignored
    assert_equal ip_direct, ip_socks_ignored
  end

  def test_resolve
    enable_socks

    assert_includes ['8.8.8.8', '8.8.4.4'], Socksify.resolve('dns.google.com')
    assert_raises SOCKSError::HostUnreachable do
      Socksify.resolve('nonexistent.spaceboyz.net')
    end
  end

  def test_resolve_reverse
    enable_socks

    assert_equal('dns.google', Socksify.resolve('8.8.8.8'))
    assert_raises SOCKSError::HostUnreachable do
      Socksify.resolve('0.0.0.0')
    end
  end

  def test_proxy
    enable_socks
    default_server = TCPSocket.socks_server
    default_port = TCPSocket.socks_port
    Socksify.proxy('localhost.example.com', 60_001) do
      assert_equal 'localhost.example.com', TCPSocket.socks_server
      assert_equal 60_001, TCPSocket.socks_port
    end
    assert_equal [TCPSocket.socks_server, TCPSocket.socks_port], [default_server, default_port]
  end

  def test_proxy_failback
    enable_socks
    default_server = TCPSocket.socks_server
    default_port = TCPSocket.socks_port

    assert_raises StandardError do
      Socksify.proxy('localhost.example.com', 60_001) do
        raise StandardError, 'error'
      end
    end
    assert_equal TCPSocket.socks_server, default_server
    assert_equal TCPSocket.socks_port, default_port
  end
end
