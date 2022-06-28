# encoding: us-ascii

# Copyright (C) 2007 Stephan Maka <stephan@spaceboyz.net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'socket'
require 'resolv'
require 'socksify/debug'
require 'socksify/tcpsocket'

# error class
class SOCKSError < RuntimeError
  def initialize(msg)
    Socksify.debug_error("#{self.class}: #{msg}")
    super
  end

  # rubocop:disable Style/Documentation
  class ServerFailure < SOCKSError
    def initialize
      super('general SOCKS server failure')
    end
  end

  class NotAllowed < SOCKSError
    def initialize
      super('connection not allowed by ruleset')
    end
  end

  class NetworkUnreachable < SOCKSError
    def initialize
      super('Network unreachable')
    end
  end

  class HostUnreachable < SOCKSError
    def initialize
      super('Host unreachable')
    end
  end

  class ConnectionRefused < SOCKSError
    def initialize
      super('Connection refused')
    end
  end

  class TTLExpired < SOCKSError
    def initialize
      super('TTL expired')
    end
  end

  class CommandNotSupported < SOCKSError
    def initialize
      super('Command not supported')
    end
  end

  class AddressTypeNotSupported < SOCKSError
    def initialize
      super('Address type not supported')
    end
  end
  # rubocop:enable Style/Documentation

  RESPONSE_CODE_CLASSES = { 1 => ServerFailure,
                            2 => NotAllowed,
                            3 => NetworkUnreachable,
                            4 => HostUnreachable,
                            5 => ConnectionRefused,
                            6 => TTLExpired,
                            7 => CommandNotSupported,
                            8 => AddressTypeNotSupported }.freeze

  def self.for_response_code(code)
    (resp = RESPONSE_CODE_CLASSES[code]) ? resp : self
  end
end

# namespace
module Socksify
  def self.resolve(host)
    socket = TCPSocket.new # no args?
    Socksify.debug_debug "Sending hostname to resolve: #{host}"
    req = request(host)
    socket.write req
    addr, _port = socket.socks_receive_reply
    Socksify.debug_notice "Resolved #{host} as #{addr} over SOCKS"
    addr
  ensure
    socket.close
  end

  def self.proxy(server, port)
    default_server = TCPSocket.socks_server
    default_port = TCPSocket.socks_port
    begin
      TCPSocket.socks_server = server
      TCPSocket.socks_port = port
      yield
    ensure # failback
      TCPSocket.socks_server = default_server
      TCPSocket.socks_port = default_port
    end
  end

  def self.request(host)
    req = String.new << "\005"
    case host
    when /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ # to IPv4 address
      req << "\xF1\000\001#{(1..4).map { |i| Regexp.last_match(i).to_i }.pack('CCCC')}"
    when /^[:0-9a-f]+$/ # to IPv6 address
      raise 'TCP/IPv6 over SOCKS is not yet supported (inet_pton missing in Ruby & not supported by Tor)'
    #   # req << "\004" # UNREACHABLE
    else # to hostname
      req << "\xF0\000\003#{[host.size].pack('C')}#{host}"
    end
    req << [0].pack('n') # Port
  end
end
