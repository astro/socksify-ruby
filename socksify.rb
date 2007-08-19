require 'socket'
require 'socksify_debug'

class SOCKSError < RuntimeError
  def self.new(msg)
    Socksify::debug_error(msg)
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
  def initialize(host, port, local_host="0.0.0.0", local_port=0)
    socks_server = self.class.socks_server
    socks_port = self.class.socks_port

    if socks_server and socks_port
      Socksify::debug_notice "Connecting to SOCKS server #{socks_server}:#{socks_port}"
      initialize_tcp socks_server, socks_port

      # Authentication
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

      # Connect
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
      Socksify::debug_debug "Waiting for connect reply"
      connect_reply = recv(4)
      if connect_reply[0] != auth_reply[0]
        raise SOCKSError.new("SOCKS version #{connect_reply[0]} not requested")
      end
      if connect_reply[1] != 0
        raise SOCKSError.new("SOCKS error #{connect_reply[1]}")
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
      recv(bind_addr_len + 2)
      Socksify::debug_notice "Connected to #{host}:#{port} over SOCKS server #{socks_server}:#{socks_port}"
    else
      Socksify::debug_notice "Connecting directly to #{host}:#{port}"
      initialize_tcp host, port, local_host, local_port
      Socksify::debug_debug "Connected to #{host}:#{port}"
    end
  end
end
