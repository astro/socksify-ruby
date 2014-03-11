=begin
    Copyright (C) 2007 Stephan Maka <stephan@spaceboyz.net>
    Copyright (C) 2011 Musy Bite <musybite@gmail.com>

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

require 'socksify'
require 'net/http'

module Net
  class HTTP
    def self.SOCKSProxy(p_host, p_port)
      delta = SOCKSProxyDelta
      proxyclass = Class.new(self)
      proxyclass.send(:include, delta)
      proxyclass.module_eval {
        include delta::InstanceMethods
        extend delta::ClassMethods
        @socks_server = p_host
        @socks_port = p_port
      }
      proxyclass
    end

    module SOCKSProxyDelta
      module ClassMethods
        def socks_server
          @socks_server
        end

        def socks_port
          @socks_port
        end
      end

      module InstanceMethods
        if RUBY_VERSION[0..0] >= '2'
          def address
            TCPSocket::SOCKSConnectionPeerAddress.new(self.class.socks_server, self.class.socks_port, @address)
          end
        else
          def conn_address
            TCPSocket::SOCKSConnectionPeerAddress.new(self.class.socks_server, self.class.socks_port, address())
          end
        end
      end
    end
  end
end
