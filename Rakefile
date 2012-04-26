require 'rake/testtask'


Rake::TestTask.new do |t|
  t.pattern = 'test/*.rb'
  t.verbose = true
end

task :default => :test


task :build do
  system "gem build rbpic.gemspec" or raise
end

