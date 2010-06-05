require 'rubygems'
require 'rake'
require 'echoe'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the mongo_rateable plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the mongo_rateable plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'MongoRateable'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


Echoe.new('acts_as_mongo_rateable', '0.2.0') do |p|
  p.description    = "A ratings system for Rails apps using MongoDB, with bayesian and straight averages, and weighting."
  p.url            = "http://github.com/mepatterson/acts_as_mongo_rateable"
  p.author         = "M. E. Patterson"
  p.email          = "madraziel @nospam@ gmail.com"
  p.ignore_pattern = ["tmp/*", "script/*"]
  p.development_dependencies = []
end