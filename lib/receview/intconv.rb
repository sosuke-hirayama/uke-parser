# -*- encoding: utf-8 -*-

module IntConv
  # VersionPerth
  def int2ver(value)
    version = []
    value.to_s.scan(/(\d{1,2})(?=(?:\d{2}*$))/).flatten.each do |v|
      version.push(v.sub(/^0+/, "").to_i.to_s)
    end
    return version.join(".")
  end

  # ３桁ごとにカンマ区切りにする S
  def int2kanma(value)
    value.to_s.scan(/(\d{1,3})(?=(?:\d{3}*$))/).join(",") 
  end

  # ３桁ごとにカンマ区切りにする L
  def i2k_l(value)
    value.to_s.scan(/(\d{1,3})(?=(?:\d{3}*$))/).join("，") 
  end

  # 小数点だけを削除
  def dpoint2zero(value="0")
    # if /([+-]?[1-9]?\d+(\.\d+[1-9])?)(0*)?/ =~ value ; return $1 ; end
    temp = ""
    if /\S*\.\S*/ =~ value
      temp = value.sub(/\.*[0]+$/, "")
    else
      temp = value.sub(/\.[0]+$/, "")
    end
    return temp
  end
  module_function :int2ver
  module_function :int2kanma
  module_function :dpoint2zero
end

