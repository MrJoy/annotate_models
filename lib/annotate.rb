$:.unshift(File.dirname(__FILE__))
require "annotate/version"

module Annotate
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
    :format_bare, :format_rdoc, :format_markdown, :no_sort, :force, :trace,
  ]
  OTHER_OPTIONS=[
    :model_dir, :require,
  ]


  ##
  # Set default values that can be overridden via environment variables.
  #
  def self.set_defaults(options = {})
    return if(@has_set_defaults)
    @has_set_defaults = true
    options = HashWithIndifferentAccess.new(options)
    [POSITION_OPTIONS, FLAG_OPTIONS, OTHER_OPTIONS].flatten.each do |key|
      if(options.has_key?(key))
        default_value = if(options[key].is_a?(Array))
          options[key].join(",")
        else
          options[key]
        end
      end
      default_value = ENV[key.to_s] if(!ENV[key.to_s].blank?)
      ENV[key.to_s] = default_value
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

    options[:model_dir] = ENV['model_dir']
    options[:require]   = (!ENV['require'].blank?) ? ENV['require'].split(',') : []

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

    # Rails 3 wants to load our .rake files for us.
    if(Rails.version.split('.').first.to_i < 3)
      Dir[File.join(File.dirname(__FILE__), 'tasks', '**/*.rake')].each { |rake| load rake }
    end
  end

  def self.eager_load
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
