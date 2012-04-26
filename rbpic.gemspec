
require './lib/rbpic/gen'

Gem::Specification.new do |s|
  s.name        = 'rbpic'
  s.version     = RbPIC::VERSION
  s.date        = '2012-04-24'
  s.summary     = 'High-level assembly language for the PIC10.'
  s.description = <<-EOS
rbpic
=====

A high-level assembly dialect (RSM) that compiles into PIC assembly that
targets the PIC10 series of microprocessors by Microchip.
EOS

  s.author        = 'Patrick J. Franz'
  s.email         = ['patrick@z-dyne.com']
  s.homepage      = 'http://github.com/zdyne/rbpic'

  s.require_paths = ['lib']

  s.files         = ['lib/rbpic/gen.rb']
  s.executables << 'rbpic-compile'

  s.required_ruby_version = '>= 1.9.2'

  s.add_runtime_dependency 'trollop'
  s.add_development_dependency 'wrong'
end
