# -*- encoding: utf-8 -*-

require 'jma/receview/generation'

module YearConv
  # 和暦と西暦より年齢出力 7桁
  # wa2toshi("3041122", "2004,11,16")
  def wa2toshi(bday, now_day)
    age = ""
    toshi = ["-", "1867", "1911", "1925", "1988"]
    now_data = now_day.to_s.split(/-/) 
    barr = bday.to_s.split(//) 

    if !barr.empty?
      # 1月〜12月 誕生日
      bas_value = (barr[3]+barr[4]).to_i

      # 1月〜12月 現在の日付
      now_value = now_data[1].to_i

      # 西暦
      wa_toshi = toshi[barr[0].to_i].to_i + (barr[1] + barr[2]).to_i

      if now_value.to_i < bas_value.to_i
        # 誕生月の前
        age = (now_data[0].to_i - wa_toshi - 1).to_s
      elsif now_value.to_i == bas_value.to_i
        # 誕生月である
        age = "*" + (now_data[0].to_i - wa_toshi).to_s
      else
        # 誕生月の後
        age = (now_data[0].to_i - wa_toshi).to_s
      end
    end
    return age.to_s
  end

  # 請求年月,診療年月 5桁日付データ
  # 診療 S50.10
  def date_make(data, rosai=false)
    if not data.to_s.empty?
      # 年レコード
      if rosai
        toshi = ["-", "M", "-", "T", "-", "S", "-",  "H"]
      else
        toshi = ["-", "M", "T", "S", "H"]
      end

      temp = []
      temp = data.to_s.split(//) 
      age_out = toshi[temp[0].to_i].to_s + temp[1].to_s + temp[2].to_s \
                    + "." + temp[3].to_s + temp[4].to_s
    else
      age_out = ""
    end
    return age_out.to_s
  end

  # option=nil "平成20年3月1日" -> "20年 3月 1日"
  # option=sr "4210910" -> " 21年  9月 10日"
  # option=br "4210910" -> "　２１年　　９月　１０日"
  # option=wa "4210910" -> "平成 21年 9月 10日"
  # option=rosai2wa "7210910" -> "平成 21年 9月 10日生"
  def wadate6make(str, option=nil)
    toshi = ["-", "明治", "大正", "昭和", "平成"]
    rosai_toshi = {
      "1" => "明治",
      "3" => "対象",
      "5" => "昭和",
      "7" => "平成",
    }
    if option == "sr" or option == "br" or option == "wa" or option == "rosai2wa"
      year_tmp = str.to_s.split(//)
      year_tmp[1] = " " if year_tmp[1].to_s == "0"
      year_tmp[3] = " " if year_tmp[3].to_s == "0"
      year_tmp[5] = " " if year_tmp[5].to_s == "0"
      year  = year_tmp[1].to_s
      year += year_tmp[2].to_s
      mon   = year_tmp[3].to_s
      mon  += year_tmp[4].to_s
      day   = year_tmp[5].to_s
      day  += year_tmp[6].to_s
      
      year = word2kotei2(year, 3)
      mon  = word2kotei2(mon, 3)
      day  = word2kotei2(day, 3)
      if option == "br"
        return_str = sw2bw("#{year}年#{mon}月#{day}日")
      elsif option == "wa"
        wareki = toshi[year_tmp[0].to_i].to_s
        return_str = "#{wareki}#{year}年#{mon}月#{day}日"
      elsif option == "rosai2wa"
        wareki = rosai_toshi[year_tmp[0].to_s].to_s
        return_str = "#{wareki}#{year}年#{mon}月#{day}日生"
      else
        return_str = "#{year}年#{mon}月#{day}日"
      end
    else
      toshi.each do |wa|
        str = str.sub(/#{wa}/, "")
      end
      year_y = str.split(/年/)
      year   = year_y[0].to_s
      year_m = year_y[1].to_s.split(/月/)
      mon    = year_m[0].to_s
      day    = year_m[1].to_s.split(/日/)[0].to_s
      
      year = word2kotei2(year, 2)
      mon  = word2kotei2(mon, 2)
      day  = word2kotei2(day, 2)
      return_str = "#{year}年#{mon}月#{day}日"
    end
    return return_str
  end

  # 請求年月,診療年月 5桁日付データ
  def data7make(data, option=nil)
    # 年レコード
    toshi = ["-", "明治", "大正", "昭和", "平成"]
    toshi_rece = ["-", "明", "大", "昭", "平"]
    toshi_rosai = ["-", "1", "3", "5", "7"]

    out_date = ""
    temp = []
    temp = data.to_s.split(//) 

    case option
    when "rece"
      temp[5] = " " if temp[5] == "0"
      temp[3] = " " if temp[3] == "0"
      temp[1] = " " if temp[1] == "0"
      year_i = sw2bw(temp[0].to_s).to_s
      year_s = toshi_rece[temp[0].to_i].to_s
      year_y = sw2bw(temp[1].to_s + temp[2].to_s).to_s + "．"
      mon = sw2bw(temp[3].to_s + temp[4].to_s).to_s + "．"
      day = sw2bw(temp[5].to_s + temp[6].to_s).to_s
      out_date = "　" + year_i + year_s + year_y + mon + day
    when "rosai_rece"
      temp[5] = " " if temp[5] == "0"
      temp[3] = " " if temp[3] == "0"
      temp[1] = " " if temp[1] == "0"
      year_s = toshi_rosai[temp[0].to_i].to_s
      year_y = temp[1].to_s + temp[2].to_s
      mon = temp[3].to_s + temp[4].to_s
      day = temp[5].to_s + temp[6].to_s
      out_date = year_s + year_y + mon + day
    when "rosai_rece_nogen"
      temp[5] = " " if temp[5] == "0"
      temp[3] = " " if temp[3] == "0"
      temp[1] = " " if temp[1] == "0"
      year_y = temp[1].to_s + temp[2].to_s
      mon = temp[3].to_s + temp[4].to_s
      day = temp[5].to_s + temp[6].to_s
      out_date = year_y + mon + day
    else
      if temp[5] == "0"
        temp[5] = ""
      end
      if temp[3] == "0"
        temp[3] = ""
      end
      if temp[1] == "0"
        temp[1] = ""
      end
      
      out_date = toshi[temp[0].to_i].to_s + temp[1].to_s + \
        temp[2].to_s + "年" + temp[3].to_s + temp[4].to_s + "月"

      if !temp[5].to_s.empty? or !temp[6].to_s.empty?
        out_date = out_date + temp[5].to_s + temp[6].to_s + "日"
      end
    end
    return out_date
  end

  # 和暦 -> 西暦 (5桁 -> 8桁)日付データ
  # wa2sei(41611)
  # ５桁数値なら、西暦を返す
  # ８桁数値なら、和暦を返す
  def wa2sei(data, split_str="")
    toshi = ["-", "1867", "1911", "1925", "1988"]
    temp = []
    temp = data.to_s.split(//) 
    if /^\d{5}$/ =~ data.to_s
      year = (toshi[temp[0].to_i].to_i + ((temp[1].to_i * 10).to_i + temp[2].to_i).to_i).to_s
      month = temp[3].to_s + temp[4].to_s
      if split_str == ""
        return year+month
      elsif split_str == Array
        return [year, month]
      else
        return year+split_str.to_s+month
      end
    elsif data.to_s =~ /^\d{8}$/
      wa_reki = (toshi.size - 1)
      year = (temp[0].to_s + temp[1].to_s + temp[2].to_s + temp[3].to_s).to_i - toshi.last.to_i 
      month = temp[4].to_s + temp[5].to_s
      if split_str == ""
        return wa_reki.to_s + year.to_s + month
      elsif split_str.class == Array
        return [wa_reki.to_s, year, month]
      else
        return wa_reki.to_s + split_str.to_s + year.to_s + split_str.to_s + month
      end
    else
      return "ERR"
    end
  end

  def now_Days
    year  = Date.today.year.to_s
    month = sprintf("%02d", Date.today.month.to_s)
    day   = sprintf("%02d", Date.today.day.to_s)
    return year+month+day
  end

  def now_Times
    nowt = Time.new
    return nowt.strftime("%Y/%m/%d %H:%M:%S").to_s
  end

  def uniq_Times
    time = Time.new
    return time.strftime("%Y%m%d%H%M%S") + time.usec.to_s
  end

  def uniq_TimesLog
    time = Time.new
    return time.strftime("%Y/%m/%d %H:%M:%S") + time.usec.to_s
  end

  module_function :wa2toshi
  module_function :date_make
  module_function :data7make
  module_function :wa2sei
end
