module Specs
  module Adapters
    class Base
      attr_reader :session

      def initialize(session, **_options)
        @session = session
      end

      def process_message(text, image: nil, **kwargs)
        Specs::Orchestrator.new(session).process_turn(text, image: image, **kwargs)
      end

      def format_result(result)
        result
      end
    end
  end
end
