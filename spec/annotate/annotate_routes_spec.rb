require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'annotate/annotate_routes'

describe AnnotateRoutes do

  def mock_file(stubs={})
    @mock_file ||= mock(File, stubs)
  end

  describe "Annotate Job" do

    it "should check if routes.rb exists" do
      File.should_receive(:exists?).with("config/routes.rb").and_return(false)
      AnnotateRoutes.should_receive(:puts).with("Can`t find routes.rb")
      AnnotateRoutes.do_annotate
    end

    describe "When Annotating" do

      before(:each) do
        File.should_receive(:exists?).with("config/routes.rb").and_return(true)
        AnnotateRoutes.should_receive(:`).with("rake routes").and_return("bad line\ngood line")
        File.should_receive(:open).with("config/routes.rb", "wb").and_yield(mock_file)
        AnnotateRoutes.should_receive(:puts).with("Route file annotated.")
      end

      describe "With Annotations at the Top of the File" do
        it "should annotate and add a newline as a spacer from the content" do
          File.should_receive(:read).with("config/routes.rb").and_return("ActionController::Routing...\nfoo\n")
          @mock_file.should_receive(:puts).with(/^# == Route Map \(Updated \d{4}-\d{2}-\d{2} \d{2}:\d{2}\)\n#\n# good line\n\nActionController::Routing...\nfoo\n/)
          AnnotateRoutes.do_annotate
        end

        it "should always ensure a trailing newline on the file." do
          File.should_receive(:read).with("config/routes.rb").and_return("ActionController::Routing...\nfoo")
          @mock_file.should_receive(:puts).with(/^# == Route Map \(Updated \d{4}-\d{2}-\d{2} \d{2}:\d{2}\)\n#\n# good line\n\nActionController::Routing...\nfoo\n/)
          AnnotateRoutes.do_annotate
        end

        it "should not add a newline if there are empty lines already." do
          File.should_receive(:read).with("config/routes.rb").and_return("\n\n\nActionController::Routing...\nfoo\n")
          @mock_file.should_receive(:puts).with(/^# == Route Map \(Updated \d{4}-\d{2}-\d{2} \d{2}:\d{2}\)\n#\n# good line\n\n\n\nActionController::Routing...\nfoo\n/)
          AnnotateRoutes.do_annotate
        end
      end

      describe "With Annotations at the Bottom of the File" do
        it "should annotate and add a newline as a spacer from the content" do
          File.should_receive(:read).with("config/routes.rb").and_return("ActionController::Routing...\nfoo\n")
          @mock_file.should_receive(:puts).with(/^ActionController::Routing...\nfoo\n\n# == Route Map \(Updated \d{4}-\d{2}-\d{2} \d{2}:\d{2}\)\n#\n# good line\n/)
          AnnotateRoutes.do_annotate({ :position_in_routes => 'after' })
        end

        it "should always ensure a trailing newline on the file." do
          File.should_receive(:read).with("config/routes.rb").and_return("ActionController::Routing...\nfoo")
          @mock_file.should_receive(:puts).with(/^ActionController::Routing...\nfoo\n\n# == Route Map \(Updated \d{4}-\d{2}-\d{2} \d{2}:\d{2}\)\n#\n# good line\n/)
          AnnotateRoutes.do_annotate({ :position_in_routes => 'after' })
        end

        it "should not add a newline if there are empty lines already." do
          File.should_receive(:read).with("config/routes.rb").and_return("ActionController::Routing...\nfoo\n\n\n")
          @mock_file.should_receive(:puts).with(/^ActionController::Routing...\nfoo\n\n\n\n# == Route Map \(Updated \d{4}-\d{2}-\d{2} \d{2}:\d{2}\)\n#\n# good line\n/)
          AnnotateRoutes.do_annotate({ :position_in_routes => 'after' })
        end
      end

    end

    describe "When Removing Annotations" do

      before(:each) do
        File.should_receive(:exists?).with("config/routes.rb").and_return(true)
        File.should_receive(:open).with("config/routes.rb", "wb").and_yield(mock_file)
        AnnotateRoutes.should_receive(:puts).with("Removed annotations from routes file.")
      end

      describe "With Annotations at the Top of the File" do

        it "should remove annotations and the newline it added." do
          File.should_receive(:read).with("config/routes.rb").and_return("# == Route Map (Updated 2012-08-16 12:00)\n#\n# good line\n\nActionController::Routing...\nfoo\n")
          @mock_file.should_receive(:puts).with("ActionController::Routing...\nfoo\n")
          AnnotateRoutes.remove_annotations
        end

        it "should remove any large chunks of whitepace adjacent to the header." do
          File.should_receive(:read).with("config/routes.rb").and_return("# == Route Map (Updated 2012-08-16 12:00)\n#\n# good line\n\n\n\n\n\n\n\n\n\n\n\n\n\nActionController::Routing...\nfoo\n")
          @mock_file.should_receive(:puts).with("ActionController::Routing...\nfoo\n")
          AnnotateRoutes.remove_annotations
        end

        it "... but only from the side of the file that had the header." do
          File.should_receive(:read).with("config/routes.rb").and_return("# == Route Map (Updated 2012-08-16 12:00)\n#\n# good line\n\n\n\n\n\n\n\n\n\n\n\n\n\nActionController::Routing...\nfoo\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
          @mock_file.should_receive(:puts).with("ActionController::Routing...\nfoo\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
          AnnotateRoutes.remove_annotations
        end

      end

      describe "With Annotations at the Bottom of the File" do

        it "should remove annotations and the newline it added." do
          File.should_receive(:read).with("config/routes.rb").and_return("ActionController::Routing...\nfoo\n\n# == Route Map (Updated 2012-08-16 12:00)\n#\n# good line\n")
          @mock_file.should_receive(:puts).with("ActionController::Routing...\nfoo\n")
          AnnotateRoutes.remove_annotations
        end

        it "should remove any large chunks of whitepace adjacent to the header." do
          File.should_receive(:read).with("config/routes.rb").and_return("ActionController::Routing...\nfoo\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n# == Route Map (Updated 2012-08-16 12:00)\n#\n# good line")
          @mock_file.should_receive(:puts).with("ActionController::Routing...\nfoo\n")
          AnnotateRoutes.remove_annotations
        end

        it "... but only from the side of the file that had the header." do
          File.should_receive(:read).with("config/routes.rb").and_return("\n\n\n\n\n\n\n\n\n\n\n\n\n\nActionController::Routing...\nfoo\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n# == Route Map (Updated 2012-08-16 12:00)\n#\n# good line")
          @mock_file.should_receive(:puts).with("\n\n\n\n\n\n\n\n\n\n\n\n\n\nActionController::Routing...\nfoo\n")
          AnnotateRoutes.remove_annotations
        end

      end

    end

  end

end
