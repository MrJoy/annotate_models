# Note : this causes annoying psych warnings under Ruby 1.9.2-p180; to fix, upgrade to 1.9.3
begin
  require 'bundler'
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake/dsl_definition'
require 'rake'
include Rake::DSL

require "./lib/annotate"

require 'jeweler'
DEVELOPMENT_GROUPS=[:development, :test]
RUNTIME_GROUPS=Bundler.definition.groups - DEVELOPMENT_GROUPS
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20
  # for more options.
  gem.name = "annotate"
  gem.homepage = "http://github.com/ctran/annotate_models"
  gem.rubyforge_project = "annotate"
  gem.license = "Ruby"
  gem.summary = %q{Annotates Rails Models, routes, fixtures, and others based on the database schema.}
  gem.description = %q{Annotates Rails/ActiveRecord Models, routes, fixtures, and others based on the database schema.}
  gem.email = ["alex@stinky.com", "ctran@pragmaquest.com", "x@nofxx.com", "turadg@aleahmad.net", "jon@cloudability.com"]
  gem.authors = ["Cuong Tran", "Alex Chaffee", "Marcos Piccinini", "Turadg Aleahmad", "Jon Frisby"]
  gem.require_paths = ["lib"]
  # gem.rdoc_options = ["--charset=UTF-8"]
  # gem.required_ruby_version = "> 1.9.2"

  # Jeweler wants to manage dependencies for us when there's a Gemfile.
  # We override it so we can skip development dependencies, and so we can
  # do lockdowns on runtime dependencies while letting them float in the
  # Gemfile.
  #
  # This allows us to ensure that using Friston as a gem will behave how
  # we want, while letting us handle updating dependencies gracefully.
  #
  # The lockfile is already used for production deployments, but NOT having
  # it be obeyed in the gemspec meant that we needed to add explicit
  # lockdowns in the Gemfile to avoid having weirdness ensue in GUI.
  #
  # This is probably a not particularly great way of handling this, but it
  # should suffice for now.
  gem.dependencies.clear

  Bundler.load.dependencies_for(*RUNTIME_GROUPS).each do |dep|
    # gem.add_dependency dep.name, *dependency.requirement.as_list
    # dev_resolved = Bundler.definition.specs_for(DEVELOPMENT_GROUPS).select { |spec| spec.name == dep.name }.first
    runtime_resolved = Bundler.definition.specs_for(Bundler.definition.groups - DEVELOPMENT_GROUPS).select { |spec| spec.name == dep.name }.first
    if(!runtime_resolved.nil?)
      gem.add_dependency(dep.name, dep.requirement)
    end
  end


  gem.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.extra_rdoc_files = ['README.rdoc', 'CHANGELOG.rdoc', 'TODO.rdoc']

  gem.files.reject! do |fn|
    fn =~ /^Gemfile.*/ ||
    fn =~ /^Rakefile/ ||
    fn =~ /^\.rvmrc/ ||
    fn =~ /^\.gitignore/ ||
    fn =~ /^\.rspec/ ||
    fn =~ /^\.document/ ||
    fn =~ /^\.yardopts/ ||
    fn =~ /^pkg/ ||
    fn =~ /^spec/ ||
    fn =~ /^doc/ ||
    fn =~ /^vendor\/cache/
  end
end
Jeweler::RubygemsDotOrgTasks.new

namespace :jeweler do
  task :clobber do
    FileUtils.rm_f("pkg")
  end
end
task :clobber => :'jeweler:clobber'

# want other tests/tasks run by default? Add them to the list
task :default => [:spec]

require "rspec/core/rake_task" # RSpec 2.0
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = ['spec/*_spec.rb', 'spec/**/*_spec.rb']
end

task :integration_environment do
  require './spec/spec_helper'
end

namespace :gemsets do
  desc "Completely empty any gemsets used by scenarios, so they'll be perfectly clean on the next run."
  task :empty => [:integration_environment, :'templates:rebuild'] do
    Annotate::Integration::SCENARIOS.each do |test_rig, base_dir, test_name|
      Annotate::Integration.empty_gemset(test_rig)
    end
  end
end
task :clobber => :'gemsets:empty'

namespace :integration do
  desc "Remove any cruft generated by manual debugging runs which is .gitignore'd."
  task :clean => :integration_environment do
    Annotate::Integration.nuke_all_cruft
  end

  desc "Reset any changed files, and remove any untracked files in spec/integration/*/, plus run integration:clean."
  task :clobber => [:integration_environment, :'integration:clean'] do
    Annotate::Integration.reset_dirty_files
    Annotate::Integration.clear_untracked_files
  end
end
task :clobber => :'integration:clobber'

namespace :templates do
  desc "Rebuild templates used for interactive debugging of integration scenarios."
  task :rebuild => :integration_environment do
    Annotate::Integration::SCENARIOS.each do |test_rig, base_dir, test_name|
      puts "Compiling interactive-debugging templates for #{test_name}..."
      # Compile our debugging templates...
      Annotate::Integration.compile_templates(base_dir, test_rig, true)
    end
  end
end

require 'yard'
YARD::Rake::YardocTask.new do |t|
  # t.files   = ['features/**/*.feature', 'features/**/*.rb', 'lib/**/*.rb']
  # t.options = ['--any', '--extra', '--opts'] # optional
end

namespace :yard do
  task :clobber do
    FileUtils.rm_f(".yardoc")
    FileUtils.rm_f("doc")
  end
end
task :clobber => :'yard:clobber'

namespace :rubinius do
  task :clobber do
    FileList["**/*.rbc"].each { |fname| FileUtils.rm_f(fname) }
  end
end
task :clobber => :'rubinius:clobber'
