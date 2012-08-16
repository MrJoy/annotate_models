# These tasks are added to the project if you install annotate as a Rails plugin.
# (They are not used to build annotate itself.)

# Append annotations to Rake tasks for ActiveRecord, so annotate automatically gets
# run after doing db:migrate. 
# Unfortunately it relies on ENV for options; it'd be nice to be able to set options
# in a per-project config file so this task can read them.
task :set_annotation_options

namespace :db do
  task :migrate => :set_annotation_options do
    sh 'annotate_models' unless(ENV['skip_on_db_migrate'] =~ /(true|t|yes|y|1)$/i)
  end

  namespace :migrate do
    [:change, :up, :down, :reset, :redo].each do |t|
      task t => :set_annotation_options do
        sh 'annotate_models' unless(ENV['skip_on_db_migrate'] =~ /(true|t|yes|y|1)$/i)
      end
    end
  end
end


