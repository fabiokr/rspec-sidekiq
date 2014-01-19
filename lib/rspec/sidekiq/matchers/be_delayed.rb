module RSpec
  module Sidekiq
    module Matchers
      def be_delayed *expected_arguments
        BeDelayed.new *expected_arguments
      end

      class BeDelayed
        def initialize *expected_arguments
          @expected_arguments = expected_arguments
        end

        def description
          description = "be delayed"
          description += " for #{@expected_interval} seconds" if @expected_interval
          description += " until #{@expected_time}" if @expected_time
          description += " with arguments #{@expected_arguments}" unless @expected_arguments.empty?
          description
        end

        def failure_message
          message = "expected #{@expected_method.receiver}.#{@expected_method.name} to be delayed"
          message += " for #{@expected_interval} seconds" if @expected_interval
          message += " until #{@expected_time}" if @expected_time
          message += " with arguments #{@expected_arguments}" unless @expected_arguments.empty?
          message
        end

        def for interval
          @expected_interval = interval
          self
        end

        def matches? expected_method
          @expected_method = expected_method

          job = (::Sidekiq::Extensions::DelayedClass.jobs + ::Sidekiq::Extensions::DelayedModel.jobs + ::Sidekiq::Extensions::DelayedMailer.jobs).find do |job|
            yaml = YAML.load(job["args"].first)
            @expected_method.receiver == yaml[0] && @expected_method.name == yaml[1] && (@expected_arguments <=> yaml[2]) == 0
          end

          if job
            if @expected_interval
              return job["at"].to_i == job["enqueued_at"].to_i + @expected_interval
            elsif @expected_time
              return job["at"].to_i == @expected_time.to_i
            else
              return true
            end
          else
            return false
          end
        end

        def negative_failure_message
          message = "expected #{@expected_method.receiver}.#{@expected_method.name} to not be delayed"
          message += " for #{@expected_interval} seconds" if @expected_interval
          message += " until #{@expected_time}" if @expected_time
          message += " with arguments #{@expected_arguments}" unless @expected_arguments.empty?
          message
        end

        def until time
          @expected_time = time
          self
        end
      end
    end
  end
end