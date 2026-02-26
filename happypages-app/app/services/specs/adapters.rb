module Specs
  module Adapters
    REGISTRY = { "web" => Web, "slack" => Specs::Adapters::Slack }.freeze

    def self.for(session, **options)
      klass = REGISTRY[session.channel_type] || Web
      klass.new(session, **options)
    end
  end
end
