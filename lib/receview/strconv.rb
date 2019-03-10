# -*- encoding: utf-8 -*-

require 'jma/receview/generation'

module StrConv
  require 'nkf'
  require 'jma/receview/base'

  def fix_utf8(str,stat=true)
    base = ReceView_Base.new
    conv_str = ""
    if base.nkf_version[NKF::VERSION]
      conv_str = str.toutf8
    else
      if RUBY_VERSION.to_s <= "1.8.7"
        conv_str = NKF.nkf("-Ew", ("＠".toeuc + str)).sub(/^＠/, "")
      else
        conv_str = NKF.nkf("-Ew", str)
      end
    end
    return conv_str
  end

  # 文字サイズ取得
  def array_char_size(array)
    line_char_size = 0
    array.each do |t|
      if t.size == 1
        line_char_size += 1
      else
        line_char_size += 2
      end
    end
    return line_char_size
  end

  # 文字サイズ取得
  def string_char_size(str)
    if str.size == 1
      line_char_size = 1
    else
      line_char_size = 2
    end
    return line_char_size
  end

  # 文字最大値チェック
  def char_max_value(str, max=1, mini=0)
    if max >= mini
      stat_size = str.to_s.split(//).size
      if stat_size <= max
        if stat_size >= mini
          true
        else
          false
        end
      else
        false
      end
    else
      raise "StrConv Error: int [max < mini]"
    end
  end

  # 全角チェック
  def em_size(str)
    if /(?:\xEF\xBD\xA1-\xEF\xBD\xBF|\xEF\xBE\x80-\xEF\xBE\x9F)|[\x20-\x7E]/ !~ str
      return true
    else
      return false
    end
  end

  # 半角数値チェック
  def nw_size(str, plus="")
    c = "[^0-9#{plus}]"
    if /#{c}/ !~ str
      return true
    else
      return false
    end
  end
  
  # 文字を固定長まで空白を入れて返す
  def word2kotei(word="", long=1)
    wsize = word.split(//).size
    unless wsize > long
      tmp_size = long - wsize
      tmp_size.times do
        word << " "
      end
    end
    return word
  end

  # 文字を固定長まで空白を入れて返す
  def word2kotei2(word="", long=1)
    wsize = 0
    word.split(//).each do |w|
      if em_size(w)
        wsize += 2
      else
        wsize += 1
      end
    end

    if wsize < long
      tmp_size = long - wsize
      tmp_size.times do
        word = " " + word
      end
    end
    return word
  end

  # 半角数字、半角スペースを全角文字にする
  def sw2bw(word="", mode="")
    makew = word.to_s
    list_s = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", " ", ","]
    list_b = ["１","２","３","４","５","６","７","８","９","０","　", "，"]

    if mode == "Reverse"
      list_b.each_with_index do |str, index|
        makew = makew.gsub(/#{str}/, list_s[index])
      end
    else
      list_s.each_with_index do |str, index|
        makew = makew.gsub(/#{str}/, list_b[index])
      end
    end
    return makew
  end

  def mark(word)
    return "(#{word})"
  end

  # 文字をサイズを返す
  def word_size(word="")
    wsize = 0
    word.split(//).each do |w|
      if em_size(w)
        wsize += 2
      else
        wsize += 1
      end
    end
    return wsize
  end

  # 文字コード判定 NKF
  def str_encode(str)
    case NKF.guess(str)
    when NKF::UTF8
      "utf8"
    when NKF::SJIS
      "sjis"
    when NKF::EUC
      "euc"
    when NKF::ASCII
      "ascii"
    when NKF::UNKNOWN
      "unknown"
    end
  end

  def str_return(str, return_int, prefix="")
    str_fix = prefix + ""
    strs = str.to_s.split(//)

    strs.each_with_index do |str_tmp, str_index|
      str_fix << str_tmp
      if (str_index+1) % return_int == 0 and (str_index+1) != strs.size
        str_fix << "\n" + prefix
      end
    end
    return str_fix
  end

  def str_return_array(str, return_int, prefix="")
    return str_return(str, return_int, prefix).split(/\n/)
  end

  # 単位コード付加 image preview
  def make_preview_mark(name="", tani="", parent=1)
    if !tani.to_s.empty?
      if parent.to_i == 1
        name_plus_tani = "（#{name}　#{tani}）"
      else
        name_plus_tani = "#{name}　#{tani}"
      end
    else
      name_plus_tani = name
    end
    return name_plus_tani
  end

  # 単位コード付加 診療行為ビュー
  def make_diagnosis_mark(name="", parent=1)
    if parent.to_i == 1
      name_plus_tani = "（#{name}）"
    else
      name_plus_tani = "#{name}"
    end
    return name_plus_tani
  end

  module_function :word2kotei
  module_function :str_encode
end


