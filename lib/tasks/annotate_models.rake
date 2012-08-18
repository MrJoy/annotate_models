Annotate.loaded_tasks = true

task :set_annotation_options

desc "Add schema information (as comments) to model and fixture files"
task :annotate_models => :set_annotation_options do
  # Ghetto hack because when migrating from scratch we'll have old versions
  # of the model code loaded which could be a serious problem for accuracy.
  sh 'annotate_models'
end

desc "Remove schema information from model and fixture files"
task :remove_model_annotation => :set_annotation_options do
  # Ghetto hack because when migrating from scratch we'll have old versions
  # of the model code loaded which could be a serious problem for accuracy.
  sh 'annotate_models --delete'
end
