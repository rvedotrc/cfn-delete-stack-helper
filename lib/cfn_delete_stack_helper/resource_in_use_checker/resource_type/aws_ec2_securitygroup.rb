module CfnDeleteStackHelper

  class ResourceInUseChecker

    class ResourceType

      class AWS_EC2_SecurityGroup

        attr_reader :checker

        def initialize(checker)
          @checker = checker
        end

        def check(resource_summary, resource_template)
          # Is this SG in use by anything outside of this stack?
          # (It would be very common for it to be used by something /inside/,
          # e.g. an AWS::AutoScaling::LaunchConfiguration).
          
          sg_id = resource_summary.physical_resource_id
          as_client = Aws::AutoScaling::Client.new(checker.aws_client_config)
          ec2_client = Aws::EC2::Client.new(checker.aws_client_config)

          instances = ec2_client.describe_instances(
            filters: [ { name: "instance.group-id", values: [sg_id] } ],
          )
          instances = instances.reservations.map(&:instances).flatten
          instances = discard_our_asgs(instances)
          instances = discard_terminated(instances)
          unless instances.empty?
            checker.resource_in_use resource_summary, "in use by EC2 instance(s) #{instances.map(&:instance_id)}"
            instances.each do |i|
              checker.additional_info "Instance #{i.instance_id} has tags #{ec2_instance_tags(i).inspect}"
            end
          end

          # TODO, referenced by any EC2 Security Group ingress/egress rule?
          # TODO, referenced by any AutoScaling LaunchConfiguration?
        end

        def discard_our_asgs(instances)
          instances.reject do |i|
            # Is tags ever nil? Defensive.
            tags_hash = ec2_instance_tags i
            asg_name = tags_hash["aws:autoscaling:groupName"]
            checker.resources.map(&:physical_resource_id).include? asg_name
          end
        end

        def discard_terminated(instances)
          instances.reject {|i| i.state.name == "terminated"}
        end

        def ec2_instance_tags(i)
          (i.tags || []).map {|t| [t.key, t.value]}.to_h
        end

      end

    end

  end

end
