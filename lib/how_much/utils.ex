defmodule HowMuch.Utils do
  def unix_timestamp(date) do
    {:ok, datetime} = DateTime.new(date, ~T[00:00:00.000], "Etc/UTC")
    DateTime.to_unix(datetime)
  end

  def unix_timestamp_to_date(timestamp) do
    DateTime.from_unix!(timestamp)
    |> DateTime.to_date()
  end

  def yesterday() do
    Date.utc_today() |> Date.add(-1)
  end
end
