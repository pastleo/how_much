defmodule HowMuch.VegaLite do
  alias VegaLite, as: Vl

  @color_list [
    "#D9ED92",
    "#B5E48C",
    "#99D98C",
    "#76C893",
    "#52B69A",
    "#34A0A4",
    "#168AAD",
    "#1A759F",
    "#1E6091",
    "#184E77"
  ]

  def color_list, do: @color_list

  def summarized_bar_chart(summarized_data_frame, by_field, title) do
    Vl.new(width: 600, height: 600, title: title)
    |> Vl.data_from_values(summarized_data_frame,
      only: ["date", "value", by_field]
    )
    |> Vl.mark(:bar, tooltip: true)
    |> Vl.encode_field(:x, "date", type: :temporal)
    |> Vl.encode_field(:y, "value", type: :quantitative)
    |> Vl.encode_field(:color, by_field, type: :nominal, scale: [range: @color_list])
  end

  def summarized_recorded_bar_line_chart(summarized_data_frame, recorded_data_frame, by_field, title) do
    Vl.new(width: 600, height: 600, title: title)
    |> Vl.layers([
      Vl.new()
      |> Vl.data_from_values(summarized_data_frame,
        only: ["date", "value", by_field]
      )
      |> Vl.mark(:bar, tooltip: true)
      |> Vl.encode_field(:x, "date", type: :temporal)
      |> Vl.encode_field(:y, "value", type: :quantitative)
      |> Vl.encode_field(:color, by_field, type: :nominal, scale: [range: @color_list]),

      Vl.new()
      |> Vl.data_from_values(recorded_data_frame,
        only: ["date", "value", by_field]
      )
      |> Vl.mark(:line, tooltip: true)
      |> Vl.encode_field(:x, "date", type: :temporal)
      |> Vl.encode_field(:y, "value", type: :quantitative)
    ])
  end

  def current_pie_chart(current_data_frame, name_field, title) do
    Vl.new(width: 400, height: 400, title: title)
    |> Vl.data_from_values(current_data_frame)
    |> Vl.mark(:arc, tooltip: true)
    |> Vl.encode_field(:theta, "value", type: :quantitative)
    |> Vl.encode_field(:color, name_field, type: :nominal, scale: [range: @color_list])
    |> Vl.config(view: [stroke: nil])
  end
end
