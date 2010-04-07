require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "relate"
    gem.summary = %Q{Gem that encapsulates common model relationships}
    gem.description = %Q{Behave is a Ruby Gem that encapsulates a number of commen model relationships.}
    gem.email = "mhgibbons@me.com"
    gem.homepage = "http://github.com/accuser/relate"
    gem.authors = ["Matthew Gibbons"]
    gem.add_dependency "activemodel", ">= 3.0.0.beta2"
    gem.add_dependency "activesupport", ">= 3.0.0.beta2"
    gem.add_dependency "delayed_job", ">= 1.7.0"
    gem.add_dependency "mongoid", ">= 2.0.0.beta2"
    gem.add_dependency "mongoid_cached_document", ">= 0.1.0"
    gem.add_dependency "sunspot_rails", ">= 1.0.0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "relate #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
