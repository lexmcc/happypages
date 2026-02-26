module Specs
  class SlackRenderer
    class << self
      def render_text(content)
        return [] if content.blank?
        [{ type: "section", text: { type: "mrkdwn", text: content } }]
      end

      def render_tool_output(tool_name, tool_input, session_id)
        return [] unless tool_name && tool_input

        case tool_name
        when "ask_question"
          render_question(tool_input, session_id)
        when "ask_freeform"
          render_freeform(tool_input)
        when "generate_client_brief"
          render_brief_summary(tool_input)
        when "analyze_image"
          render_text("Image analysis complete.")
        else
          []
        end
      end

      def render_question(input, session_id)
        blocks = []

        question_text = input["question"]
        question_text = "#{input["context"]}\n\n#{question_text}" if input["context"].present?

        blocks << { type: "section", text: { type: "mrkdwn", text: question_text } }

        options = input["options"] || []
        elements = options.each_with_index.map do |option, index|
          {
            type: "button",
            text: { type: "plain_text", text: option["label"], emoji: true },
            action_id: "speccy_option_#{session_id}_#{index}",
            value: option["label"]
          }
        end

        blocks << { type: "actions", elements: elements } if elements.any?
        blocks
      end

      def render_freeform(input)
        blocks = []

        question_text = input["question"]
        question_text = "#{input["context"]}\n\n#{question_text}" if input["context"].present?

        blocks << { type: "section", text: { type: "mrkdwn", text: question_text } }
        blocks << { type: "context", elements: [{ type: "mrkdwn", text: "Type your answer in this thread" }] }
        blocks
      end

      def render_brief_summary(brief)
        blocks = []
        blocks << { type: "section", text: { type: "mrkdwn", text: "*#{brief["title"]}*" } } if brief["title"]
        blocks << { type: "section", text: { type: "mrkdwn", text: "_#{brief["goal"]}_" } } if brief["goal"]

        (brief["sections"] || []).each do |section|
          blocks << { type: "section", text: { type: "mrkdwn", text: "*#{section["heading"]}*\n#{section["content"]}" } }
        end

        blocks
      end

      def render_completion(result)
        blocks = [{ type: "divider" }]
        summary = "Spec interview complete!"
        summary += " View the full specification in the web portal." if result[:client_brief].present?
        blocks << { type: "section", text: { type: "mrkdwn", text: summary } }
        blocks
      end

      def render_error(error_text)
        [{ type: "section", text: { type: "mrkdwn", text: ":warning: #{error_text}" } }]
      end

      def render_selected_option(label)
        [{ type: "section", text: { type: "mrkdwn", text: "Selected: *#{label}*" } }]
      end
    end
  end
end
