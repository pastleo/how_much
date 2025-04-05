import yfinance as yf

def fetch_tick_3mo(tick, start_date):
  dat = yf.Ticker(tick)

  df = dat.history(period='3mo', interval='1d', start=start_date)
  # print(df)

  # Extract dates and close prices
  dates = df.index.tolist()
  close_prices = df['Close'].tolist()

  # Convert dates to ISO8601 format strings in UTC timezone
  iso_dates = [date.tz_convert('UTC').strftime('%Y-%m-%d') for date in dates]

  # Create array of [date, close_price] tuples
  return list(zip(iso_dates, close_prices))
