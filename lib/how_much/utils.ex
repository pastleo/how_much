defmodule HowMuch.Utils do
  def unix_timestamp(date) do
    {:ok, datetime} = DateTime.new(date, ~T[00:00:00.000])
    DateTime.to_unix(datetime)
  end
end
