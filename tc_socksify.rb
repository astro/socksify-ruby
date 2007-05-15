#!/usr/bin/ruby

require 'test/unit'
require 'socksify'
require 'net/http'
require 'uri'

class SocksifyTest < Test::Unit::TestCase
  def setup
    TCPSocket.socks_server = nil
    TCPSocket.socks_port = nil
  end

  def test_whatismyip
    ip_direct = whatismyip
    puts "IP directly: #{ip_direct}"

    TCPSocket.socks_server = "127.0.0.1"
    TCPSocket.socks_port = 9050

    ip_socks = whatismyip
    puts "IP over SOCKS: #{ip_socks}"
  end

  def whatismyip
    url = URI::parse('http://www.whatismyip.org/')
    Net::HTTP.start(url.host, url.port) do |http|
      http.get('/', "User-Agent"=>"ruby-socksify test").body
    end
  end
end
