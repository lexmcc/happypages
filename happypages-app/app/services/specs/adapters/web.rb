module Specs
  module Adapters
    class Web < Base
      def initialize(session, strip_team_spec: false)
        super(session)
        @strip_team_spec = strip_team_spec
      end

      def format_result(result)
        return result unless @strip_team_spec
        result = result.dup
        result.delete(:team_spec)
        result
      end
    end
  end
end
