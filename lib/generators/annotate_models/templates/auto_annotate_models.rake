# NOTE: only doing this in development as some production environments (Heroku)
# NOTE: are sensitive to local FS writes, and besides -- it's just not proper
# NOTE: to have a dev-mode tool do its thing in production.
if(Rails.env.development?)
  task :set_annotation_options do
    Annotate.set_defaults({
      'position_in_routes'   => "before"
      'position_in_class'    => "before",
      'position_in_test'     => "before",
      'position_in_fixture'  => "before",
      'position_in_factory'  => "before",
      'show_indexes'         => "true",
      'simple_indexes'       => "false",
      'model_dir'            => "app/models",
      'include_version'      => "false",
      'require'              => "",
      'exclude_tests'        => "false",
      'exclude_fixtures'     => "false",
      'exclude_factories'    => "false",
      'ignore_model_sub_dir' => "false",
      'skip_on_db_migrate'   => "false",
      'format_bare'          => "false",
      'format_rdoc'          => "false",
      'format_markdown'      => "true",
      'no_sort'              => "false",
      'force'                => "false",
    })
  end

  Annotate.load_tasks
end
