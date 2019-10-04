# frozen_string_literal: true

module Micro
  module Case
    module Flow
      module ClassMethods
        def __flow__
          @__flow
        end

        def flow(*args)
          @__flow = flow_reducer.build(args)
        end

        def call(options = {})
          new(options).call
        end
      end

      CONSTRUCTOR = <<-RUBY
      def initialize(options)
        @options = options
        flow = self.class.__flow__
        raise Error::UndefinedFlow unless flow
      end
      RUBY

      private_constant :ClassMethods, :CONSTRUCTOR

      def self.included(base)
        def base.flow_reducer; Reducer; end
        base.extend(ClassMethods)
        base.class_eval(CONSTRUCTOR)
      end

      def self.[](*args)
        Reducer.build(args)
      end

      def call
        self.class.__flow__.call(@options)
      end

      module Safe
        def self.included(base)
          base.send(:include, Micro::Case::Flow)
          def base.flow_reducer; SafeReducer; end
        end

        def self.[](*args)
          SafeReducer.build(args)
        end
      end
    end
  end
end