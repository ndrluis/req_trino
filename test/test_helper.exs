Calendar.put_time_zone_database(Tzdata.TimeZoneDatabase)
ExUnit.start(exclude: [:integration])

defmodule TableHelpers do
  def random_identifier(prefix) do
    "#{prefix}_#{:rand.uniform(1000)}"
  end
end
