# frozen_string_literal: true

require 'test/unit'
require 'net/http'
require 'uri'

$LOAD_PATH.unshift "#{__dir__}/../lib/"

require 'socksify'
require 'socksify/http'

module HelperMethods
  def disable_socks
    TCPSocket.socks_server = nil
    TCPSocket.socks_port = nil
  end

  def enable_socks
    TCPSocket.socks_server = '127.0.0.1'
    TCPSocket.socks_port = 9050
  end

  def http_tor_proxy
    Net::HTTP::SOCKSProxy('127.0.0.1', 9050)
  end

  def get_http(http_klass, url, host_header = nil)
    uri = URI(url)
    body = nil
    http_klass.start(uri.host, uri.port,
                     use_ssl: uri.scheme == 'https',
                     verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
      req = Net::HTTP::Get.new uri.path
      req['Host'] = host_header
      body = http.request(req).body
    end
    body
  end
end

module TorProjectHelperMethods
  def parse_check_tor_resp(body)
    ip_regexp = %r{Your IP address appears to be:\s*<strong>(\d+\.\d+\.\d+\.\d+)</strong>}
    raise 'Bogus response, no IP' unless body =~ ip_regexp

    [tor?(body), Regexp.last_match(1)] # true/false, ip
  end

  def tor?(tor_project_dot_org_body)
    if tor_project_dot_org_body.include? 'This browser is configured to use Tor.'
      true
    elsif tor_project_dot_org_body.include? 'You are not using Tor.'
      false
    else
      raise 'Bogus response'
    end
  end

  def check_tor(http_klass = Net::HTTP)
    parse_check_tor_resp get_http(http_klass, 'https://check.torproject.org/', 'check.torproject.org')
  end

  def check_tor_with_service_as_string(http_klass = Net::HTTP)
    parse_check_tor_resp get_http(http_klass, 'https://check.torproject.org/')
  end
end

module YandexHelperMethods
  def internet_yandex_com_ip(http_klass = Net::HTTP)
    parse_internet_yandex_com_response get_http(http_klass, 'https://213.180.204.62/internet', 'yandex.com') # "http://yandex.com/internet"
  end

  def parse_internet_yandex_com_response(body)
    raise "Bogus response, no IP\n#{body.inspect}" unless body =~ %r{<div>(\d+\.\d+\.\d+\.\d+)</div>}

    Regexp.last_match(1) # ip
  end
end
