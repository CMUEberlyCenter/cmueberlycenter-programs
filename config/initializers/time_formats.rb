Time::DATE_FORMATS[:short_date] = '%b %d, %Y'
Time::DATE_FORMATS[:time_stamp] = '%Y-%m-%d %H:%M%z'
Time::DATE_FORMATS[:date_stamp] = '%b %d, %Y'
Time::DATE_FORMATS[:ordinal] = lambda { |time| time.strftime("%b #{time.day.ordinalize}, %Y") }
