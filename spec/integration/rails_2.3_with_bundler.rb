require 'common_validation'

module Annotate
  module Validations
    module Rails23WithBundler
      SCHEMA_ANNOTATION=<<-RUBY
# == Schema Information
#
# Table name: tasks
#
#  id         :integer          not null, primary key
#  content    :string(255)
#  created_at :datetime
#  updated_at :datetime
#
RUBY

      ROUTE_ANNOTATION=<<-RUBY
# == Route Map (Updated YYYY-MM-DD HH:MM)
#
#     tasks GET    /tasks(.:format)          {:controller=>"tasks", :action=>"index"}
#           POST   /tasks(.:format)          {:controller=>"tasks", :action=>"create"}
#  new_task GET    /tasks/new(.:format)      {:controller=>"tasks", :action=>"new"}
# edit_task GET    /tasks/:id/edit(.:format) {:controller=>"tasks", :action=>"edit"}
#      task GET    /tasks/:id(.:format)      {:controller=>"tasks", :action=>"show"}
#           PUT    /tasks/:id(.:format)      {:controller=>"tasks", :action=>"update"}
#           DELETE /tasks/:id(.:format)      {:controller=>"tasks", :action=>"destroy"}
#
RUBY

      def self.test_commands
        return Annotate::Validations::Common.test_commands
      end

      def self.verify_output(output)
        return Annotate::Validations::Common.verify_output(output)
      end

      def self.verify_files(test_rig)
        return Annotate::Validations::Common.verify_files({
          :model => true,
          :test => true,
          :fixture => true,
          :factory => false,
          :routes => true
        }, test_rig, SCHEMA_ANNOTATION, ROUTE_ANNOTATION, true)
      end
    end
  end
end
