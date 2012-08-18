#encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'annotate/annotate_models'
require 'annotate/active_record_patch'

describe AnnotateModels do
  def mock_class(table_name, primary_key, columns)
    options = {
      :connection   => mock("Conn", :indexes => []),
      :table_name   => table_name,
      :primary_key  => primary_key && primary_key.to_s,
      :column_names => columns.map { |col| col.name.to_s },
      :columns      => columns
    }

    mock("An ActiveRecord class", options)
  end

  def mock_column(name, type, options={})
    default_options = {
      :limit   => nil,
      :null    => false,
      :default => nil
    }

    stubs = default_options.dup
    stubs.merge!(options)
    stubs.merge!(:name => name, :type => type)

    mock("Column", stubs)
  end

  it { AnnotateModels.quote(nil).should eql("NULL") }
  it { AnnotateModels.quote(true).should eql("TRUE") }
  it { AnnotateModels.quote(false).should eql("FALSE") }
  it { AnnotateModels.quote(25).should eql("25") }
  it { AnnotateModels.quote(25.6).should eql("25.6") }
  it { AnnotateModels.quote(1e-20).should eql("1.0e-20") }

  it "should get schema info" do
    klass = mock_class(:users, :id, [
                                     mock_column(:id, :integer),
                                     mock_column(:name, :string, :limit => 50)
                                    ])

    AnnotateModels.get_schema_info(klass, "Schema Info").should eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id   :integer          not null, primary key
#  name :string(50)       not null
#

EOS
  end

  it "should get schema info even if the primary key is not set" do
    klass = mock_class(:users, nil, [
                                     mock_column(:id, :integer),
                                     mock_column(:name, :string, :limit => 50)
                                    ])

    AnnotateModels.get_schema_info(klass, "Schema Info").should eql(<<-EOS)
# Schema Info
#
# Table name: users
#
#  id   :integer          not null
#  name :string(50)       not null
#

EOS
  end

  it "should get schema info as RDoc" do
    klass = mock_class(:users, :id, [
                                     mock_column(:id, :integer),
                                     mock_column(:name, :string, :limit => 50)
                                    ])
    AnnotateModels.get_schema_info(klass, AnnotateModels::PREFIX, :format_rdoc => true).should eql(<<-EOS)
# #{AnnotateModels::PREFIX}
#
# Table name: users
#
# *id*::   <tt>integer, not null, primary key</tt>
# *name*:: <tt>string(50), not null</tt>
#--
# #{AnnotateModels::END_MARK}
#++

EOS
  end

  describe "#remove_annotation_of_file" do
    require "tmpdir"

    def create(file, body="hi")
      path = File.join(@dir, file)
      File.open(path, "w") do |f|
        f.puts(body)
      end
      return path
    end

    def content(path)
      File.read(path)
    end

    before :each do
      @dir = Dir.mktmpdir 'annotate_models'
    end

    it "should remove before annotate" do
      path = create "before.rb", <<-EOS
# == Schema Information
#
# Table name: foo
#
#  id                  :integer         not null, primary key
#  created_at          :datetime
#  updated_at          :datetime
#

class Foo < ActiveRecord::Base
end
      EOS

      AnnotateModels.remove_annotation_of_file(path)

      content(path).should == <<-EOS
class Foo < ActiveRecord::Base
end
      EOS
    end

    it "should remove after annotate" do
      path = create "after.rb", <<-EOS
class Foo < ActiveRecord::Base
end

# == Schema Information
#
# Table name: foo
#
#  id                  :integer         not null, primary key
#  created_at          :datetime
#  updated_at          :datetime
#

      EOS

      AnnotateModels.remove_annotation_of_file(path)

      content(path).should == <<-EOS
class Foo < ActiveRecord::Base
end
      EOS
    end
  end

  describe "annotating a file" do
    before do
      @model_dir = Dir.mktmpdir('annotate_models')
      (@model_file_name, @file_content) = write_model "user.rb", <<-EOS
class User < ActiveRecord::Base
end
      EOS

      @klass = mock_class(:users, :id, [
                                        mock_column(:id, :integer),
                                        mock_column(:name, :string, :limit => 50)
                                       ])
      @schema_info = AnnotateModels.get_schema_info(@klass, "== Schema Info")
    end

    def write_model file_name, file_content
      fname    = File.join(@model_dir, file_name)
      dirname = File.dirname(fname)
      FileUtils.mkdir_p(dirname)
      content = file_content
      File.open(fname, "wb") { |f| f.write content }
      return fname, content
    end

    def annotate_one_file options = {}
      AnnotateModels.annotate_one_file(@model_file_name, @schema_info, options)
    end

    it "should annotate the file before the model if position == 'before'" do
      annotate_one_file :position => "before"
      File.read(@model_file_name).should == "#{@schema_info}#{@file_content}"
    end

    it "should annotate before if given :position => :before" do
      annotate_one_file :position => :before
      File.read(@model_file_name).should == "#{@schema_info}#{@file_content}"
    end

    it "should annotate after if given :position => :after" do
      annotate_one_file :position => :after
      File.read(@model_file_name).should == "#{@file_content}\n#{@schema_info}"
    end

    it "should update annotate position" do
      annotate_one_file :position => :before

      another_schema_info = AnnotateModels.get_schema_info(mock_class(:users, :id, [mock_column(:id, :integer),]),
                                                           "== Schema Info")

      @schema_info = another_schema_info
      annotate_one_file :position => :after

      File.read(@model_file_name).should == "#{@file_content}\n#{another_schema_info}"
    end

    it "works with namespaced models (i.e. models inside modules/subdirectories)" do
      (model_file_name, file_content) = write_model "foo/user.rb", <<-EOS
class Foo::User < ActiveRecord::Base
end
      EOS

      klass = mock_class(:'foo_users', :id, [
                                        mock_column(:id, :integer),
                                        mock_column(:name, :string, :limit => 50)
                                       ])
      schema_info = AnnotateModels.get_schema_info(klass, "== Schema Info")
      AnnotateModels.annotate_one_file(model_file_name, schema_info, :position => :before)
      File.read(model_file_name).should == "#{schema_info}#{file_content}"
    end

    describe "if a file can't be annotated" do
       before do
         write_model('user.rb', <<-EOS)
           class User < ActiveRecord::Base
             raise "oops"
           end
         EOS
       end

       it "displays an error message" do
         capturing(:stdout) {
           AnnotateModels.do_annotations :model_dir => @model_dir, :is_rake => true
         }.should include("Unable to annotate user.rb: oops")
       end

       it "displays the full stack trace with --trace" do
         capturing(:stdout) {
           AnnotateModels.do_annotations :model_dir => @model_dir, :trace => true, :is_rake => true
         }.should include("/spec/annotate/annotate_models_spec.rb:")
       end

       it "omits the full stack trace without --trace" do
         capturing(:stdout) {
           AnnotateModels.do_annotations :model_dir => @model_dir, :trace => false, :is_rake => true
         }.should_not include("/spec/annotate/annotate_models_spec.rb:")
       end
    end

    describe "if a file can't be deannotated" do
       before do
         write_model('user.rb', <<-EOS)
           class User < ActiveRecord::Base
             raise "oops"
           end
         EOS
       end

       it "displays an error message" do
         capturing(:stdout) {
           AnnotateModels.remove_annotations :model_dir => @model_dir, :is_rake => true
         }.should include("Unable to deannotate user.rb: oops")
       end

       it "displays the full stack trace" do
         capturing(:stdout) {
           AnnotateModels.remove_annotations :model_dir => @model_dir, :trace => true, :is_rake => true
         }.should include("/user.rb:2:in `<class:User>'")
       end

       it "omits the full stack trace without --trace" do
         capturing(:stdout) {
           AnnotateModels.remove_annotations :model_dir => @model_dir, :trace => false, :is_rake => true
         }.should_not include("/user.rb:2:in `<class:User>'")
       end
    end
  end
end
