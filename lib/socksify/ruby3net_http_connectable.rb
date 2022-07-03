# frozen_string_literal: true

# Ruby 3.0 private method Net::HTTP#connect
module Ruby3NetHTTPConnectable
  # rubocop:disable all - CAN'T LINT RUBY SOURCE CODE!
  def connect
    if use_ssl? # 3.1 - MOVED FROM FURTHER DOWN IN METHOD
      # reference early to load OpenSSL before connecting,
      # as OpenSSL may take time to load.
      @ssl_context = OpenSSL::SSL::SSLContext.new
    end

    if proxy? then
      conn_addr = proxy_address
      conn_port = proxy_port
    else
      conn_addr = conn_address
      conn_port = port
    end

    D "opening connection to #{conn_addr}:#{conn_port}..."
    ######## RUBY < 3.1 ########
    s = Timeout.timeout(@open_timeout, Net::OpenTimeout) {
      begin
        TCPSocket.open(conn_addr, conn_port, @local_host, @local_port)
      rescue => e
        raise e, "Failed to open TCP connection to " +
          "#{conn_addr}:#{conn_port} (#{e.message})"
      end
    }
    ######## END RUBY < 3.1 ########
    s.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
    D "opened"
    if use_ssl?
      if proxy?
        plain_sock = Net::BufferedIO.new(s, read_timeout: @read_timeout, # 3.1 - FULLY QUALIFY CLASS
                                            write_timeout: @write_timeout,
                                            continue_timeout: @continue_timeout,
                                            debug_output: @debug_output)
        buf = "CONNECT #{conn_address}:#{@port} HTTP/#{Net::HTTP::HTTPVersion}\r\n" # 3.1 - FULLY QUALIFY CONSTANT
        buf << "Host: #{@address}:#{@port}\r\n"
        if proxy_user
          credential = ["#{proxy_user}:#{proxy_pass}"].pack('m0')
          buf << "Proxy-Authorization: Basic #{credential}\r\n"
        end
        buf << "\r\n"
        plain_sock.write(buf)
        Net::HTTPResponse.read_new(plain_sock).value # 3.1 - FULLY QUALIFY CLASS
        # assuming nothing left in buffers after successful CONNECT response
      end

      ssl_parameters = Hash.new
      iv_list = instance_variables
      Net::HTTP::SSL_IVNAMES.each_with_index do |ivname, i| # 3.1 - FULLY QUALIFY CONSTANT
        if iv_list.include?(ivname)
          value = instance_variable_get(ivname)
          unless value.nil?
            ssl_parameters[Net::HTTP::SSL_ATTRIBUTES[i]] = value # 3.1 - FULLY QUALIFY CONSTANT
          end
        end
      end
      # @ssl_context = OpenSSL::SSL::SSLContext.new # 3.1 - MOVED TO TOP OF METHOD
      @ssl_context.set_params(ssl_parameters)
      @ssl_context.session_cache_mode =
        OpenSSL::SSL::SSLContext::SESSION_CACHE_CLIENT |
        OpenSSL::SSL::SSLContext::SESSION_CACHE_NO_INTERNAL_STORE
      @ssl_context.session_new_cb = proc {|sock, sess| @ssl_session = sess }
      D "starting SSL for #{conn_addr}:#{conn_port}..."
      s = OpenSSL::SSL::SSLSocket.new(s, @ssl_context)
      s.sync_close = true
      # Server Name Indication (SNI) RFC 3546
      s.hostname = @address if s.respond_to? :hostname=
      if @ssl_session and
         Process.clock_gettime(Process::CLOCK_REALTIME) < @ssl_session.time.to_f + @ssl_session.timeout
        s.session = @ssl_session
      end
      ssl_socket_connect(s, @open_timeout)
      if (@ssl_context.verify_mode != OpenSSL::SSL::VERIFY_NONE) && @ssl_context.verify_hostname
        s.post_connection_check(@address)
      end
      D "SSL established, protocol: #{s.ssl_version}, cipher: #{s.cipher[0]}"
    end
    @socket = Net::BufferedIO.new(s, read_timeout: @read_timeout, # 3.1 - FULLY QUALIFY CLASS
                                     write_timeout: @write_timeout,
                                     continue_timeout: @continue_timeout,
                                     debug_output: @debug_output)
    @last_communicated = nil # 3.1 - NEW
    on_connect
  rescue => exception
    if s
      D "Conn close because of connect error #{exception}"
      s.close
    end
    raise
  end
  # rubocop:enable all
  private :connect
end
