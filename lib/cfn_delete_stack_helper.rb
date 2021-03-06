# Copyright 2016 Rachel Evans
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'cfn-events'

require_relative 'cfn_delete_stack_helper/highlighting_text_table'
require_relative 'cfn_delete_stack_helper/resource_in_use_checker'
require_relative 'cfn_delete_stack_helper/version'

module CfnDeleteStackHelper

  class Main
    
    def initialize(argv)
      @argv = argv
    end
    
    def run
      unless @argv.count == 1
        $stderr.puts "Usage: cfn-delete-stack-helper STACK_NAME_OR_ID"
        exit 1
      end

      stack_name_or_id = @argv.first
      run = Runner.new(aws_client_config, stack_name_or_id)
      exit run.exitstatus
    end

    private

    def aws_client_config
      {
        http_proxy: get_proxy,
        user_agent_suffix: "cfn-delete-stack-helper #{VERSION}",
      }
    end
     
    def get_proxy
      e = ENV['https_proxy']
      e = "https://#{e}" if e && !e.empty? && !e.start_with?('http')
      return e
    end

  end

  class Runner

    attr_reader :stack_name

    def initialize(aws_client_config, stack_name)
      @aws_client_config = aws_client_config
      @stack_name = stack_name
      @use_colour = $stdout.isatty

      require 'aws-sdk'
      cfn_client = Aws::CloudFormation::Client.new(aws_client_config)

      description = begin
                      cfn_client.describe_stacks(stack_name: stack_name)
                    rescue Aws::CloudFormation::Errors::ValidationError => e
                      # e.g. "Stack with id some-name does not exist"
                      $stderr.puts "ERROR: #{e.message}"
                      @exitstatus = 1
                      return
                    end

      if description.stacks.count > 1
        raise "Expected 0 or 1 stacks, found #{description.stacks.count}: #{description.inspect}"
      end

      description = description.stacks.first
      show_stack_header(description)

      resources = cfn_client.describe_stack_resources(stack_name: description.stack_id)
      resources = resources.stack_resources
      show_resource_list(resources)

      case description.stack_status
      when "DELETE_COMPLETE"
        puts "Stack is already deleted.  Nothing to do."
        @exitstatus = 0
        return
      when "ROLLBACK_COMPLETE"
        puts "Stack creation failed, but was successfully rolled back; stack deletion is the only way forward."
        puts ""
      when "ROLLBACK_FAILED", "DELETE_FAILED"
        puts "Stack is in #{description.stack_status} status; stack deletion is the only way forward."
        puts ""
      end

      ResourceInUseChecker.new(description, resources, aws_client_config, @use_colour).run

      # TODO, advise which resources cannot be re-created with the same IDs, if deleted

      unless prompted_proceed?
        @exitstatus = 0
        return
      end

      cfn_client.delete_stack(stack_name: description.stack_id)
      puts "Stack deletion requested"
      puts ""

      most_recent_event = cfn_client.describe_stack_events(stack_name: description.stack_id).data.stack_events.first
      @exitstatus = watch_stack_events description.stack_id, cfn_client, most_recent_event.timestamp
    end

    def watch_stack_events(stack_id, cfn_client, since)
      config = CfnEvents::Config.new
      config.cfn_client = cfn_client
      config.stack_name_or_id = stack_id
      config.wait = true
      config.since = since

      rc = CfnEvents::Runner.new(config).run
    end

    def show_stack_header(description)
      arn = description.stack_id
      region = arn.split(':')[3]
      account_id = arn.split(':')[4]
      account_alias = get_account_alias(account_id)

      puts <<EOF

Stack ARN:    #{arn}
Account:      #{account_id}#{account_alias ? " (#{account_alias})" : ""}
Region:       #{region}
Stack name:   #{description.stack_name}
Status:       #{description.stack_status}
Created:      #{description.creation_time}
Last updated: #{description.last_updated_time || "never"}

EOF
    end

    def show_resource_list(resources)
      header_row = {
        cells: [ "" ].concat(%w[ resource_type resource_status logical_resource_id physical_resource_id ]),
      }

      table = [ header_row ]

      table.concat(resources.map do |res|
        already_deleted = (%w[ DELETE_COMPLETE DELETE_SKIPPED ].include? res.resource_status)
        cells = [
          (already_deleted ? "" : "->"),
          res.resource_type,
          res.resource_status,
          res.logical_resource_id,
          res.physical_resource_id,
        ]
        colour = (already_deleted ? nil : :red)
        { cells: cells, colour: colour }
      end.to_a)

      puts HighlightingTextTable.new(use_colour: @use_colour).draw_table(table)
      puts ""
    end

    def get_account_alias(account_id)
      ans = Aws::IAM::Client.new(@aws_client_config).list_account_aliases
      ans.account_aliases.first
    end

    def prompted_proceed?
      puts "Are you sure you want to request deletion of any remaining resources, plus the stack itself?"
      puts ""
      print "Enter YES to proceed, anything else to abort: "
      answer = begin
                 $stdin.readline
               rescue EOFError
                 puts "(EOF on standard input)"
                 nil
               end
      unless answer and answer.chomp == "YES"
        puts "Aborted!"
        puts ""
        return false
      end

      puts ""
      true
    end

    def exitstatus
      @exitstatus
    end

  end

end
