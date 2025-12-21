defmodule HowMuch.Explorer.DataFrame do
  require Explorer.DataFrame
  alias Explorer.DataFrame, as: DF

  def summarize(assets_value_data_frame, by_field) do
    each_assets_value_data_frame =
      DF.lazy(assets_value_data_frame)
      |> DF.group_by([by_field, "date"])
      |> DF.summarise(value: sum(value))
      |> DF.collect()
      |> DF.pivot_wider(by_field, "value")

    aggregated_data_frame =
      DF.lazy(assets_value_data_frame)
      |> DF.group_by("date")
      |> DF.summarise(value: sum(value), has_record: any?(has_record))
      |> DF.collect()

    DF.join(
      aggregated_data_frame,
      each_assets_value_data_frame,
      on: ["date"],
      how: :left
    )
    |> DF.sort_by(desc: date)
  end

  def filter_summarized_has_record(summarized_data_frame) do
    DF.filter(summarized_data_frame, has_record == true)
    |> DF.discard("has_record")
  end

  def current(assets_value_data_frame, by_field) do
    DF.filter(assets_value_data_frame, date > HowMuch.Utils.yesterday() and value > 0)
    |> DF.select([by_field, "date", "value"])
  end
end
