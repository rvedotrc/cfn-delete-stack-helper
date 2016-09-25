Gem::Specification.new do |s|
  s.name        = 'cfn-delete-stack-helper'
  s.version     = '0.1.1'
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
lib/cfn_delete_stack_helper.rb
lib/cfn_delete_stack_helper/highlighting_text_table.rb
  ] + s.executables.map {|s| "bin/"+s}

  s.require_paths = ["lib"]

  s.add_dependency 'aws-sdk', "~> 2"
  s.add_dependency 'cloudsaw', ">= 0.4"
end
