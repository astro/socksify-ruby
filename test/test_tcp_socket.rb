# frozen_string_literal: true

require_relative 'test_helper'

class TCPSocketTest < Minitest::Test
  include HelperMethods

  if RUBY_VERSION.to_f >= 3.0
    def test_tcp_socket_direct_connection_with_connection_timeout
      socket = TCPSocket.new('127.0.0.1', 9050, connect_timeout: 0.1)

      assert !socket.closed?
    end
  end
end
