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
require 'socksify_debug'

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

class TCPSocket
  def self.socks_server
    @@socks_server
  end
  def self.socks_server=(host)
    @@socks_server = host
  end
  def self.socks_port
    @@socks_port
  end
  def self.socks_port=(port)
    @@socks_port = port
  end

  alias :initialize_tcp :initialize

  # See http://tools.ietf.org/html/rfc1928
  def initialize(host=nil, port=0, local_host="0.0.0.0", local_port=0)
    socks_server = self.class.socks_server
    socks_port = self.class.socks_port

    if socks_server and socks_port
      Socksify::debug_notice "Connecting to SOCKS server #{socks_server}:#{socks_port}"
      initialize_tcp socks_server, socks_port

      socks_authenticate

      if host
        socks_connect(host, port)
      end
    else
      Socksify::debug_notice "Connecting directly to #{host}:#{port}"
      initialize_tcp host, port, local_host, local_port
      Socksify::debug_debug "Connected to #{host}:#{port}"
    end
  end
  
  # Authentication
  def socks_authenticate
    Socksify::debug_debug "Sending no authentication"
    write "\005\001\000"
    Socksify::debug_debug "Waiting for authentication reply"
    auth_reply = recv(2)
    if auth_reply[0] != 4 and auth_reply[0] != 5
      raise SOCKSError.new("SOCKS version #{auth_reply[0]} not supported")
    end
    if auth_reply[1] != 0
      raise SOCKSError.new("SOCKS authentication method #{auth_reply[1]} neither requested nor supported")
    end
  end

  # Connect
  def socks_connect(host, port)
    Socksify::debug_debug "Sending destination address"
    write "\005\001\000"
    if host =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/  # to IPv4 address
      write "\001" + [$1.to_i,
                      $2.to_i,
                      $3.to_i,
                      $4.to_i
                     ].pack('CCCC')
    elsif host =~ /^[:0-9a-f]+$/  # to IPv6 address
      raise "TCP/IPv6 over SOCKS is not yet supported (inet_pton missing in Ruby & not supported by Tor"
      write "\004"
    else                          # to hostname
      write "\003" + [host.size].pack('C') + host
    end
    write [port].pack('n')

    socks_receive_reply
    Socksify::debug_notice "Connected to #{host}:#{port} over SOCKS"
  end

  # returns [bind_addr: String, bind_port: Fixnum]
  def socks_receive_reply
    Socksify::debug_debug "Waiting for SOCKS reply"
    connect_reply = recv(4)
    if connect_reply[0] != 5
      raise SOCKSError.new("SOCKS version #{connect_reply[0]} is not 5")
    end
    if connect_reply[1] != 0
      raise SOCKSError.for_response_code(connect_reply[1])
    end
    Socksify::debug_debug "Waiting for bind_addr"
    bind_addr_len = case connect_reply[3]
                    when 1
                      4
                    when 3
                      recv(1)[0]
                    when 4
                      16
                    else
                      raise SOCKSError.for_response_code(connect_reply[3])
                    end
    bind_addr_s = recv(bind_addr_len)
    bind_addr = case connect_reply[3]
                when 1
                  "#{bind_addr_s[0]}.#{bind_addr_s[1]}.#{bind_addr_s[2]}.#{bind_addr_s[3]}"
                when 3
                  bind_addr_s
                when 4  # Untested!
                  i = 0
                  ip6 = ""
                  bind_addr_s.each_byte do |b|
                    if i > 0 and i % 2 == 0
                      ip6 += ":"
                    end
                    i += 1

                    ip6 += b.to_s(16).rjust(2, '0')
                  end
                end
    bind_port = recv(bind_addr_len + 2)
    [bind_addr, bind_port.unpack('n')]
  end
end

module Socksify
  def self.resolve(host)
    s = TCPSocket.new

    begin
      Socksify::debug_debug "Sending hostname to resolve: #{host}"
      s.write "\005"
      if host =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/  # to IPv4 address
        s.write "\xF1\000\001" + [$1.to_i,
                                  $2.to_i,
                                  $3.to_i,
                                  $4.to_i
                                 ].pack('CCCC')
      elsif host =~ /^[:0-9a-f]+$/  # to IPv6 address
        raise "TCP/IPv6 over SOCKS is not yet supported (inet_pton missing in Ruby & not supported by Tor"
        s.write "\004"
      else                          # to hostname
        s.write "\xF0\000\003" + [host.size].pack('C') + host
      end
      s.write [0].pack('n')  # Port
      
      addr, port = s.socks_receive_reply
      Socksify::debug_notice "Resolved #{host} as #{addr} over SOCKS"
      addr
    ensure
      s.close
    end
  end
end
