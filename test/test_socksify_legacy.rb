module TestSocksifyLegacy
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
end
