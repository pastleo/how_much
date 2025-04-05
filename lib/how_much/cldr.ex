defmodule HowMuch.Cldr do
  use Cldr,
    locales: ["en", "zh"],
    default_locale: "en",
    providers: [Cldr.Number, Money]
end
