module Specs
  class ToolDefinitions
    def self.v1
      [
        {
          name: "ask_question",
          description: "Ask the user a structured question with predefined options. Use for most interview questions.",
          input_schema: {
            type: "object",
            required: ["question", "options"],
            properties: {
              question: {
                type: "string",
                description: "The question to ask. Should be clear, specific, and end with a question mark."
              },
              options: {
                type: "array",
                items: {
                  type: "object",
                  required: ["label", "description"],
                  properties: {
                    label: {
                      type: "string",
                      description: "Short option label (1-5 words)."
                    },
                    description: {
                      type: "string",
                      description: "Brief explanation of what this option means or implies."
                    }
                  }
                },
                minItems: 2,
                maxItems: 4
              },
              allow_freeform: {
                type: "boolean",
                description: "Whether the user can type a custom answer instead of picking an option. Default: true.",
                default: true
              },
              context: {
                type: "string",
                description: "Optional brief context shown before the question, acknowledging what you already know. Keep to 1-2 sentences."
              }
            }
          }
        },
        {
          name: "ask_freeform",
          description: "Ask an open-ended question with no predefined options. Use sparingly — only when the answer space is genuinely open and can't be narrowed to useful options.",
          input_schema: {
            type: "object",
            required: ["question"],
            properties: {
              question: {
                type: "string",
                description: "The open-ended question to ask."
              },
              context: {
                type: "string",
                description: "Optional brief context shown before the question. Keep to 1-2 sentences."
              },
              hint: {
                type: "string",
                description: "Placeholder text in the input field to guide the user's response format or length."
              }
            }
          }
        },
        {
          name: "analyze_image",
          description: "Analyse an uploaded image (screenshot, mockup, design reference). Extract colors, typography, layout patterns, spacing, and visual effects. Call this whenever the user uploads an image.",
          input_schema: {
            type: "object",
            required: ["analysis"],
            properties: {
              analysis: {
                type: "object",
                required: ["colors", "typography", "layout"],
                properties: {
                  colors: {
                    type: "array",
                    items: {
                      type: "object",
                      required: ["hex", "role"],
                      properties: {
                        hex: { type: "string", description: "Hex color value (e.g. #ff584d)." },
                        role: {
                          type: "string",
                          enum: %w[primary secondary background surface accent text text-muted border error success],
                          description: "Semantic role of this color."
                        },
                        name: { type: "string", description: "Optional human-readable name (e.g. 'Coral')." }
                      }
                    },
                    description: "Colors extracted from the image, each with a hex value and semantic role."
                  },
                  typography: {
                    type: "array",
                    items: {
                      type: "object",
                      required: ["element", "family"],
                      properties: {
                        element: { type: "string", description: "HTML element or role (e.g. h1, body, caption)." },
                        family: { type: "string", description: "Best guess at the font family." },
                        size: { type: "string", description: "Estimated font size (e.g. '32px')." },
                        weight: { type: "string", description: "Font weight (e.g. '700', 'bold')." }
                      }
                    },
                    description: "Typography styles observed in the image."
                  },
                  layout: {
                    type: "object",
                    properties: {
                      type: { type: "string", description: "Primary layout model (e.g. flex, grid, stack)." },
                      direction: { type: "string", description: "Flow direction (e.g. column, row)." },
                      alignment: { type: "string", description: "Alignment pattern (e.g. center, start)." },
                      responsive_hints: { type: "string", description: "Notes on likely responsive behaviour." }
                    },
                    description: "Layout patterns observed in the image."
                  },
                  spacing: {
                    type: "object",
                    properties: {
                      base_unit: { type: "string", description: "Detected base spacing unit (e.g. '8px')." },
                      notable: {
                        type: "array",
                        items: { type: "string" },
                        description: "Notable spacing values observed."
                      }
                    },
                    description: "Spacing patterns mapped to a 4px/8px scale."
                  },
                  effects: {
                    type: "array",
                    items: {
                      type: "object",
                      properties: {
                        type: { type: "string", description: "Effect type (e.g. shadow, border, radius, gradient)." },
                        where: { type: "string", description: "Where this effect appears." },
                        value: { type: "string", description: "CSS-like value for the effect." }
                      }
                    },
                    description: "Visual effects like shadows, borders, border-radius, gradients."
                  },
                  states_visible: {
                    type: "array",
                    items: { type: "string" },
                    description: "UI states visible in the image (e.g. hover, focus, disabled, active)."
                  }
                }
              },
              summary: {
                type: "string",
                description: "One-sentence summary of what the image shows and key design observations."
              }
            }
          }
        },
        {
          name: "generate_client_brief",
          description: "Generate the client-facing specification document. Plain language, focused on goals and outcomes. Called during the GENERATE phase.",
          input_schema: {
            type: "object",
            required: ["title", "goal", "sections"],
            properties: {
              title: {
                type: "string",
                description: "Project/feature name."
              },
              goal: {
                type: "string",
                description: "One sentence: what we're building and why, in plain language."
              },
              sections: {
                type: "array",
                items: {
                  type: "object",
                  required: ["heading", "content"],
                  properties: {
                    heading: { type: "string" },
                    content: { type: "string", description: "Markdown content for this section." }
                  }
                },
                description: "Ordered sections of the brief. Typical sections: Background, What We're Building, How It Works (user perspective), What You'll See, Timeline/Phases, What We Need From You."
              },
              visual_references: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    image_id: { type: "string", description: "Reference to an uploaded image." },
                    caption: { type: "string" },
                    section: { type: "string", description: "Which section this image relates to." }
                  }
                }
              }
            }
          }
        },
        {
          name: "generate_team_spec",
          description: "Generate the team-facing technical specification. Includes chunks, acceptance criteria, technical notes. Called during the GENERATE phase.",
          input_schema: {
            type: "object",
            required: ["title", "goal", "approach", "chunks"],
            properties: {
              title: { type: "string" },
              goal: {
                type: "string",
                description: "One sentence: what we're building and why."
              },
              approach: {
                type: "string",
                description: "The chosen solution direction with brief rationale."
              },
              chunks: {
                type: "array",
                items: {
                  type: "object",
                  required: ["title", "description", "acceptance_criteria"],
                  properties: {
                    title: { type: "string" },
                    description: { type: "string", description: "What this chunk delivers. Should be detailed enough to start work without questions." },
                    acceptance_criteria: {
                      type: "array",
                      items: { type: "string" },
                      description: "Testable criteria. 'Given X, when Y, then Z' format preferred."
                    },
                    dependencies: {
                      type: "array",
                      items: { type: "string" },
                      description: "Other chunk titles this depends on."
                    },
                    has_ui: {
                      type: "boolean",
                      description: "Whether this chunk involves frontend/UI work."
                    }
                  }
                }
              },
              tech_notes: {
                type: "array",
                items: { type: "string" },
                description: "Implementation details, constraints, gotchas discussed during the interview."
              },
              design_tokens: {
                type: "object",
                description: "Only present if screenshots were analysed. Contains extracted colors, typography, spacing.",
                properties: {
                  colors: { type: "object" },
                  typography: { type: "object" },
                  spacing: { type: "object" },
                  effects: { type: "object" }
                }
              },
              open_questions: {
                type: "array",
                items: { type: "string" },
                description: "Anything unresolved from the interview."
              }
            }
          }
        },
        {
          name: "request_handoff",
          description: "Request that the session be handed off to another user. Call when the current user can't answer key questions and someone else on the project could.",
          input_schema: {
            type: "object",
            required: %w[reason summary suggested_questions],
            properties: {
              reason: { type: "string", description: "Why a handoff is needed." },
              summary: { type: "string", description: "Complete summary of everything covered so far." },
              suggested_questions: {
                type: "array",
                items: { type: "string" },
                description: "Specific questions the next person should answer."
              },
              suggested_role: {
                type: "string",
                description: "What kind of person should take over. e.g., 'designer', 'developer', 'business owner'."
              }
            }
          }
        }
      ]
    end
  end
end
