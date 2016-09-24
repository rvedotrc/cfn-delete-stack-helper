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
      puts stack_header(description)

      resources = cfn_client.describe_stack_resources(stack_name: description.stack_id)
      resources = resources.stack_resources

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

      puts draw_table(table)
      puts ""

      case description.stack_status
      when "DELETE_COMPLETE"
        puts "Stack is already deleted.  Nothing to do."
        return
      when "ROLLBACK_COMPLETE"
        puts "Stack creation failed, but was rolled back.  Nothing to do."
        return
      when "ROLLBACK_FAILED", "DELETE_FAILED"
        puts "WARNING: Stack rollback/deletion failed; stack deletion is the only way forward."
      end

      # TODO, try and predict if any resource deletions (of resources that are
      # not already deleted) will fail

      # TODO, advise which resources cannot be re-created with the same IDs, if deleted

      puts "Are you sure you want to request deletion of any remaining resources, plus the stack itself?"
      puts ""
      print "Enter YES to proceed, anything else to abort: "
      answer = $stdin.readline
      unless answer and answer.chomp == "YES"
        puts "Aborted!"
        puts ""
        @exitstatus = 0
        return
      end
      puts ""

      cfn_client.delete_stack(stack_name: description.stack_id)
      puts "Stack deletion requested"
      puts ""

      most_recent_event = cfn_client.describe_stack_events(stack_name: description.stack_id).data.stack_events.first
      since = most_recent_event.timestamp.to_s
      system "cfn-events", "--since", since, "-w", description.stack_id

      @exitstatus = $?.exitstatus
    end

    def stack_header(description)
      arn = description.stack_id
      region = arn.split(':')[3]
      account_id = arn.split(':')[4]
      account_alias = get_account_alias(account_id)

      <<EOF

Stack ARN:    #{arn}
Account:      #{account_id}#{account_alias ? " (#{account_alias})" : ""}
Region:       #{region}
Stack name:   #{description.stack_name}
Status:       #{description.stack_status}
Created:      #{description.creation_time}
Last updated: #{description.last_updated_time || "never"}

EOF
    end

    def get_account_alias(account_id)
      ans = Aws::IAM::Client.new(@aws_client_config).list_account_aliases
      ans.account_aliases.first
    end

    def exitstatus
      @exitstatus
    end

    def draw_table(rows)
      return "" if rows.empty?
      column_count = rows.first[:cells].count

      max_widths_by_column = column_count.times.map do |n|
        rows.map {|row| row[:cells][n].to_s.length}.max
      end

      format_string = max_widths_by_column.map {|w| "%-#{w}s"}.join("  ")

      rows.map {|row|
        text = format_string % row[:cells]
        text.sub!(/ *$/, "")

        if row[:colour] and @use_colour
          require 'colored'
          text = text.send(row[:colour])
        end

        text
      }
    end

  end

end
