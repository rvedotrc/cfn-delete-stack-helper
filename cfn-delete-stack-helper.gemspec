lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cfn_delete_stack_helper/version'

Gem::Specification.new do |s|
  s.name        = 'cfn-delete-stack-helper'
  s.version     = CfnDeleteStackHelper::VERSION
  s.licenses    = [ 'Apache-2.0' ]
  s.date        = '2016-09-23'
  s.summary     = 'Safety checks before deleting an AWS CloudFormation stack'
  s.description = '
    cfn-delete-stack-helper runs various safety checks before deleting an AWS
    CloudFormation stack.
    
    It shows:
     - what would be deleted, if the stack deletion were to succeed;

    It also aims to:
     - predict certain kinds of failure to delete (for example, non-empty S3
       buckets);
     - advise on to what extent the deletions would be reversible.

    Respects $https_proxy.
  '
  s.homepage    = 'https://github.com/rvedotrc/cfn-delete-stack-helper'
  s.authors     = ['Rachel Evans']
  s.email       = 'cfn-delete-stack-helper-git@rve.org.uk'

  s.executables = %w[
cfn-delete-stack-helper
  ]

  s.files       = %w[
lib/cfn_delete_stack_helper/highlighting_text_table.rb
lib/cfn_delete_stack_helper/resource_in_use_checker/resource_type/aws_ec2_securitygroup.rb
lib/cfn_delete_stack_helper/resource_in_use_checker/resource_type/aws_s3_bucket.rb
lib/cfn_delete_stack_helper/resource_in_use_checker.rb
lib/cfn_delete_stack_helper/version.rb
lib/cfn_delete_stack_helper.rb
  ] + s.executables.map {|s| "bin/"+s}

  s.require_paths = ["lib"]

  s.add_dependency 'aws-sdk', '~> 2.0'
  s.add_dependency 'cfn-events', '~> 0.1'
end
