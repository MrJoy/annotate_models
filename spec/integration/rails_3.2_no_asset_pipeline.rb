require 'common_validation'

module Annotate
  module Validations
    module Rails32NoAssetPipeline
      SCHEMA_ANNOTATION=<<-RUBY
# == Schema Information
#
# Table name: tasks
#
#  content    :string(255)
#  created_at :datetime         not null
#  id         :integer          not null, primary key
#  updated_at :datetime         not null
#
RUBY

      ROUTE_ANNOTATION=<<-RUBY
# == Route Map (Updated YYYY-MM-DD HH:MM)
#
#     tasks GET    /tasks(.:format)          tasks#index
#           POST   /tasks(.:format)          tasks#create
#  new_task GET    /tasks/new(.:format)      tasks#new
# edit_task GET    /tasks/:id/edit(.:format) tasks#edit
#      task GET    /tasks/:id(.:format)      tasks#show
#           PUT    /tasks/:id(.:format)      tasks#update
#           DELETE /tasks/:id(.:format)      tasks#destroy
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
