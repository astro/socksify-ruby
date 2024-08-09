# frozen_string_literal: true

require_relative 'test_helper'

class TCPSocketTest < Minitest::Test
  include HelperMethods

  if RUBY_VERSION.to_f >= 3.0
    def test_tcp_socket_direct_connection_with_connection_timeout
      disable_socks

      socket = TCPSocket.new('127.0.0.1', 9050, connect_timeout: 0.1)

      refute_predicate socket, :closed?
    end

    def test_tcp_socket_socks_connection_with_connection_timeout
      enable_socks

      # leave off the host because we don't need to worry about connecting to socks
      socket = TCPSocket.new(connect_timeout: 0.1)

      refute_predicate socket, :closed?
    end
  end

  def test_tcp_socket_direct_connection_with_connection_timeout_no_kwargs
    disable_socks

    socket = TCPSocket.new('127.0.0.1', 9050)

    refute_predicate socket, :closed?
  end
end
