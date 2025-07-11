require_relative 'socksproxyable'

# monkey patch
class TCPSocket
  extend Socksproxyable::ClassMethods
  include Socksproxyable::InstanceMethodsAuthenticate
  include Socksproxyable::InstanceMethodsConnect

  alias initialize_tcp initialize

  attr_reader :socks_peer

  # See http://tools.ietf.org/html/rfc1928
  # rubocop:disable Metrics/ParameterLists
  def initialize(host = nil, port = nil, local_host = nil, local_port = nil, **kwargs)
    @socks_peer = host if host.is_a?(SOCKSConnectionPeerAddress)
    host = socks_peer.peer_host if socks_peer

    if socks_server && socks_port && !socks_ignores.include?(host)
      make_socks_connection(host, port, **kwargs)
    else
      make_direct_connection(host, port, local_host, local_port, **kwargs)
    end
  end
  # rubocop:enable Metrics/ParameterLists

  # string representation of the peer host address
  class SOCKSConnectionPeerAddress < String
    attr_reader :socks_server, :socks_port, :socks_username, :socks_password

    def initialize(socks_server, socks_port, peer_host, socks_username = nil, socks_password = nil)
      @socks_server = socks_server
      @socks_port = socks_port
      @socks_username = socks_username
      @socks_password = socks_password
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

  def socks_server
    @socks_server ||= socks_peer ? socks_peer.socks_server : self.class.socks_server
  end

  def socks_port
    @socks_port ||= socks_peer ? socks_peer.socks_port : self.class.socks_port
  end

  def socks_username
    @socks_username ||= socks_peer ? socks_peer.socks_username : self.class.socks_username
  end

  def socks_password
    @socks_password ||= socks_peer ? socks_peer.socks_password : self.class.socks_password
  end

  def socks_ignores
    @socks_ignores ||= socks_peer ? [] : self.class.socks_ignores
  end

  def make_socks_connection(host, port, **kwargs)
    Socksify.debug_notice "Connecting to SOCKS server #{socks_server}:#{socks_port}"
    initialize_tcp socks_server, socks_port, **kwargs
    socks_authenticate(socks_username, socks_password) unless @socks_version =~ /^4/
    socks_connect(host, port) if host
  end

  def make_direct_connection(host, port, local_host, local_port, **kwargs)
    Socksify.debug_notice "Connecting directly to #{host}:#{port}"
    initialize_tcp host, port, local_host, local_port, **kwargs
    Socksify.debug_debug "Connected to #{host}:#{port}"
  end
end
