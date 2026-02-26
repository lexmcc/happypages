module Specs
  module Adapters
    class Slack < Base
      def format_result(result)
        if result[:error]
          return {
            blocks: SlackRenderer.render_error(result[:error]),
            text: result[:error],
            status: nil, client_brief: nil, team_spec: nil
          }
        end

        blocks = []
        blocks += SlackRenderer.render_text(result[:content]) if result[:content].present?
        blocks += SlackRenderer.render_tool_output(result[:tool_name], result[:tool_input], session.id) if result[:tool_name]

        if result[:status] == "completed"
          blocks += SlackRenderer.render_completion(result)
        end

        {
          blocks: blocks,
          text: result[:content] || "New message from Speccy",
          status: result[:status],
          client_brief: result[:client_brief],
          team_spec: nil
        }
      end
    end
  end
end
