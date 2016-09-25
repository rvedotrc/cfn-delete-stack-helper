require 'aws-sdk'
require 'json'

module CfnDeleteStackHelper

  class ResourceInUseChecker

    attr_reader :description, :resources, :aws_client_config, :use_colour

    def initialize(description, resources, aws_client_config, use_colour)
      @description = description
      @resources = resources
      @aws_client_config = aws_client_config
      @use_colour = use_colour
    end

    def run
      puts "Checking to see if resources are obviously in use ..."

      template = JSON.parse(
        Aws::CloudFormation::Client.new(aws_client_config).get_template(stack_name: description.stack_id).template_body
      )

      resources.each do |resource|
        check_resource resource, template["Resources"][resource.logical_resource_id]
      end

      puts ""
    end

    def check_resource(resource_summary, resource_template)
      case resource_summary.resource_status
      when "DELETE_SKIPPED", "DELETE_COMPLETE"
        return
      end

      case resource_template["DeletionPolicy"]
      when nil, "Delete"
      else
        return
      end

      # FIXME: we're trusting that AWS resource types are always of a safe form
      type = resource_summary.resource_type.gsub /::/, '_'
      checker_class = "CfnDeleteStackHelper::ResourceInUseChecker::ResourceType::#{type}"
      req = "resource_in_use_checker/resource_type/#{type.downcase}"

      begin
        require_relative req
        # Eww, eval
        eval(checker_class).new(self).check(resource_summary, resource_template)
      rescue LoadError
        # We assume no checker
      end
    end

    def resource_in_use(resource_summary, message)
      line1 = "WARNING: deletion of #{resource_summary.logical_resource_id.inspect} will fail because it is in use"
      line2 = "  Reason: #{message}"

      if use_colour
        puts line1.red, line2.red
      else
        puts line1, line2
      end
    end

    def additional_info(message)
      puts "  Info: #{message}"
    end

  end

end
