#encoding: us-ascii
=begin
    Copyright (C) 2007 Stephan Maka <stephan@spaceboyz.net>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

require 'socket'
require 'resolv'
require 'socksify/debug'
require 'socksify/tcpsocket_'

class SOCKSError < RuntimeError
  def initialize(msg)
    Socksify::debug_error("#{self.class}: #{msg}")
    super
  end

  class ServerFailure < SOCKSError
    def initialize
      super("general SOCKS server failure")
    end
  end
  class NotAllowed < SOCKSError
    def initialize
      super("connection not allowed by ruleset")
    end
  end
  class NetworkUnreachable < SOCKSError
    def initialize
      super("Network unreachable")
    end
  end
  class HostUnreachable < SOCKSError
    def initialize
      super("Host unreachable")
    end
  end
  class ConnectionRefused < SOCKSError
    def initialize
      super("Connection refused")
    end
  end
  class TTLExpired < SOCKSError
    def initialize
      super("TTL expired")
    end
  end
  class CommandNotSupported < SOCKSError
    def initialize
      super("Command not supported")
    end
  end
  class AddressTypeNotSupported < SOCKSError
    def initialize
      super("Address type not supported")
    end
  end

  def self.for_response_code(code)
    case code
    when 1
      ServerFailure
    when 2
      NotAllowed
    when 3
      NetworkUnreachable
    when 4
      HostUnreachable
    when 5
      ConnectionRefused
    when 6
      TTLExpired
    when 7
      CommandNotSupported
    when 8
      AddressTypeNotSupported
    else
      self
    end
  end
end

module Socksify
  def self.resolve(host)
    s = TCPSocket.new

    begin
      req = String.new
      Socksify::debug_debug "Sending hostname to resolve: #{host}"
      req << "\005"
      if host =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/  # to IPv4 address
        req << "\xF1\000\001" + [$1.to_i,
                                  $2.to_i,
                                  $3.to_i,
                                  $4.to_i
                                 ].pack('CCCC')
      elsif host =~ /^[:0-9a-f]+$/  # to IPv6 address
        raise "TCP/IPv6 over SOCKS is not yet supported (inet_pton missing in Ruby & not supported by Tor"
        req << "\004"
      else                          # to hostname
        req << "\xF0\000\003" + [host.size].pack('C') + host
      end
      req << [0].pack('n')  # Port
      s.write req
      
      addr, _port = s.socks_receive_reply
      Socksify::debug_notice "Resolved #{host} as #{addr} over SOCKS"
      addr
    ensure
      s.close
    end
  end

  def self.proxy(server, port)
    default_server = TCPSocket::socks_server
    default_port = TCPSocket::socks_port
    begin
      TCPSocket::socks_server = server
      TCPSocket::socks_port = port
      yield
    ensure
      TCPSocket::socks_server = default_server
      TCPSocket::socks_port = default_port
    end
  end
end
