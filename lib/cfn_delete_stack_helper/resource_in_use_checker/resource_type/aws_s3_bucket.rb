module CfnDeleteStackHelper

  class ResourceInUseChecker

    class ResourceType

      class AWS_S3_Bucket

        attr_reader :checker

        def initialize(checker)
          @checker = checker
        end

        def check(resource_summary, resource_template)
          bucket_name = resource_summary.physical_resource_id

          # Should be in the correct region already ... right?
          s3_client = Aws::S3::Client.new(checker.aws_client_config)

          listing = s3_client.list_objects(bucket: bucket_name, max_keys: 1)

          unless listing.contents.empty?
            checker.resource_in_use resource_summary, "bucket is not empty"
          end
        end


      end

    end

  end

end
