desc "Prepends the route map to the top of routes.rb"
task :annotate_routes => :environment do
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'annotate', 'annotate_routes'))
  # TODO: Make this obey options...
  AnnotateRoutes.do_annotate
end
