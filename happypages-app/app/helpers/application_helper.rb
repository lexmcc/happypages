module ApplicationHelper
  def render_field(field, configs)
    # Convert field key to Stimulus target name (snake_case to camelCase)
    target_name = field[:key].gsub(/_([a-z])/) { $1.upcase }

    content_tag(:div) do
      label = content_tag(:label, field[:label],
        for: "configs_#{field[:key]}",
        class: "block text-sm font-medium text-gray-700 mb-1"
      )

      input = case field[:type]
      when :url
        tag.input(
          type: "url",
          name: "configs[#{field[:key]}]",
          id: "configs_#{field[:key]}",
          value: configs[field[:key]]&.config_value,
          class: "w-full px-4 py-2 bg-[#f9f9f9] border border-black/10 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#ff584d] focus:border-[#ff584d]",
          placeholder: "https://..."
        )
      when :text
        tag.input(
          type: "text",
          name: "configs[#{field[:key]}]",
          id: "configs_#{field[:key]}",
          value: configs[field[:key]]&.config_value,
          class: "w-full px-4 py-2 bg-[#f9f9f9] border border-black/10 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#ff584d] focus:border-[#ff584d]"
        )
      when :number
        tag.input(
          type: "number",
          name: "configs[#{field[:key]}]",
          id: "configs_#{field[:key]}",
          value: configs[field[:key]]&.config_value,
          class: "w-full px-4 py-2 bg-[#f9f9f9] border border-black/10 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#ff584d] focus:border-[#ff584d]",
          min: "0",
          step: "1",
          data: { preview_target: target_name, action: "input->preview#updatePreview" }
        )
      when :select
        current_value = configs[field[:key]]&.config_value || field[:options].first
        current_label = current_value.titleize

        # Custom dropdown component
        content_tag(:div, class: "relative", data: { controller: "dropdown", dropdown_open_value: "false" }) do
          # Hidden input for form submission
          hidden = tag.input(
            type: "hidden",
            name: "configs[#{field[:key]}]",
            id: "configs_#{field[:key]}",
            value: current_value,
            data: { dropdown_target: "hidden", preview_target: target_name, action: "change->preview#updatePreview" }
          )

          # Visible button
          chevron_svg = content_tag(:svg,
            content_tag(:path, nil, d: "M19 9l-7 7-7-7", stroke_linecap: "round", stroke_linejoin: "round"),
            xmlns: "http://www.w3.org/2000/svg",
            fill: "none",
            viewBox: "0 0 24 24",
            stroke: "currentColor",
            stroke_width: "2",
            class: "w-5 h-5 text-gray-500 transition-transform duration-200"
          )

          button = content_tag(:button,
            content_tag(:span, current_label, data: { dropdown_target: "selected" }) + chevron_svg,
            type: "button",
            data: { dropdown_target: "button", action: "click->dropdown#toggle" },
            class: "w-full pl-4 pr-4 py-2 bg-[#f9f9f9] border border-black/10 rounded-lg text-left focus:outline-none focus:ring-2 focus:ring-[#ff584d] focus:border-[#ff584d] cursor-pointer flex items-center justify-between"
          )

          # Dropdown menu
          menu_items = field[:options].map do |option|
            content_tag(:div,
              option.titleize,
              data: { action: "click->dropdown#select", value: option, label: option.titleize },
              class: "px-4 py-2 cursor-pointer transition-colors hover:bg-[#e8e8e4]"
            )
          end.join.html_safe

          menu = content_tag(:div,
            menu_items,
            data: { dropdown_target: "menu" },
            class: "hidden absolute z-20 mt-1 w-full bg-[#f4f4f0] border border-black/5 rounded-lg shadow-[inset_1px_1px_0_rgba(255,255,255,1),inset_-1px_-1px_0_rgba(0,0,0,0.05),0_4px_8px_rgba(0,0,0,0.1)] overflow-hidden"
          )

          safe_join([hidden, button, menu])
        end
      end

      hint = field[:hint] ? content_tag(:p, field[:hint], class: "mt-1 text-sm text-gray-500") : nil

      safe_join([label, input, hint].compact)
    end
  end
end
