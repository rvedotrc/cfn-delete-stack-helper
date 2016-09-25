module CfnDeleteStackHelper

  class HighlightingTextTable

    def initialize(opts = {})
      @use_colour = opts[:use_colour]
    end

    def draw_table(rows)
      return "" if rows.empty?
      column_count = rows.first[:cells].count

      max_widths_by_column = column_count.times.map do |n|
        rows.map {|row| row[:cells][n].to_s.length}.max
      end

      format_string = max_widths_by_column.map {|w| "%-#{w}s"}.join("  ")

      rows.map {|row|
        text = format_string % row[:cells]
        text.sub!(/ *$/, "")

        if row[:colour] and @use_colour
          require 'colored'
          text = text.send(row[:colour])
        end

        text + "\n"
      }.join ""
    end

  end

end
