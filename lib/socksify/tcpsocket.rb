require_relative 'socksproxyable'

# monkey patch
class TCPSocket
  extend Socksproxyable::ClassMethods
  include Socksproxyable::InstanceMethodsAuthenticate
  include Socksproxyable::InstanceMethodsConnect

  alias initialize_tcp initialize

  # See http://tools.ietf.org/html/rfc1928
  # rubocop:disable Metrics/ParameterLists
  def initialize(host = nil, port = nil, local_host = nil, local_port = nil)
    socks_peer = host if host.is_a?(SOCKSConnectionPeerAddress)
    socks_server = set_socks_server(socks_peer)
    socks_port = set_socks_port(socks_peer)
    socks_ignores = set_socks_ignores(socks_peer)
    host = socks_peer.peer_host if socks_peer
    if socks_server && socks_port && !socks_ignores.include?(host)
      make_socks_connection(host, port, socks_server, socks_port)
    else
      make_direct_connection(host, port, local_host, local_port)
    end
  end
  # rubocop:enable Metrics/ParameterLists

  # string representation of the peer host address
  class SOCKSConnectionPeerAddress < String
    attr_reader :socks_server, :socks_port

    def initialize(socks_server, socks_port, peer_host)
      @socks_server = socks_server
      @socks_port = socks_port
      super(peer_host)
    end

    def inspect
      "#{self} (via #{@socks_server}:#{@socks_port})"
    end

    def peer_host
      to_s
    end
  end

  private

  def set_socks_server(socks_peer = nil)
    socks_peer ? socks_peer.socks_server : self.class.socks_server
  end

  def set_socks_port(socks_peer = nil)
    socks_peer ? socks_peer.socks_port : self.class.socks_port
  end

  def set_socks_ignores(socks_peer = nil)
    socks_peer ? [] : self.class.socks_ignores
  end

  def make_socks_connection(host, port, socks_server, socks_port)
    Socksify.debug_notice "Connecting to SOCKS server #{socks_server}:#{socks_port}"
    initialize_tcp socks_server, socks_port
    socks_authenticate unless @socks_version =~ /^4/
    socks_connect(host, port) if host
  end

  def make_direct_connection(host, port, local_host, local_port)
    Socksify.debug_notice "Connecting directly to #{host}:#{port}"
    initialize_tcp host, port, local_host, local_port
    Socksify.debug_debug "Connected to #{host}:#{port}"
  end
end
