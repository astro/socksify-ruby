#!/usr/bin/env ruby

require 'rubygems'

spec = Gem::Specification.new do |s|
  s.name = 'socksify-a'
  s.version = "1.1.2"
  s.summary = "Redirect all TCPSockets through a SOCKS 4a/5 proxy"
  s.author = "Andrey Kouznetsov"
  s.email = "smixok@gmail.com"
  s.homepage = "http://smix.name"
  # s.rubyforge_project = 'socksify-a'
  s.files = %w{COPYING}
  s.files += Dir.glob("lib/**/*")
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
