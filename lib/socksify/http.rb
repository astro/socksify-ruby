#  Copyright (C) 2007 Stephan Maka <stephan@spaceboyz.net>
#  Copyright (C) 2011 Musy Bite <musybite@gmail.com>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'socksify'
require 'net/http'
require_relative 'ruby3net_http_connectable'

module Net
  # patched class
  class HTTP
    def self.socks_proxy(p_host, p_port, username: nil, password: nil)
      proxyclass.module_eval do
        include Ruby3NetHTTPConnectable if RUBY_VERSION.to_f > 3.0 # patch #connect method
        include SOCKSProxyDelta::InstanceMethods
        extend SOCKSProxyDelta::ClassMethods

        @socks_server = p_host
        @socks_port = p_port
        @socks_username = username
        @socks_password = password
      end

      proxyclass
    end

    def self.proxyclass
      @proxyclass ||= Class.new(self).tap { |klass| klass.send(:include, SOCKSProxyDelta) }
    end

    class << self
      alias SOCKSProxy socks_proxy # legacy support for non snake case method name
    end

    module SOCKSProxyDelta
      # class methods
      module ClassMethods
        attr_reader :socks_server, :socks_port,
                    :socks_username, :socks_password
      end

      # instance methods - no long supports Ruby < 2
      module InstanceMethods
        def address
          TCPSocket::SOCKSConnectionPeerAddress.new(
            self.class.socks_server, self.class.socks_port,
            @address,
            self.class.socks_username, self.class.socks_password
          )
        end
      end
    end
  end
end
