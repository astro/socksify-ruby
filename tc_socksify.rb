#!/usr/bin/ruby

require 'test/unit'
require 'socksify'
require 'net/http'
require 'uri'

class SocksifyTest < Test::Unit::TestCase
  def setup
    Socksify::debug = true
  end

  def test_whatismyip
    [['Hostname', :whatismyip],
     ['IPv4', :whatismyip_ip]].each do |f_name, f|
      TCPSocket.socks_server = nil
      TCPSocket.socks_port = nil

      ip_direct = send(f)
      puts "By #{f_name} directly: #{ip_direct}"

      TCPSocket.socks_server = "127.0.0.1"
      TCPSocket.socks_port = 9050

      ip_socks = send(f)
      puts "By #{f_name} over SOCKS: #{ip_socks}"

      assert(ip_direct != ip_socks)
    end
  end

  def whatismyip
    url = URI::parse('http://www.whatismyip.org/')
    Net::HTTP.start(url.host, url.port) do |http|
      http.get('/', "User-Agent"=>"ruby-socksify test").body
    end
  end

  def whatismyip_ip
    url = URI::parse('http://206.176.224.3/')
    Net::HTTP.start(url.host, url.port) do |http|
      http.get('/',
               "Host"=>"www.whatismyip.org",
               "User-Agent"=>"ruby-socksify test").body
    end
  end
end
