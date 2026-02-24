module Specs
  class Orchestrator
    COMPRESSION_INTERVAL = 8
    TRADEOFF_SIGNALS = %w[tradeoff trade-off pros\ and\ cons compare which\ is\ better what\ are\ the\ options].freeze

    def initialize(session)
      @session = session
      @client = AnthropicClient.new
    end

    def process_turn(user_text, image: nil, user: nil, active_user: nil)
      ActiveRecord::Base.transaction do
        @session.lock!

        compress_if_needed
        update_phase
        prompt_context = active_user || build_active_user_context(user)
        system_prompt = Specs::PromptBuilder.new(@session, active_user: prompt_context).build
        model = select_model(user_text)
        tools = Specs::ToolDefinitions.v1
        api_messages = build_api_messages(user_text, image: image)

        response = @client.messages(
          system: system_prompt,
          messages: api_messages,
          model: model,
          tools: tools,
          max_tokens: model == AnthropicClient::OPUS ? 8192 : 4096
        )

        assistant_content = response["content"]
        usage = response["usage"] || {}

        # Store full assistant response in transcript
        @session.transcript << { "role" => "assistant", "content" => assistant_content }

        # Parse response blocks
        text_blocks = assistant_content.select { |b| b["type"] == "text" }
        tool_use_blocks = assistant_content.select { |b| b["type"] == "tool_use" }

        display_text = text_blocks.map { |b| b["text"] }.join("\n\n").presence
        next_turn = @session.turns_used + 1

        # Create user message record
        user_message = @session.messages.create!(
          role: "user",
          content: user_text,
          turn_number: next_turn,
          user: user
        )
        user_message.image.attach(image) if image

        # Create assistant message record
        first_tool = tool_use_blocks.first
        assistant_message = @session.messages.create!(
          role: "assistant",
          content: display_text,
          tool_calls: first_tool ? first_tool["input"] : nil,
          tool_name: first_tool ? first_tool["name"] : nil,
          turn_number: next_turn,
          model_used: model,
          input_tokens: usage["input_tokens"],
          output_tokens: usage["output_tokens"]
        )

        # Process tool_use blocks and auto-inject tool_results
        process_tool_results(tool_use_blocks, assistant_message)

        # Update session state
        @session.turns_used = next_turn
        @session.total_input_tokens += usage["input_tokens"].to_i
        @session.total_output_tokens += usage["output_tokens"].to_i

        # Auto-complete if both outputs are present
        if @session.client_brief.present? && @session.team_spec.present?
          @session.status = "completed"
        end

        @session.save!

        build_result(assistant_message, display_text, tool_use_blocks, model)
      end
    rescue AnthropicClient::MaxTokensError => e
      { error: "Response was too long. Please try a shorter message.", type: :max_tokens }
    rescue AnthropicClient::RefusalError => e
      { error: "The AI was unable to respond to that message. Please try rephrasing.", type: :refusal }
    end

    private

    def build_api_messages(user_text, image: nil)
      messages = @session.transcript.deep_dup

      # Build user content
      user_content = []

      # If the last assistant message had tool_use, format as tool_result
      last_assistant = messages.reverse.find { |m| m["role"] == "assistant" }
      if last_assistant
        tool_uses = Array(last_assistant["content"]).select { |b| b["type"] == "tool_use" }
        asking_tools = tool_uses.select { |b| b["name"].in?(%w[ask_question ask_freeform]) }

        if asking_tools.any?
          # User is answering a question — send as tool_result(s) first, then text
          asking_tools.each do |tool_use|
            user_content << { "type" => "tool_result", "tool_use_id" => tool_use["id"], "content" => user_text }
          end
        end
      end

      # Add image block if present
      if image
        blob = image.is_a?(ActiveStorage::Blob) ? image : image[:blob]
        if blob
          user_content << {
            "type" => "image",
            "source" => {
              "type" => "base64",
              "media_type" => blob.content_type,
              "data" => Base64.strict_encode64(blob.download)
            }
          }
        end
      end

      # Add text block (only if not already sent as tool_result, or always for context)
      if user_content.none? { |b| b["type"] == "tool_result" }
        user_content << { "type" => "text", "text" => user_text }
      end

      messages << { "role" => "user", "content" => user_content }
      messages
    end

    def process_tool_results(tool_use_blocks, assistant_message = nil)
      return if tool_use_blocks.empty?

      tool_results = []

      tool_use_blocks.each do |block|
        case block["name"]
        when "analyze_image"
          if assistant_message
            assistant_message.update_column(:image_data, block["input"]["analysis"])
          end
          tool_results << {
            "type" => "tool_result",
            "tool_use_id" => block["id"],
            "content" => "Image analysis recorded. #{block.dig("input", "summary")}"
          }
        when "generate_client_brief"
          @session.client_brief = block["input"]
          tool_results << { "type" => "tool_result", "tool_use_id" => block["id"], "content" => "Client brief generated successfully." }
        when "generate_team_spec"
          @session.team_spec = block["input"]
          tool_results << { "type" => "tool_result", "tool_use_id" => block["id"], "content" => "Team spec generated successfully." }
        when "request_handoff"
          input = block["input"]
          @session.handoffs.create!(
            from_user: @session.user,
            from_name: @session.user&.email || "System",
            reason: input["reason"],
            summary: input["summary"],
            suggested_questions: input["suggested_questions"] || [],
            suggested_role: input["suggested_role"],
            turn_number: @session.turns_used + 1
          )
          tool_results << {
            "type" => "tool_result",
            "tool_use_id" => block["id"],
            "content" => "Handoff request registered. The session owner will be notified to invite the next participant."
          }
        when "ask_question", "ask_freeform"
          # These wait for user input — no auto tool_result needed now.
          # The NEXT process_turn call handles the tool_result.
          return
        else
          tool_results << { "type" => "tool_result", "tool_use_id" => block["id"], "is_error" => true, "content" => "Unknown tool: #{block["name"]}" }
        end
      end

      # Append all tool_results as a single user message (tool_results first per API rules)
      if tool_results.any?
        @session.transcript << { "role" => "user", "content" => tool_results }
      end
    end

    def compress_if_needed
      return unless should_compress?

      turns_text = @session.transcript.map { |m|
        content = m["content"]
        if content.is_a?(Array)
          content.filter_map { |b| b["text"] if b["type"] == "text" }.join("\n")
        else
          content.to_s
        end
      }.join("\n\n---\n\n")

      prompt = Specs::PromptBuilder::COMPRESSION_PROMPT % { turns_to_compress: turns_text }

      response = @client.messages(
        system: [{ type: "text", text: "You are a conversation summarizer." }],
        messages: [{ "role" => "user", "content" => prompt }],
        model: AnthropicClient::HAIKU,
        max_tokens: 2048
      )

      summary_text = response["content"]&.find { |b| b["type"] == "text" }&.dig("text")
      if summary_text.present?
        @session.compressed_context = summary_text
        # Keep only the last 4 messages in transcript
        @session.transcript = @session.transcript.last(4)
      end
    end

    def should_compress?
      @session.turns_used > 0 && @session.turns_used % COMPRESSION_INTERVAL == 0
    end

    def update_phase
      pct = @session.budget_percentage
      new_phase = if pct <= 0.5
        "explore"
      elsif pct <= 0.7
        "narrow"
      elsif pct <= 0.85
        "converge"
      else
        "generate"
      end

      # Phase can only advance, never regress
      phases = Specs::Session::PHASES
      current_idx = phases.index(@session.phase) || 0
      new_idx = phases.index(new_phase) || 0
      @session.phase = phases[[current_idx, new_idx].max]
    end

    def build_active_user_context(user)
      return nil unless user || @session.active_handoff

      if (handoff = @session.active_handoff)
        {
          name: handoff.to_name || user&.email,
          role: handoff.to_role || user&.role,
          handoff_context: "This session was handed off from #{handoff.from_name} at turn #{handoff.turn_number}. Their summary:\n\"#{handoff.summary}\"\n\nSuggested questions for you:\n#{handoff.suggested_questions.map { |q| "- #{q}" }.join("\n")}"
        }
      elsif user
        { name: user.email, role: user.role }
      end
    end

    def select_model(user_text)
      return AnthropicClient::OPUS if @session.phase == "generate"
      return AnthropicClient::OPUS if user_text.length > 500 && user_text.count("?") >= 2

      lower = user_text.downcase
      return AnthropicClient::OPUS if TRADEOFF_SIGNALS.any? { |s| lower.include?(s) }

      AnthropicClient::SONNET
    end

    def build_result(assistant_message, display_text, tool_use_blocks, model)
      first_tool = tool_use_blocks.first
      {
        message_id: assistant_message.id,
        content: display_text,
        tool_name: first_tool&.dig("name"),
        tool_input: first_tool&.dig("input"),
        turn_number: assistant_message.turn_number,
        model_used: model,
        phase: @session.phase,
        turns_used: @session.turns_used,
        turn_budget: @session.turn_budget,
        status: @session.status,
        client_brief: @session.client_brief,
        team_spec: @session.team_spec,
        handoff_requested: @session.handoffs.where(turn_number: assistant_message.turn_number).exists?
      }
    end
  end
end
