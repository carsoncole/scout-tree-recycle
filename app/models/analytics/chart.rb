class Analytics
  # Rounded bar chart geometry for one analytics series. The view draws the
  # SVG from these measurements so the page stays free of plotting math.
  class Chart
    HEIGHT = 248
    INTERVALS = 4

    Bar = Data.define(:x, :y, :width, :height, :label, :value_label)
    Column = Data.define(:x, :width, :label, :value_label)
    Tick = Data.define(:y, :label)
    XLabel = Data.define(:x, :text)

    def initialize(points, scale:)
      @points = points
      @scale = scale
    end

    def width
      @width ||= begin
        span = @points.empty? ? 220 : [ [ @points.size * 48, 220 ].max, 560 ].min
        (left_gutter + span + 12).ceil
      end
    end

    def height
      HEIGHT
    end

    def plot_left
      left_gutter
    end

    def plot_right
      width - 12
    end

    def plot_bottom
      HEIGHT - 36
    end

    def bars
      @bars ||= build_bars
    end

    def columns
      @columns ||= build_columns
    end

    def y_ticks
      @y_ticks ||= y_tick_values.map { |value| Tick.new(y: y_for(value), label: format_tick(value)) }
    end

    def x_labels
      @x_labels ||= choose_x_labels
    end

    def path_for(bar)
      return if bar.height <= 0

      radius = [ 4.0, bar.width / 2.0, bar.height ].min
      x = bar.x
      y = bar.y
      w = bar.width
      h = bar.height
      bottom = y + h

      "M #{n(x)} #{n(y + radius)} Q #{n(x)} #{n(y)} #{n(x + radius)} #{n(y)} " \
        "H #{n(x + w - radius)} Q #{n(x + w)} #{n(y)} #{n(x + w)} #{n(y + radius)} " \
        "V #{n(bottom)} H #{n(x)} Z"
    end

    private

    def build_bars
      return [] if @points.empty?

      @points.each_with_index.map do |point, index|
        height = (point.value.to_f / nice_max) * plot_height
        x = plot_left + (index * slot) + ((slot - bar_width) / 2.0)
        Bar.new(
          x: x,
          y: plot_bottom - height,
          width: bar_width,
          height: height,
          label: point.label,
          value_label: point.value_label
        )
      end
    end

    def build_columns
      return [] if @points.empty?

      @points.each_with_index.map do |point, index|
        Column.new(
          x: plot_left + (index * slot),
          width: slot,
          label: point.label,
          value_label: point.value_label
        )
      end
    end

    def choose_x_labels
      return [] if bars.empty?

      chosen = [ bars.first ]
      bars.drop(1).each do |bar|
        chosen << bar if bar.x - chosen.last.x >= 72
      end

      last = bars.last
      unless chosen.last.equal?(last)
        if last.x - chosen.last.x >= 72
          chosen << last
        elsif chosen.size > 1
          chosen[-1] = last
        end
      end

      chosen.map { |bar| XLabel.new(x: bar.x + (bar.width / 2.0), text: axis_text(bar.label)) }
    end

    def axis_text(label)
      label.delete_prefix("Week of ")
    end

    def y_tick_values
      @y_tick_values ||= INTERVALS.downto(0).map { |step| nice_max * step / INTERVALS }
    end

    def nice_max
      @nice_max ||= begin
        raw = @points.map { |point| point.value.to_f }.max.to_f
        if raw <= 0
          4.0
        else
          rough = raw / INTERVALS
          magnitude = 10**Math.log10(rough).floor
          residual = rough / magnitude
          step = [ 1, 2, 2.5, 5, 10 ].find { |candidate| candidate + 1e-9 >= residual }
          interval = step * magnitude
          interval = [ interval.ceil, 1 ].max if @scale == :count
          interval += 1 while @scale == :count && (interval * INTERVALS) < raw
          (interval * INTERVALS).to_f
        end
      end
    end

    def y_for(value)
      plot_top + plot_height - ((value / nice_max) * plot_height)
    end

    def plot_top
      16
    end

    def plot_height
      plot_bottom - plot_top
    end

    def plot_width
      plot_right - plot_left
    end

    def slot
      plot_width / @points.size
    end

    def bar_width
      [ [ slot * 0.62, 22 ].min, 3 ].max
    end

    def left_gutter
      @left_gutter ||= begin
        longest = y_tick_values.map { |value| format_tick(value).length }.max || 1
        [ (longest * 7.4) + 18, 44 ].max
      end
    end

    def format_tick(value)
      if @scale == :count
        ActiveSupport::NumberHelper.number_to_delimited(value.round)
      else
        precision = (value - value.round).abs < 0.001 ? 0 : 2
        ActiveSupport::NumberHelper.number_to_currency(value, precision: precision)
      end
    end

    def n(value)
      format("%.2f", value)
    end
  end
end
