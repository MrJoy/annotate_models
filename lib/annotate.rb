$:.unshift(File.dirname(__FILE__))
require 'annotate/version'
require 'annotate/annotate_models'
require 'annotate/annotate_routes'

begin
  # ActiveSupport 3.x...
  require 'active_support/hash_with_indifferent_access'
rescue Exception => e
  # ActiveSupport 2.x...
  require 'active_support/core_ext/hash/indifferent_access'
end

module Annotate
  OPTIONS = proc do |opts, mode, has_set_position, target|
    if(mode == :both)
      opts.on('-r', '--routes',
              'Annotate the Routes.rb file instead of annotating other items like the model/test/fixture/factory.') do
        target[:klass] = AnnotateRoutes
      end
    end

    opts.on('-p', '--position [before|after]', ['before', 'after'],
            "Place the annotations at the top (before) or the bottom (after) of the model/test/fixture/factory/routes file(s)") do |p|
      ENV['position'] = p
      [
        'position_in_class','position_in_factory','position_in_fixture','position_in_test', 'position_in_routes'
      ].each do |key|
        ENV[key] = p unless(has_set_position[key])
      end
    end

    if(mode == :models || mode == :both)
      opts.on('--pc', '--position-in-class [before|after]', ['before', 'after'],
              "Place the annotations at the top (before) or the bottom (after) of the model file") do |p|
        ENV['position_in_class'] = p
        has_set_position['position_in_class'] = true
      end

      opts.on('--pf', '--position-in-factory [before|after]', ['before', 'after'],
              "Place the annotations at the top (before) or the bottom (after) of any factory files") do |p|
        ENV['position_in_factory'] = p
        has_set_position['position_in_factory'] = true
      end

      opts.on('--px', '--position-in-fixture [before|after]', ['before', 'after'],
              "Place the annotations at the top (before) or the bottom (after) of any fixture files") do |p|
        ENV['position_in_fixture'] = p
        has_set_position['position_in_fixture'] = true
      end

      opts.on('--pt', '--position-in-test [before|after]', ['before', 'after'],
              "Place the annotations at the top (before) or the bottom (after) of any test files") do |p|
        ENV['position_in_test'] = p
        has_set_position['position_in_test'] = true
      end
    end

    if(mode == :routes || mode == :both)
      opts.on('--pr', '--position-in-routes [before|after]', ['before', 'after'],
              "Place the annotations at the top (before) or the bottom (after) of any test files") do |p|
        ENV['position_in_routes'] = p
        has_set_position['position_in_routes'] = true
      end
    end

    opts.on('-R', '--require path',
            "Additional file to require before loading models, may be used multiple times") do |path|
      if !ENV['require'].blank?
        ENV['require'] = ENV['require'] + ",#{path}"
      else
        ENV['require'] = path
      end
    end

    opts.on('-d', '--delete',
            "Remove annotations from all relevant files") do
      # Mutate the string, don't change the reference, or the value won't be
      # seen by the caller.
      target[:task] = :remove_annotations
    end

    opts.on('-v', '--version',
            "Show the current version of this gem") do
      puts "annotate v#{Annotate.version}"; exit
    end
  end

  ##
  # The set of available options to customize the behavior of Annotate.
  #
  POSITION_OPTIONS=[
    :position_in_routes, :position_in_class, :position_in_test,
    :position_in_fixture, :position_in_factory, :position,
  ]
  FLAG_OPTIONS=[
    :show_indexes, :simple_indexes, :include_version, :exclude_tests,
    :exclude_fixtures, :exclude_factories, :ignore_model_sub_dir,
    :format_bare, :format_rdoc, :format_markdown, :sort, :force, :trace,
  ]
  PATH_OPTIONS=[
    :model_dir, :require,
  ]


  ##
  # Set default values that can be overridden via environment variables.
  #
  def self.set_defaults(options = {})
    return if(@has_set_defaults)
    @has_set_defaults = true
    options = HashWithIndifferentAccess.new(options)
    [POSITION_OPTIONS, FLAG_OPTIONS, PATH_OPTIONS].flatten.each do |key|
      if(options.has_key?(key))
        default_value = if(options[key].is_a?(Array))
          options[key].join(",")
        else
          options[key]
        end
      end
      default_value = ENV[key.to_s] if(!ENV[key.to_s].blank?)
      ENV[key.to_s] = default_value.to_s
    end
  end

  TRUE_RE = /^(true|t|yes|y|1)$/i
  def self.setup_options(options = {})
    POSITION_OPTIONS.each do |key|
      options[key] = fallback(ENV[key.to_s], ENV['position'], 'before')
    end
    FLAG_OPTIONS.each do |key|
      options[key] = true?(ENV[key.to_s])
    end
    PATH_OPTIONS.each do |key|
      options[key] = (!ENV[key.to_s].blank?) ? ENV[key.to_s].split(',') : []
    end

    if(options[:model_dir].count == 0)
      options[:model_dir] = ['app/models']
    end

    return options
  end

  def self.skip_on_migration?
    ENV['skip_on_db_migrate'] =~ TRUE_RE
  end

  def self.loaded_tasks=(val); @loaded_tasks = val; end
  def self.loaded_tasks; return @loaded_tasks; end

  def self.load_tasks
    return if(self.loaded_tasks)
    self.loaded_tasks = true

    Dir[File.join(File.dirname(__FILE__), 'tasks', '**/*.rake')].each { |rake| load rake }
  end

  def self.load_requires(options)
    options[:require].each { |path| require path } if options[:require].count > 0
  end

  def self.eager_load(options)
    self.load_requires(options)
    require "annotate/active_record_patch"

    if(defined?(Rails))
      if(Rails.version.split('.').first.to_i < 3)
        Rails.configuration.eager_load_paths.each do |load_path|
          matcher = /\A#{Regexp.escape(load_path)}(.*)\.rb\Z/
          Dir.glob("#{load_path}/**/*.rb").sort.each do |file|
            require_dependency file.sub(matcher, '\1')
          end
        end
      else
        klass = Rails::Application.send(:subclasses).first
        klass.eager_load!
      end
    else
      options[:model_dir].each do |dir|
        FileList["#{dir}/**/*.rb"].each do |fname|
          require File.expand_path(fname)
        end
      end
    end
  end

  def self.bootstrap_rake
    begin
      require 'rake/dsl_definition'
    rescue Exception => e
      # We might just be on an old version of Rake...
    end
    require 'rake'

    if File.exists?('./Rakefile')
      load './Rakefile'
    end
    Rake::Task[:environment].invoke rescue nil
    if(!defined?(Rails))
      # Not in a Rails project, so time to load up the parts of
      # ActiveSupport we need.
      require 'active_support'
      require 'active_support/core_ext/class/subclasses'
      require 'active_support/core_ext/string/inflections'
    end
    self.load_tasks
    Rake::Task[:set_annotation_options].invoke
  end

private

  def self.fallback(*args)
    return args.detect { |arg| !arg.blank? }
  end

  def self.true?(val)
    return false if(val.blank?)
    return false unless(val =~ TRUE_RE)
    return true
  end
end
