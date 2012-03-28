annotate_lib = File.expand_path(File.dirname(File.dirname(__FILE__)))

task :set_annotation_options
task :annotate_models => :set_annotation_options

desc "Add schema information (as comments) to model and fixture files"
task :annotate_models => :environment do
  require "#{annotate_lib}/annotate/annotate_models"
  require "#{annotate_lib}/annotate/active_record_patch"

  options=Annotate.setup_options({ :is_rake => true })
  AnnotateModels.do_annotations(options)
end

desc "Remove schema information from model and fixture files"
task :remove_annotation => :environment do
  require "#{annotate_lib}/annotate/annotate_models"
  require "#{annotate_lib}/annotate/active_record_patch"

  options=Annotate.setup_options({ :is_rake => true })
  AnnotateModels.remove_annotations(options)
end
