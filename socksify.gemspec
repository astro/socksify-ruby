# frozen_string_literal: true

require 'rubygems'

Gem::Specification.new do |s|
  s.name = 'socksify'
  s.version = '1.7.3'
  s.summary = 'Redirect all TCPSockets through a SOCKS5 proxy'
  s.authors = ['Stephan Maka', 'Andrey Kouznetsov', 'Christopher Thorpe', 'Musy Bite', 'Yuichi Tateno', 'David Dollar']
  s.licenses = ['Ruby', 'GPL-3.0']
  s.required_ruby_version = '>= 2.0'
  s.email = 'stephan@spaceboyz.net'
  s.homepage = 'https://github.com/astro/socksify-ruby'
  s.files = %w[COPYING]
  s.files += Dir.glob('lib/**/*')
  s.files += Dir.glob('bin/**/*')
  s.files += Dir.glob('doc/**/*')
  # s.files = s.files.delete_if { |f| f =~ /~$/ } # ?
  s.require_path = 'lib'
  s.executables = %w[socksify_ruby]
  s.extra_rdoc_files = Dir.glob('doc/**/*') + %w[COPYING]
  s.metadata['funding_uri'] = 'https://github.com/sponsors/astro'
end
