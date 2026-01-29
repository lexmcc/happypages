class Admin::ProgressController < Admin::BaseController
  def index
    @milestones = parse_history_file
    @key_milestones = parse_key_milestones
    @weeks = group_by_week(@milestones)
  end

  private

  def parse_history_file
    history_path = Rails.root.join("HISTORY.md")
    return [] unless File.exist?(history_path)

    content = File.read(history_path)
    milestones = []
    current_week = nil

    content.each_line do |line|
      # Match week headers like "### Week 1: Foundation (Jan 8-13, 2026)"
      if line =~ /^### (Week \d+: .+) \((.+)\)/
        current_week = { title: $1, dates: $2 }
      # Match milestone entries like "- **Jan 8** - Project inception..."
      elsif line =~ /^- \*\*(.+?)\*\* - (.+)$/
        milestones << {
          date: $1,
          description: $2.strip,
          week: current_week
        }
      end
    end

    milestones
  end

  def parse_key_milestones
    history_path = Rails.root.join("HISTORY.md")
    return [] unless File.exist?(history_path)

    content = File.read(history_path)
    key_milestones = []
    in_key_section = false

    content.each_line do |line|
      if line =~ /^## Key Milestones/
        in_key_section = true
      elsif in_key_section && line =~ /^## /
        break  # Next section started
      elsif in_key_section && line =~ /^\d+\. \*\*(.+?)\*\* - (.+?): (.+)$/
        key_milestones << {
          title: $1,
          date: $2,
          description: $3.strip
        }
      end
    end

    key_milestones
  end

  def group_by_week(milestones)
    milestones.group_by { |m| m[:week] }.compact
  end
end
