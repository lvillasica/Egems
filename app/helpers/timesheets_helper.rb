module TimesheetsHelper

  def format_date(date)
    date.localtime.strftime("%Y-%m-%d")
  end

  def format_time(time)
    time ? time.localtime.strftime("%I:%M:%S %p %Y-%m-%d") : "--:--"
  end
end
