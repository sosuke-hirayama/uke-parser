# -*- encoding: utf-8 -*-

require 'jma/receview/generation'

module DayConv
  # 月末の日時を取得  year = year+month
  def month2endday(year=Date.today.year.to_s + Date.today.month.to_s)
    time = ""
    if /([0-9]{4})([0-9]{2})/ =~ year
      sp_year = $1.to_i
      sp_month = $2.to_i
      time = Date.new(sp_year, sp_month, -1).day
    end
    return time
  end
  module_function :month2endday
end


