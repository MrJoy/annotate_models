if(!ENV['is_cli'])
  task :set_annotation_options
  task :annotate_models => :set_annotation_options
end

desc "Add schema information (as comments) to model and fixture files"
task :annotate_models => :environment do
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'annotate', 'annotate_models'))
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'annotate', 'active_record_patch'))

  options=Annotate.setup_options({ :is_rake => true })
  AnnotateModels.do_annotations(options)
end

desc "Remove schema information from model and fixture files"
task :remove_annotation => :environment do
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'annotate', 'annotate_models'))
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'annotate', 'active_record_patch'))

  options=Annotate.setup_options({ :is_rake => true })
  AnnotateModels.remove_annotations(options)
end
