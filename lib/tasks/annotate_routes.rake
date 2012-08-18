Annotate.loaded_tasks = true

task :set_annotation_options

desc "Prepends the route map to the top of routes.rb"
task :annotate_routes => :set_annotation_options do
  # TODO: Make this obey options...
  sh "annotate_routes"
end

desc "Remove route information from routes file"
task :remove_route_annotation => :set_annotation_options do
  # Ghetto hack because when migrating from scratch we'll have old versions
  # of the model code loaded which could be a serious problem for accuracy.
  sh 'annotate_routes --delete'
end
