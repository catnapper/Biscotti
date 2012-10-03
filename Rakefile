require "bundler/gem_tasks"

task :play do
  $: << File.join(Dir.pwd, 'lib')
  require 'biscotti'
  require 'pry'
  binding.pry
end

