require_relative 'socksproxyable'

# monkey patch
class TCPSocket
  extend Socksproxyable::ClassMethods
  include Socksproxyable::InstanceMethodsAuthenticate
  include Socksproxyable::InstanceMethodsConnect

  @socks_version ||= '5'
  @socks_server ||= nil
  @socks_port ||= nil
  @socks_username ||= nil
  @socks_password ||= nil
  @socks_ignores ||= %w[localhost]

  alias initialize_tcp initialize

  # See http://tools.ietf.org/html/rfc1928
  def initialize(host = nil, port = 0, local_host = nil, local_port = nil)
    if host.is_a?(SOCKSConnectionPeerAddress)
      socks_peer = host
      socks_server = socks_peer.socks_server
      socks_port = socks_peer.socks_port
      socks_ignores = []
      host = socks_peer.peer_host
    else
      socks_server = self.class.socks_server
      socks_port = self.class.socks_port
      socks_ignores = self.class.socks_ignores
    end

    if socks_server && socks_port && !socks_ignores.include?(host)
      Socksify.debug_notice "Connecting to SOCKS server #{socks_server}:#{socks_port}"
      initialize_tcp socks_server, socks_port

      socks_authenticate unless @socks_version =~ /^4/

      socks_connect(host, port) if host
    else
      Socksify.debug_notice "Connecting directly to #{host}:#{port}"
      initialize_tcp host, port, local_host, local_port
      Socksify.debug_debug "Connected to #{host}:#{port}"
    end
  end

  # string representation of the peer host address
  class SOCKSConnectionPeerAddress < String
    attr_reader :socks_server, :socks_port

    def initialize(socks_server, socks_port, peer_host)
      @socks_server = socks_server
      @socks_port = socks_port
      super peer_host
    end

    def inspect
      "#{self} (via #{@socks_server}:#{@socks_port})"
    end

    def peer_host
      to_s
    end
  end
end
