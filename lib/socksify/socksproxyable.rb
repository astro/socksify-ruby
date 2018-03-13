# frozen_string_literal: true

# decorator methods for socks proxying
module Socksproxyable
  # class methods
  module ClassMethods
    attr_accessor :socks_server, :socks_port, :socks_username, :socks_password

    def socks_version
      @socks_version ||= '5'
    end

    def socks_ignores
      @socks_ignores ||= %w[localhost]
    end

    def socks_ignores=(*hosts)
      @socks_ignores = hosts
    end

    def socks_version_hex
      socks_version == '4a' || socks_version == '4' ? "\004" : "\005"
    end
  end

  # instance method #socks_authenticate
  module InstanceMethodsAuthenticate
    # rubocop:disable Metrics
    def socks_authenticate(socks_username, socks_password)
      if socks_username || socks_password
        Socksify.debug_debug 'Sending username/password authentication'
        write "\005\001\002"
      else
        Socksify.debug_debug 'Sending no authentication'
        write "\005\001\000"
      end
      Socksify.debug_debug 'Waiting for authentication reply'
      auth_reply = recv(2)
      raise SOCKSError, "Server doesn't reply authentication" if auth_reply.empty?

      if auth_reply[0..0] != "\004" && auth_reply[0..0] != "\005"
        raise SOCKSError, "SOCKS version #{auth_reply[0..0]} not supported"
      end

      if socks_username || socks_password
        if auth_reply[1..1] != "\002"
          raise SOCKSError, "SOCKS authentication method #{auth_reply[1..1]} neither requested nor supported"
        end

        auth = "\001"
        auth += username.to_s.length.chr
        auth += socks_username.to_s
        auth += socks_password.to_s.length.chr
        auth += socks_password.to_s
        write auth
        auth_reply = recv(2)
        raise SOCKSError, 'SOCKS authentication failed' if auth_reply[1..1] != "\000"
      elsif auth_reply[1..1] != "\000"
        raise SOCKSError, "SOCKS authentication method #{auth_reply[1..1]} neither requested nor supported"
      end
    end
    # rubocop:enable Metrics
  end

  # instance methods #socks_connect & #socks_receive_reply
  module InstanceMethodsConnect
    # rubocop:disable Metrics
    def socks_connect(host, port)
      port = Socket.getservbyname(port) if port.is_a?(String)
      req = String.new
      Socksify.debug_debug 'Sending destination address'
      req << TCPSocket.socks_version_hex
      Socksify.debug_debug TCPSocket.socks_version_hex.unpack 'H*'
      req << "\001"
      req << "\000" if self.class.socks_version == '5'
      req << [port].pack('n') if self.class.socks_version =~ /^4/
      host = Resolv::DNS.new.getaddress(host).to_s if self.class.socks_version == '4'
      Socksify.debug_debug host
      if host =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ # to IPv4 address
        req << "\001" if self.class.socks_version == '5'
        ip = (1..4).map { |i| Regexp.last_match(i).to_i }.pack('CCCC')
        req << ip
      elsif host =~ /^[:0-9a-f]+$/ # to IPv6 address
        raise 'TCP/IPv6 over SOCKS is not yet supported (inet_pton missing in Ruby & not supported by Tor'
        # req << "\004" # UNREACHABLE
      elsif self.class.socks_version == '5' # to hostname
        # req << "\003" + [host.size].pack('C') + host
        req << "\003#{[host.size].pack('C')}#{host}"
      else
        req << "\000\000\000\001" << "\007\000"
        Socksify.debug_notice host
        req << host << "\000"
      end
      req << [port].pack('n') if self.class.socks_version == '5'
      write req
      socks_receive_reply
      Socksify.debug_notice "Connected to #{host}:#{port} over SOCKS"
    end
    # rubocop:enable Metrics

    # returns [bind_addr: String, bind_port: Fixnum]
    # rubocop:disable Metrics
    def socks_receive_reply
      Socksify.debug_debug 'Waiting for SOCKS reply'
      if self.class.socks_version == '5'
        connect_reply = recv(4)
        raise SOCKSError, "Server doesn't reply" if connect_reply.empty?

        Socksify.debug_debug connect_reply.unpack 'H*'
        raise SOCKSError, "SOCKS version #{connect_reply[0..0]} is not 5" if connect_reply[0..0] != "\005"
        raise SOCKSError.for_response_code(connect_reply.bytes.to_a[1]) if connect_reply[1..1] != "\000"

        Socksify.debug_debug 'Waiting for bind_addr'
        bind_addr_len = case connect_reply[3..3]
                        when "\001"
                          4
                        when "\003"
                          recv(1).bytes.first
                        when "\004"
                          16
                        else
                          raise SOCKSError.for_response_code(connect_reply.bytes.to_a[3])
                        end
        bind_addr_s = recv(bind_addr_len)
        bind_addr = case connect_reply[3..3]
                    when "\001"
                      bind_addr_s.bytes.to_a.join('.')
                    when "\003"
                      bind_addr_s
                    when "\004" # Untested!
                      i = 0
                      ip6 = ''
                      bind_addr_s.each_byte do |b|
                        ip6 += ':' if i > 0 && i.even?
                        i += 1
                        ip6 += b.to_s(16).rjust(2, '0')
                      end
                    end
        bind_port = recv(bind_addr_len + 2)
        [bind_addr, bind_port.unpack('n')]
      else
        connect_reply = recv(8)
        unless connect_reply[0] == "\000" && connect_reply[1] == "\x5A"
          Socksify.debug_debug connect_reply.unpack 'H'
          raise SOCKSError, 'Failed while connecting througth socks'
        end
      end
    end
    # rubocop:enable Metrics
  end
end
