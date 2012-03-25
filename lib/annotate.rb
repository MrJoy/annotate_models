
require 'yaml'

module Annotate
  def self.version
    version_file = File.dirname(__FILE__) + "/../VERSION.yml"
    if File.exist?(version_file)
      config = YAML.load(File.read(version_file))
      version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
    else
      version = "0.0.0"
    end
  end

  TRUE_RE = /(true|t|yes|y|1)$/i
  def self.setup_options(options = {})
    options[:position_in_class] = ENV['position_in_class'] || ENV['position'] || 'before'
    options[:position_in_fixture] = ENV['position_in_fixture'] || ENV['position']  || 'before'
    options[:position_in_factory] = ENV['position_in_factory'] || ENV['position'] || 'before'
    options[:show_indexes] = ENV['show_indexes'] =~ TRUE_RE
    options[:simple_indexes] = ENV['simple_indexes'] =~ TRUE_RE
    options[:model_dir] = ENV['model_dir']
    options[:include_version] = ENV['include_version'] =~ TRUE_RE
    options[:require] = ENV['require'] ? ENV['require'].split(',') : []
    options[:exclude_tests] = ENV['exclude_tests'] =~ TRUE_RE
    options[:exclude_fixtures] = ENV['exclude_fixtures'] =~ TRUE_RE
    options[:ignore_model_sub_dir] = ENV['ignore_model_sub_dir'] =~ TRUE_RE
    options[:format_rdoc] = ENV['format_rdoc'] =~ TRUE_RE
    options[:format_markdown] = ENV['format_markdown'] =~ TRUE_RE
    options[:no_sort] = ENV['no_sort'] =~ TRUE_RE
    options[:force] = ENV['force'] =~ TRUE_RE

    return options
  end

  def self.load_tasks
    return if(@loaded_tasks)
    @loaded_tasks = true

    # Rails 3 wants to load our .rake files for us.
    # TODO: selectively do this require on Rails 2.x?
    Dir[File.join(File.dirname(__FILE__), 'tasks', '**/*.rake')].each { |rake| load rake }
  end
end
