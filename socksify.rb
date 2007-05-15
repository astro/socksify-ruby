require 'socket'

class SOCKSError < RuntimeError
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
      initialize_tcp socks_server, socks_port

      # Authentication
      write "\005\001\000"
      auth_reply = recv(2)
      if auth_reply[0] != 4 and auth_reply[0] != 5
        raise SOCKSError.new("SOCKS version #{auth_reply[0]} not supported")
      end
      if auth_reply[1] != 0
        raise SOCKSError.new("SOCKS authentication method #{auth_reply[1]} neither requested nor supported")
      end

      # Connect
      write "\005\001\000\003#{[host.size].pack('C')}#{host}#{[port].pack('n')}"
      connect_reply = recv(4)
      if connect_reply[0] != auth_reply[0]
        raise SOCKSError.new("SOCKS version #{connect_reply[0]} not requested")
      end
      if connect_reply[1] != 0
        raise SOCKSError.new("SOCKS error #{connect_reply[1]}")
      end
      bind_addr_len = case connect_reply[3]
                      when 1
                        4
                      when 3
                        recv(1)[0]
                      when 4
                        16
                      else
                        raise SOCKSError.new("Unknown BND.ADDR #{connect_reply[3]}")
                      end
      recv(bind_addr_len + 2)
    else
      initialize_tcp host, port, local_host, local_port
    end
  end
end
