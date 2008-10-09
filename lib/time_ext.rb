class Time
  def self.parse_utc(date, now=Time.now)
    d = Date._parse(date, false)
    year = d[:year]
    year = yield(year) if year && block_given?
    make_time(year, d[:mon], d[:mday], d[:hour], d[:min], d[:sec], d[:sec_fraction], d[:zone] || 'UTC', now)
  end
end