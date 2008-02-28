#!/usr/bin/env ruby

require 'rubygems'

spec = Gem::Specification.new do |s|
  s.name = 'socksify'
  s.version = "1.0"
  s.summary = "Redirect all TCPSockets through a SOCKS5 proxy"
  s.author = "Stephan Maka"
  s.email = "stephan@spaceboyz.net"
  s.homepage = "http://socksify.rubyforge.org/"
  s.rubyforge_project = 'socksify'
  s.files = %w{COPYING}
  s.files + Dir.glob("lib/**/*")
  s.files += Dir.glob("bin/**/*")
  s.files += Dir.glob("doc/**/*")
  s.files = s.files.delete_if { |f| f =~ /\~$/ }
  s.require_path = 'lib'
  s.executables = %w{socksify_ruby}
  s.has_rdoc = false
  s.extra_rdoc_files = Dir.glob("doc/**/*") + %w{COPYING}
end

if $0 == __FILE__
  require 'rubygems/builder'
  Gem::Builder.new(spec).build
end
