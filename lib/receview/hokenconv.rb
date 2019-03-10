# -*- encoding: utf-8 -*-

require 'jma/receview/generation'

module HokenConv
  require 'date'
  def ken2wau_name(code="00")
    # 県番号から広域連合の統括番号
    wau_no = {
      "01" => "39010004",
      "02" => "39020003",
      "03" => "39030002",
      "04" => "39040001",
      "05" => "39050000",
      "06" => "39060009",
      "07" => "39070008",
      "08" => "39080007",
      "09" => "39090006",
      "10" => "39100003",
      "11" => "39110002",
      "12" => "39120001",
      "13" => "39130000",
      "14" => "39140009",
      "15" => "39150008",
      "16" => "39160007",
      "17" => "39170006",
      "18" => "39180005",
      "19" => "39190004",
      "20" => "39200001",
      "21" => "39210000",
      "22" => "39220009",
      "23" => "39230008",
      "24" => "39240007",
      "25" => "39250006",
      "26" => "39260005",
      "27" => "39270004",
      "28" => "39280003",
      "29" => "39290002",
      "30" => "39300009",
      "31" => "39310008",
      "32" => "39320007",
      "33" => "39330006",
      "34" => "39340005",
      "35" => "39350004",
      "36" => "39360003",
      "37" => "39370002",
      "38" => "39380001",
      "39" => "39390000",
      "40" => "39400007",
      "41" => "39410006",
      "42" => "39420005",
      "43" => "39430004",
      "44" => "39440003",
      "45" => "39450002",
      "46" => "39460001",
      "47" => "39470000"
    }
    return wau_no[code.to_s].to_s
  end

  def code2syouki(code="00")
    syouki_conv = {
      "01" => "【主たる疾患の診断根拠となる臨床症状】",
      "02" => "【主たる疾患の診断根拠となる臨床症状の診察検査所見】",
      "03" => "【主な治療行為（手術、処置、薬物治療等）の必要性】",
      "04" => "【主な治療行為（手術、処置、薬物治療等）の経過】",
      "05" => "【合計点数が１００万点以上の薬剤に係る症状等】",
      "06" => "【合計点数が１００万点以上の処置に係る症状等】",
      "07" => "【その他１】",
      "08" => "【その他２】",
      "09" => "【その他３】",
      "50" => "【治験概要】",
      "51" => "【疾患別リハビリテーションに係る治療継続理由】",
      "52" => "【廃用症候群に係る評価表】",
      "90" => "【診療報酬明細以外の診療報酬明細書の症状症記】",
    }
    return syouki_conv[code].to_s
  end

  def code2tokki(code="00", yyyymm=201404)
    yyyymm = wa2sei(yyyymm).to_i 
    tokki_conv = {
      "01" => "公",
      "02" => "長",
      "03" => "長処",
      "04" => "老保",
      "05" => "高度",
      "06" => "(欠)",
      "07" => "老併",
      "08" => "老健",
      "09" => "施",
      "10" => "第三",
      "11" => "薬治",
      "12" => "器治",
      "13" => "先進",
      "14" => "制超",
      "15" => "経過",
      "16" => "長２",
      "17" => "上位",
      "18" => "一般",
      "19" => "低所",
      "20" => "二割",
      "21" => "高半",
      "22" => "多上",
      "23" => "多一",
      "24" => "多低",
      "25" => "出産",
      "26" => "区ア",
      "27" => "区イ",
      "28" => "区ウ",
      "29" => "区エ",
      "30" => "区オ",
      "31" => "多ア",
      "32" => "多イ",
      "33" => "多ウ",
      "34" => "多エ",
      "35" => "多オ",
      "36" => "加治",
      "37" => "申出",
      "38" => "医併",
      "39" => "医療"
    }

    if yyyymm.to_i >= 200804
      tokki_conv["04"] = "後保"
    end

    return tokki_conv[code].to_s
  end

  def tokki_c2s_marge(tokki_raw)
    tokki_data = ""
    tokki_raw.scan(/\d\d/).each do |tkcode|
      tokki_data << "(#{tkcode}#{code2tokki(tkcode)})"
    end
    return tokki_data
  end

  def kouhi2syurui(kouhixx="0", make_day=200701)
    kouhixx.sub!(/^[0]+/, "")
    kouhi_conv = {
      "10" => "感染症（３７条の２）",
      "11" => "感染症（結核入院）",
      "12" => "生活保護",
      "13" => "戦傷病者（療養給付）",
      "14" => "戦傷病者（更生）",
      "15" => "自立支援医療（更生）",
      "16" => "自立支援医療（育成）",
      "17" => "児童福祉（療養医療）",
      "18" => "原爆認定疾病",
      "19" => "原爆一般疾病",
      "20" => "精神措置入院",
      "21" => "自立支援医療（精神通院）",
      "23" => "母子家庭",
      "24" => "療養介護医療",
      "25" => "中国残留邦人等支援",
      "27" => "老人保健",
      "28" => "感染症（１類・２類）",
      "29" => "新感染症",
      "30" => "心神喪失者等医療",
      "38" => "肝炎治療",
      "51" => "特定疾患",
      "52" => "小児慢性特定疾患",
      "53" => "児童保護措置",
      "54" => "難病医療",
      "66" => "石綿健康被害救済",
      "79" => "障害児施設医療",
      "972" => "長期高額療養費",
    }

    # 200804移行
    if make_day.to_i >= 200804
      kouhi_conv["39"] = "後期高齢者"
      kouhi_conv["40"] = "後期高齢者 医療特別療養費"
    end

    data = kouhi_conv[kouhixx.to_s]
    if data.to_s.empty?
      data = kouhixx.to_s
    end
    return data
  end

  # 被保険者不明
  def hoken_Unknown?(hoken_code)
    if hoken_code == "99999999"
      true
    else
      false
    end
  end

  # 1が返るなら 公費 0なら違う
  def hoken2kouhi?(hoken_code="1111")
    tmp = hoken_code.split(//)
    if tmp[1].to_s == "2"
      out = 1
    elsif tmp[2].to_s == "2" or tmp[2].to_s == "3"
      out = 1
    else
      out = 0
    end
    return out
  end

  # 公費桁数チェック
  def kouhi_check_size?(kouhi_code=nil)
    if kouhi_code != nil
      if kouhi_code.size >= 1 or kouhi_code.size <= 8
        return true
      else
        return false
      end
    else
      return false
    end
  end

  # 入院=true 入院外=false
  # 1,3,5,7,9 => "本入"
  # 2,4,6,8 => "本外"
  def hospital_stat?(code)
    ch = code.split(//)[3].to_s
    ref_table = {
      "0" => false,
      "1" => true,
      "2" => false,
      "3" => true,
      "4" => false,
      "5" => true,
      "6" => false,
      "7" => true,
      "8" => false,
      "9" => true
    }
    return ref_table[ch]
  end

  # 入院=true 入院外=false
  # 9項目にデータがある場合
  def rosai_hospital_stat?(code)
    rhosp = false
    if code.class == Array
      if !code[8].to_s.empty?
        rhosp = true
      end
    else
      if !code.split(/,/)[8].to_s.empty?
        rhosp = true
      end
    end
    return rhosp
  end

  # 入院=true 入院外=false
  # 帳票種別を確認
  def rosai_hospital_form_stat?(code, mode="")
    # 入外傷,入院外傷 true
    if mode == "preview"
      case code2rosai_formdoc(code, "rece")
      when "34702"
        false
      when "34703"
        false
      when "34704"
        true
      when "34705"
        true
      else
        false
      end
    else
      # 入外,入院外 true
      case code2rosai_formdoc(code, "rece")
      when "34702"
        true
      when "34703"
        false
      when "34704"
        true
      when "34705"
        false
      else
        false
      end
    end
  end

  # 保険種別コード,保険コードより
  # num = 1 : 社保 hoken_code検索
  # num = 2 : 国保 hoken_code検索
  # hoken_code : 各種4桁数値コード
  def code2hoken(num, hoken_code, date, mode=0, rece=false)
    # レセプト種別コード
    
    sk_1 = { 1 => "医科" }
    kk_1 = { 1 => "医科" }

    sk_2 = {
      1 => "医保",
      2 => "公費",
      3 => "老人",
      4 => "退職",
    }

    kk_2 = {
      1 => "医保",
      2 => "",
      3 => "老人",
      4 => "退職",
    }

    if rece
      sk_3_a = {
        1 => "単独",
        2 => "２併",
        3 => "３併",
        4 => "３併",
        5 => "３併",
      }
      sk_3_b= {
        1 => "単独",
        2 => "２併",
        3 => "３併",
        4 => "３併",
        5 => "３併",
      }

      kk_3_a = {
        1 => "単独",
        2 => "２併",
        3 => "３併",
        4 => "３併",
        5 => "３併",
      }
      kk_3_b = {
        1 => "単",
        2 => "１種",
        3 => "２種",
        4 => "３種",
        5 => "４種",
      }

      sk_4_a = {
        1 => "本",
        2 => "本",
        3 => "三",
        4 => "三",
        5 => "家",
        6 => "家",
        7 => "高",
        8 => "高",
        9 => "高",
        0 => "高",
      }
      sk_4_b = {
        1 => "本",
        2 => "本",
        3 => "三",
        4 => "三",
        5 => "家",
        6 => "家",
        7 => "高",
        8 => "高",
        9 => "高",
        0 => "高",
      }

      kk_4_a = {
        1 => "本",
        2 => "本",
        3 => "三",
        4 => "三",
        5 => "家",
        6 => "家",
        7 => "高",
        8 => "高",
        9 => "高",
        0 => "高",
      }
      kk_4_b = {
        1 => "本",
        2 => "本",
        3 => "三",
        4 => "三",
        5 => "家",
        6 => "家",
        7 => "高",
        8 => "高",
        9 => "高",
        0 => "高"
      }

      sk_5_a = {
        1 => "入",
        2 => "外",
        3 => "入",
        4 => "外",
        5 => "入",
        6 => "外",
        7 => "入一",
        8 => "外一",
        9 => "入７",
        0 => "外７",
      }
      sk_5_b = {
        1 => "入",
        2 => "外",
        3 => "入",
        4 => "外",
        5 => "入",
        6 => "外",
        7 => "入一",
        8 => "外一",
        9 => "入７",
        0 => "外７",
      }

      kk_5_a = {
        1 => "入",
        2 => "外",
        3 => "入",
        4 => "外",
        5 => "入",
        6 => "外",
        7 => "入一",
        8 => "外一",
        9 => "入７",
        0 => "外７",
      }
      kk_5_2 = {
        1 => "入",
        2 => "外",
        3 => "入",
        4 => "外",
        5 => "入",
        6 => "外",
        7 => "入一",
        8 => "外一",
        9 => "入７",
        0 => "外７",
      }
    else
      sk_3_a = {
        1 => "単独",
        2 => "と１種の公費併用",
        3 => "と２種の公費併用",
        4 => "と３種の公費併用",
        5 => "と４種の公費併用",
      }
      sk_3_b = {
        1 => "単独",
        2 => "と２種の公費併用",
        3 => "と３種の公費併用",
        4 => "と４種の公費併用",
      }

      kk_3_a = {
        1 => "単独",
        2 => "と１種の公費併用",
        3 => "と２種の公費併用",
        4 => "と３種の公費併用",
        5 => "と４種の公費併用",
      }
      kk_3_b = {
        1 => "単",
        2 => "１種",
        3 => "２種",
        4 => "３種",
        5 => "４種",
      }

      sk_4_a = {
        1 => "本人",
        2 => "本人",
        3 => "三歳未満",
        4 => "三歳未満",
        5 => "家族",
        6 => "家族",
        7 => "高齢受給者９割",
        8 => "高齢受給者９割",
        9 => "高齢受給者８割",
        0 => "高齢受給者８割",
      }
      sk_4_b = {
        1 => "本人",
        2 => "本人",
        3 => "三歳",
        4 => "三歳",
        5 => "家族",
        6 => "家族",
        7 => "高９",
        8 => "高９",
        9 => "高８",
        0 => "高８",
      }

      kk_4_a = {
        1 => "本人",
        2 => "本人",
        3 => "三歳未満",
        4 => "三歳未満",
        5 => "家族",
        6 => "家族",
        7 => "高齢受給者９割",
        8 => "高齢受給者９割",
        9 => "高齢受給者８割",
        0 => "高齢受給者８割"
      }
      kk_4_b = {
        1 => "本人",
        2 => "本人",
        3 => "三歳",
        4 => "三歳",
        5 => "家族",
        6 => "家族",
        7 => "高９",
        8 => "高９",
        9 => "高８",
        0 => "高８",
      }

      sk_5_a = {
        1 => "入院",
        2 => "入院外",
        3 => "入院",
        4 => "入院外",
        5 => "入院",
        6 => "入院外",
        7 => "入院",
        8 => "入院外",
        9 => "入院",
        0 => "入院外",
      }
      sk_5_b = {
        1 => "入",
        2 => "外",
        3 => "入",
        4 => "外",
        5 => "入",
        6 => "外",
        7 => "入",
        8 => "外",
        9 => "入",
        0 => "外",
      }

      kk_5_a = {
        1 => "入院",
        2 => "入院外",
        3 => "入院",
        4 => "入院外",
        5 => "入院",
        6 => "入院外",
        7 => "入院",
        8 => "入院外",
        9 => "入院",
        0 => "入院外",
      }
      kk_5_2 = {
        1 => "入",
        2 => "外",
        3 => "入",
        4 => "外",
        5 => "入",
        6 => "外",
        7 => "入",
        8 => "外",
        9 => "入",
        0 => "外",
      }
    end

    # 2006/9/30 まで高齢者８割
    # 2006/10/1 より高齢者７割
    # 2008/3/31 まで高齢者７割
    # 2008/4/1  より
    
    if !date.nil?
      # 41606 -> 200406
      darr = wa2sei(date, Array)
      now_date = Date::new(darr[0].to_i, darr[1].to_i, 1)

      date_flg = 0
      if now_date >= Date::new(2009, 1, 1)
        date_flg = 2
      elsif now_date >= Date::new(2008, 4, 1)
        date_flg = 2
      elsif now_date >= Date::new(2007, 10, 1)
        date_flg = 1
      elsif now_date >= Date::new(2006, 10, 1)
        date_flg = 1
      else
        date_flg = 0
      end

      # (2007, 10, 1) or (2006, 10, 1)以降
      if date_flg >= 1
        sk_4_a.each do |key,tmp|
          sk_4_a[key] = tmp.gsub(/８割/, "７割")
        end
        sk_4_b.each do |key,tmp|
          sk_4_b[key] = tmp.gsub(/８/, "７")
        end
        kk_4_a.each do |key,tmp|
          kk_4_a[key] = tmp.gsub(/８/, "７")
        end
        kk_4_b.each do |key,tmp|
          kk_4_b[key] = tmp.gsub(/８/, "７")
        end
      end

      # (2009, 1, 1) or (2008, 4, 1)以降
      if date_flg == 2
        sk_2.each do |key,tmp|
          if rece
            sk_2[key] = tmp.to_s.gsub(/老人/, "後期")
          else
            sk_2[key] = tmp.to_s.gsub(/老人/, "後期高齢者")
          end
        end
        kk_2.each do |key,tmp|
          if rece
            kk_2[key] = tmp.to_s.gsub(/老人/, "後期")
          else
            kk_2[key] = tmp.to_s.gsub(/老人/, "後期高齢者")
          end
        end
        sk_4_a.each do |key,tmp|
          sk_4_a[key] = tmp.to_s.gsub(/三歳未満/, "未就学者")
        end
        sk_4_b.each do |key,tmp|
          sk_4_b[key] = tmp.to_s.gsub(/三歳/, "未就学者")
        end
        kk_4_a.each do |key,tmp|
          kk_4_a[key] = tmp.to_s.gsub(/三歳未満/, "未就学者")
        end
        kk_4_b.each do |key,tmp|
          kk_4_b[key] = tmp.to_s.gsub(/三歳/, "未就学者")
        end
      end
    end

    # mode 1 42003 end
    # mode 2 42004 start
    # mode 3 42004 and 三歳未満=>未就学者
    case mode
    when 1
      sk_4_a.each do |key,tmp|
        sk_4_a[key] = tmp.gsub(/８割|７割/, "７割(８割)")
      end
      sk_4_b.each do |key,tmp|
        sk_4_b[key] = tmp.gsub(/高８|高７/, "高７(高８)")
      end
      kk_4_a.each do |key,tmp|
        kk_4_a[key] = tmp.gsub(/８割|７割/, "７割(８割)")
      end
      kk_4_b.each do |key,tmp|
        kk_4_b[key] = tmp.gsub(/高８|高７/, "高７(高８)")
      end
    when 2
      sk_4_a.each do |key,tmp|
        tmp.gsub!(/８割|７割/, "７割")
        tmp.gsub!(/高齢受給者/, "")
        tmp.gsub!(/９割/, "高一")
        sk_4_a[key] = tmp
      end
      sk_4_b.each do |key,tmp|
        tmp.gsub!(/高８|高７/, "高７")
        tmp.gsub!(/高齢受給者/, "")
        tmp.gsub!(/高９/, "高一")
        sk_4_b[key] = tmp
      end
      kk_4_a.each do |key,tmp|
        tmp.gsub!(/８割|７割/, "７割")
        tmp.gsub!(/高齢受給者/, "")
        tmp.gsub!(/９割/, "高一")
        kk_4_a[key] = tmp
      end
      kk_4_b.each do |key,tmp|
        tmp.gsub!(/高８|高７/, "高７")
        tmp.gsub!(/高齢受給者/, "")
        tmp.gsub!(/高９/, "高一")
        kk_4_b[key] = tmp
      end
    when 3
      sk_4_a.each do |key,tmp|
        tmp.gsub!(/８割|７割/, "７割")
        tmp.gsub!(/高齢受給者/, "")
        tmp.gsub!(/９割/, "一般・低所得")
        sk_4_a[key] = tmp
      end
      sk_4_b.each do |key,tmp|
        tmp.gsub!(/高８|高７/, "高７")
        tmp.gsub!(/高齢受給者/, "")
        tmp.gsub!(/高９/, "一般・低所得")
        sk_4_b[key] = tmp
      end
      kk_4_a.each do |key,tmp|
        tmp.gsub!(/８割|７割/, "７割")
        tmp.gsub!(/高齢受給者/, "")
        tmp.gsub!(/９割/, "一般・低所得")
        kk_4_a[key] = tmp
      end
      kk_4_b.each do |key,tmp|
        tmp.gsub!(/高８|高７/, "高７")
        tmp.gsub!(/高齢受給者/, "")
        tmp.gsub!(/高９/, "一般・低所得")
        kk_4_b[key] = tmp
        # rece_code_k_4_1[key] = tmp
      end
      sk_4_a.each do |key,tmp|
        tmp.gsub!(/三歳未満/, "未就学者")
        sk_4_a[key] = tmp
      end
      sk_4_b.each do |key,tmp|
        tmp.gsub!(/三歳/, "未就学者")
        sk_4_b[key] = tmp
      end
      kk_4_a.each do |key,tmp|
        tmp.gsub!(/三歳未満/, "未就学者")
        kk_4_a[key] = tmp
      end
      kk_4_b.each do |key,tmp|
        tmp.gsub!(/三歳/, "未就学者")
        kk_4_b[key] = tmp
      end
    else
      sk_4_a.each do |key,tmp|
        tmp.gsub!(/三/, "六")
        tmp.gsub!(/高９/, "一般・低所得")
        sk_4_a[key] = tmp
      end
      sk_4_b.each do |key,tmp|
        tmp.gsub!(/三/, "六")
        tmp.gsub!(/高９/, "一般・低所得")
        sk_4_b[key] = tmp
      end
      kk_4_a.each do |key,tmp|
        tmp.gsub!(/三/, "六")
        tmp.gsub!(/高９/, "一般・低所得")
        kk_4_a[key] = tmp
      end
      kk_4_b.each do |key,tmp|
        tmp.gsub!(/三/, "六")
        tmp.gsub!(/高９/, "一般・低所得")
        kk_4_b[key] = tmp
      end
    end

    d = []
    d = hoken_code.split(//)
    case num
    when 1
      if d[1] == 2
        out = sk_1[d[0].to_i] + ","
        out << sk_2[d[1].to_i] + "," 
        out << sk_1[d[0].to_i] + ","
        out << sk_2[d[1].to_i] + ","
        out << sk_3_b[d[2].to_i] + ","
        out << sk_4_a[d[3].to_i] + ","
        out << sk_5_a[d[3].to_i]
      else
        out = sk_1[d[0].to_i] + ","
        out << sk_2[d[1].to_i] + ","
        out << sk_3_a[d[2].to_i] + ","
        out << sk_4_a[d[3].to_i] + ","
        out << sk_5_a[d[3].to_i]
      end
    when 2
      if d[1] == 2
        out = kk_1[d[0].to_i] + ","
        out << kk_2[d[1].to_i] + ","
        out << kk_3_b[d[2].to_i] + ","
        out << kk_4_a[d[3].to_i] + ","
        out << kk_5_a[d[3].to_i]
      else
        out = kk_1[d[0].to_i] + ","
        out << kk_2[d[1].to_i] + ","
        out << kk_3_a[d[2].to_i] + ","
        out << kk_4_b[d[3].to_i] + ","
        out << kk_5_a[d[3].to_i]
      end
    when 3
      if d[1] == 2
        out = ks_1[d[0].to_i] + ","
        out << sk_2[d[1].to_i] + ","
        out << sk_3_b[d[2].to_i] + ","
        out << sk_4_b[d[3].to_i] + ","
        out << sk_5_b[d[3].to_i]
      else
        out = sk_1[d[0].to_i] + ","
        out << sk_2[d[1].to_i] + ","
        out << sk_3_a[d[2].to_i] + ","
        out << sk_4_b[d[3].to_i] + ","
        out << sk_5_b[d[3].to_i]
      end
    when 4
      if d[1] == 2
        out = kk_1[d[0].to_i] + ","
        out << kk_2[d[1].to_i] + ","
        out << kk_3_b[d[2].to_i] + ","
        out << kk_4_b[d[3].to_i] + ","
        out << kk_5_b[d[3].to_i]
      else
        out = kk_1[d[0].to_i] + ","
        out << kk_2[d[1].to_i] + ","
        out << kk_3_a[d[2].to_i] + ","
        out << kk_4_b[d[3].to_i] + ","
        out << kk_5_b[d[3].to_i]
      end
    end

    # 後期高齢者は7割,9割に置換
    if /後期高齢者/ =~ out && /\(高８\)/ =~ out
      out.gsub!(/\(高８\)/, "")
    end

    # 2006年10月1日以降でREレコードの特定項目に'80'があるなら,
    # (８割給付)の項目を追加する 本処理は外
    if date_flg.to_i >= 1
      if /高|７/ =~ out
        out << "," + "(８割給付)"
      end
    end

    if /７割|９割/ =~ out and  /医保,と/ =~ out
      out.gsub!(/医保/, "医保(７０歳以上)")
      out.gsub!(/高齢受給者９割/, "一般・低所得")
    elsif /７割|９割/ =~ out and  /医保,単独/ =~ out
      out.gsub!(/単独/, "単独(７０歳以上)")
      out.gsub!(/高齢受給者９割/, "一般・低所得")
    end

    return out
  end

  # 性別区分コード
  def sex_code2str(code="1", stat="old")
    scode = code.to_i.to_s
    if stat == "old"
      s_data = {
        "1" => "男",
        "2" => "女",
      }
    else
      s_data = {
        "1" => "男性",
        "2" => "女性",
        "3" => "小児",
        "4" => "老人",
        "5" => "周産期",
        "6" => "新生児",
        "7" => "児童",
        "8" => "思春期",
        "9" => "老年",
        "10" => "高齢者",
      }
    end
    return s_data[scode].to_s
  end

  # 転帰区分コード
  def tenki_code2str(code="1")
    tenki_data = {
      "1" => "継続",
      "2" => "治癒",
      "3" => "死亡",
      "4" => "中止"
    }
    return tenki_data[code.to_s]
  end

  # 負担区分コード
  # kubun_code : Old 1桁(1-8.A.D.F)
  # kubun_code : New 1桁(1-9.A-Z)
  def code2hutan(kubun_code)
    hutan_kubun_data = {
      "1" => "医単独",
      "2" => "医公１",
      "3" => "医公２",
      "4" => "医公12",
      "5" => "公１",
      "6" => "公２",
      "7" => "公12",
      "8" => "医老２",
        "9" => "医1234",
      "A" => "医公2老2",
        "B" => "公３",
        "C" => "公４",
      "D" => "公2老2",
        "E" => "医公３",
      "F" => "老２",
      "G" => "医公４",
        "H" => "公13",
        "I" => "公14",
        "J" => "公23",
        "K" => "公24",
        "L" => "公34",
        "M" => "医公13",
        "N" => "医公14",
        "O" => "医公23",
        "P" => "医公24",
        "Q" => "医公34",
        "R" => "公123",
        "S" => "公124",
        "T" => "公134",
        "U" => "公234",
        "V" => "医公123",
        "W" => "医公12",
        "X" => "医公134",
        "Y" => "医公234",
        "Z" => "公1234",
    }
    return hutan_kubun_data[kubun_code.to_s]
  end

  # 負担区分コードチェック
  # kubun_code : 1桁(1-9.A-Z)
  # mode = "bit" 1,2,4,8,16 
  #              h,k1,k2,k3,k4
  def chutan_check(k_code, mode=nil)
    if mode == "bit"
      hutan_kubun_stat = {
        # 保険
        "1" => 1,

        # 保険 ^ 1種
        "2" => 3,
        "3" => 5,
        "E" => 9,
        "G" => 17,

        # 保険 ^ 2種
        "4" => 7,
        "M" => 11,
        "N" => 19,
        "O" => 13,
        "P" => 21,
        "Q" => 25,

        # 保険 ^ 3種
        "V" => 15,
        "W" => 23,
        "X" => 27,
        "Y" => 29,

        # 保険 ^ 4種
        "9" => 31,

        # 1種[公費単独]
        "5" => 2,
        "6" => 4,
        "B" => 8,
        "C" => 16,

        # 2種
        "7" => 6,
        "H" => 10,
        "I" => 18,
        "J" => 12,
        "K" => 20,
        "L" => 24,

        # 3種
        "R" => 14,
        "S" => 22,
        "T" => 26,
        "U" => 28,

        # 4種
        "Z" => 30,
      }
    elsif mode == "type"
      hutan_kubun_stat = {
        # 保険 ^ 1種
        "1" => true,
        "2" => true,
        "3" => true,
        "E" => true,
        "G" => true,

        # 保険 ^ 2種
        "4" => true,
        "M" => true,
        "N" => true,
        "O" => true,
        "P" => true,
        "Q" => true,

        # 保険 ^ 3種
        "V" => true,
        "W" => true,
        "X" => true,
        "Y" => true,

        # 保険 ^ 4種
        "9" => true,

        # 1種[公費単独]
        "5" => true,
        "6" => true,
        "B" => true,
        "C" => true,

        # 2種
        "7" => true,
        "H" => true,
        "I" => true,
        "J" => true,
        "K" => true,
        "L" => true,

        # 3種
        "R" => true,
        "S" => true,
        "T" => true,
        "U" => true,

        # 4種
        "Z" => true,
      }
    else
      hutan_kubun_stat = {
        "1" => 0,
        "2" => 2,
        "3" => 0,
        "4" => 2,
        "5" => 0,
        "6" => 1,
        "7" => 1,
        "8" => -1,
        "9" => 2,
        "A" => -1,
        "B" => 1,
        "C" => 1,
        "D" => -1,
        "E" => 0,
        "F" => -1,
        "G" => 0,
        "H" => 1,
        "I" => 1,
        "J" => 3,
        "K" => 3,
        "L" => 3,
        "M" => 2,
        "N" => 2,
        "O" => 0,
        "P" => 0,
        "Q" => 0,
        "R" => 1,
        "S" => 1,
        "T" => 1,
        "U" => 3,
        "V" => 2,
        "W" => 2,
        "X" => 2,
        "Y" => 0,
        "Z" => 1,
      }
    end
    return hutan_kubun_stat[k_code.to_s]
  end

  def cfutan_status(k_code)
    futan_kubun_stat = {
      # 保険
      "1" => 110000,

      # 保険 ^ 1種
      "2" => 111000,
      "3" => 110100,
      "E" => 110010,
      "G" => 110001,

      # 保険 ^ 2種
      "4" => 111100,
      "M" => 111010,
      "N" => 111001,
      "O" => 110110,
      "P" => 110101,
      "Q" => 110011,


      # 保険 ^ 3種
      "V" => 111110,
      "W" => 111101,
      "X" => 111011,
      "Y" => 110111,

      # 保険 ^ 4種
      "9" => 111111,

      # 1種[公費単独]
      "5" => 101000,
      "6" => 100100,
      "B" => 100010,
      "C" => 100001,

      # 2種
      "7" => 101100,
      "H" => 101010,
      "I" => 101001,
      "J" => 100110,
      "K" => 100101,
      "L" => 100011,

      # 3種
      "R" => 101110,
      "S" => 101101,
      "T" => 101011,
      "U" => 100111,

      # 4種
      "Z" => 101111,
    }
    futan_code = futan_kubun_stat[k_code.to_s].to_s.split(//)
    futan_code.delete_at(0)
    return futan_code
  end

  # 保険種別コード,保険コードより
  # kizai_code : 特定機材単位 3桁数値コード
  def code2kizai_unit(kizai_code="err")
    kizai_code.to_s
    if kizai_code != "err"
      kizai_code_data = {"1" => "分",
                         "2" => "回",
                         "3" => "種",
                         "4" => "箱",
                         "5" => "巻",
                         "6" => "枚",
                         "7" => "本",
                         "8" => "組",
                         "9" => "セット",
                         "10" => "個",
                         "11" => "裂",
                         "12" => "方向",
                         "13" => "トローチ",
                         "14" => "アンプル",
                         "15" => "カプセル",
                         "16" => "錠",
                         "17" => "丸",
                         "18" => "包",
                         "19" => "瓶",
                         "20" => "袋",
                         "21" => "瓶(袋)",
                         "22" => "管",
                         "23" => "シリンジ",
                         "24" => "回分",
                         "25" => "テスト分",
                         "26" => "ガラス筒",
                         "27" => "錠",
                         "28" => "単位",
                         "29" => "万単位",
                         "30" => "フィート",
                         "31" => "滴",
                         "32" => "ｍｇ",
                         "33" => "ｇ",
                         "34" => "Ｋｇ",
                         "35" => "ｃｃ",
                         "36" => "ｍＬ",
                         "37" => "Ｌ",
                         "38" => "ｍＬＶ",
                         "39" => "バイアル",
                         "40" => "ｃｍ",
                         "41" => "ｃｍ２",
                         "42" => "ｍ",
                         "43" => "uＣｉ",
                         "44" => "ｍＣｉ",
                         "45" => "uｇ",
                         "46" => "管(瓶)",
                         "47" => "筒",
                         "48" => "ＧＢｑ",
                         "49" => "ＭＢｑ",
                         "50" => "ＫＢｑ",
                         "51" => "キット",
                         "52" => "国際単位",
                         "53" => "患者当り",
                         "54" => "気圧",
                         "55" => "缶",
                         "56" => "手術当り",
                         "57" => "容器",
                         "58" => "ｍＬ(ｇ)",
                         "59" => "ブリスター",
                         "60" => "シート",
                         "101" => "分画",
                         "102" => "染色",
                         "103" => "種類",
                         "104" => "株",
                         "105" => "菌株",
                         "106" => "照射",
                         "107" => "臓器",
                         "108" => "件",
                         "109" => "部位",
                         "110" => "肢",
                         "111" => "局所",
                         "112" => "種目",
                         "113" => "スキャン",
                         "114" => "コマ",
                         "115" => "処理",
                         "116" => "指",
                         "117" => "歯",
                         "118" => "面",
                         "119" => "側",
                         "120" => "個所",
                         "121" => "日",
                         "122" => "椎間",
                         "123" => "筋",
                         "124" => "菌種",
                         "125" => "項目",
                         "126" => "箇所",
                         "127" => "椎弓",
                         "128" => "食",
                         "129" => "根管",
                         "130" => "３分の１顎",
                         "131" => "月",
                         "132" => "入院初日",
                         "133" => "入院中",
                         "134" => "退院時",
                         "135" => "初回",
                         "136" => "口腔",
                         "137" => "顎",
                         "138" => "週",
                         "139" => "洞",
                         "140" => "神経",
                         "141" => "一連",
                         "142" => "２週",
                         "143" => "２月",
                         "144" => "３月",
                         "145" => "４月",
                         "146" => "６月",
                         "147" => "１２月",
                         "148" => "５年",
                         "149" => "妊娠中",
                         "150" => "検査有り",
                         "151" => "１疾患当り",
                        }
      return kizai_code_data[kizai_code]
    else
      return kizai_code
    end
  end

  # 県レコード
  # code2ken(1) => 青森県
  def code2ken(ken_code="err")
    if ken_code != "err"
      ken = []
      ken[1] = "北海道"
      ken[2] = "青森県"
      ken[3] = "岩手県"
      ken[4] = "宮城県"
      ken[5] = "秋田県"
      ken[6] = "山形県"
      ken[7] = "福島県"
      ken[8] = "茨城県"
      ken[9] = "栃木県"
      ken[10] = "群馬県"
      ken[11] = "埼玉県"
      ken[12] = "千葉県"
      ken[13] = "東京都"
      ken[14] = "神奈川県"
      ken[15] = "新潟県"
      ken[16] = "富山県"
      ken[17] = "石川県"
      ken[18] = "福井県"
      ken[19] = "山梨県"
      ken[20] = "長野県"
      ken[21] = "岐阜県"
      ken[22] = "静岡県"
      ken[23] = "愛知県"
      ken[24] = "三重県"
      ken[25] = "滋賀県"
      ken[26] = "京都府"
      ken[27] = "大阪府"
      ken[28] = "兵庫県"
      ken[29] = "奈良県"
      ken[30] = "和歌山県"
      ken[31] = "鳥取県"
      ken[32] = "島根県"
      ken[33] = "岡山県"
      ken[34] = "広島県"
      ken[35] = "山口県"
      ken[36] = "徳島県"
      ken[37] = "香川県"
      ken[38] = "愛媛県"
      ken[39] = "高知県"
      ken[40] = "福岡県"
      ken[41] = "佐賀県"
      ken[42] = "長崎県"
      ken[43] = "熊本県"
      ken[44] = "大分県"
      ken[45] = "宮崎県"
      ken[46] = "鹿児島県"
      ken[47] = "沖縄県"

      if ken[ken_code.to_i].to_s.empty?
        return ""
      else
        return ken[ken_code.to_i].to_s
      end
    else
      return ken_code.to_s
    end
  end

  # 診療科コード（医療法診療科コード）
  # code2sinryoka(1) => 精神科
  def code2sinryoka(sinryoka_code="err", stat="old")
    receipt_code_sinryouka = {}
    sinryoka_code = sinryoka_code.to_i.to_s
    if sinryoka_code != "err"
      receipt_code_sinryouka = {
        "1" => "内科",
        "2" => "精神科",
        "3" => "神経科",
        "4" => "神経内科",
        "5" => "呼吸器科",
        "6" => "消化器科",
        "7" => "胃腸科",
        "8" => "循環器科",
        "9" => "小児科",
        "10" => "外科",
        "11" => "整形外科",
        "12" => "形成外科",
        "13" => "美容外科",
        "14" => "脳神経外科",
        "15" => "呼吸器外科",
        "16" => "心臓血管外科",
        "17" => "小児外科",
        "18" => "皮膚ひ尿器科",
        "19" => "皮膚科",
        "20" => "ひ尿器科",
        "21" => "性病科",
        "22" => "こう門科",
        "23" => "産婦人科",
        "24" => "産科",
        "25" => "婦人科",
        "26" => "眼科",
        "27" => "耳鼻いんこう科",
        "28" => "気管食道科",
        "29" => "(欠)",
        "30" => "放射線科",
        "31" => "麻酔科",
        "32" => "(欠)",
        "33" => "心療内科",
        "34" => "アレルギー科",
        "35" => "リウマチ科",
        "36" => "リハビリテーション科",
        "37" => "病理診断科",
        "38" => "臨床検査科",
        "39" => "救急科",
      }

      if receipt_code_sinryouka[sinryoka_code].to_s.empty?
        sinryoka_code = "" if sinryoka_code.to_s == "0"
        return sinryoka_code.to_s
      else
        return receipt_code_sinryouka[sinryoka_code].to_s
      end
    else
      return sinryoka_code.to_s
    end
  end

  # 審査支払機関レコード
  # code2siharai(1) => 支払基金
  def code2siharai_kikan(siharai_code="err", mode="")
    if siharai_code != "err"
      if mode == "rece"
        siharai = ["XX", "社", "国"]
        return siharai[siharai_code.to_i]
      else
        siharai = ["XX", "支払基金", "国保連合会"]
        return siharai[siharai_code.to_i]
      end
    else
      return siharai_code
    end
  end

  # 審査支払機関レコード
  # s2send_hoken("支払基金") => 1
  def s2send_hoken(kikin_str="err")
    if kikin_str != "err"
      siharai = {"支払基金" => 1, "国保連合会" => 2}
      kikan_code = siharai[kikin_str.to_s].to_s
      if kikan_code == ""
        kikan_code = 3
      end
      return kikan_code
    else
      return kikin_str.to_s
    end
  end

  # 審査支払機関レコード
  # s2send_hoken_roman("1") => kikin
  # s2send_hoken_roman("2") => kokuho
  # s2send_hoken_roman("")  => etc
  def s2send_hoken_roman(kikin_str="err")
    if kikin_str != "err"
      siharai = {"1" => "kikin", "2" => "kokuho", "3" => "etc"}
      kikan = siharai[kikin_str.to_s].to_s
      kikan = "etc" if kikan == ""

      return kikan
    else
      return kikin_str.to_s
    end
  end

  # 診療識別コード (医科)
  # code2sinryo_dic(11) => 初診
  # デフォルトコード変換はしない
  def code2sinryo_dic(sinryo_code="err", replace=false)
    if sinryo_code != "err"
      sinryo_dic = {
        "11" => "初診",
        "12" => "再診",
        "13" => "指導",
        "14" => "在宅",
        "21" => "内服",
        "22" => "屯服",
        "23" => "外用",
        "24" => "調材",
        "25" => "処方",
        "26" => "麻毒",
        "27" => "調基",
        "28" => "その他",
        "31" => "皮下筋肉内",
        "32" => "静脈内",
        "33" => "その他",
        "39" => "薬材料原点",
        "40" => "処置",
        "50" => "手術",
        "54" => "麻酔",
        "60" => "検査",
        # "64" => "病理診断",
        "70" => "画像診断",
        "80" => "その他",
        "90" => "入院基本料",
        "92" => "特定入院料・その他",
        "97" => "食事療法・標準負担額",
      }
    end
    if replace
      sinryo_dic[sinryo_code]
    else
      sinryo_code.to_s
    end
  end

  # コメントコード判定
  # comment_check(820000001) => trueなら 0以外が戻り値
  # コードの区分によって戻り値が違う
  def comment_check(comment_code=1)
    code = comment_code.to_i
    check_int = 0
    if code >= 810000001 and code <= 819999999
      check_int = 1
    end
    if code >= 820000001 and code <= 829999999
      check_int = 2
    end
    if code >= 830000001 and code <= 839999999
      check_int = 3
    end
    if code >= 840000001 and code <= 849999999
      check_int = 4
    end
    if code >= 850000001 and code <= 859999999
      check_int = 5
    end
    if code >= 860000001 and code <= 869999999
      check_int = 6
    end
    if code >= 870000001 and code <= 879999999
      check_int = 7
    end
    if code >= 880000001 and code <= 889999999
      check_int = 8
    end
    if code >= 890000001 and code <= 899999999
      check_int = 9
    end
    return check_int
  end

  # 修飾語判定コード(接頭語、接尾語)
  def syusyoku_check(code=1)
    code.to_i
    if code <= 7 ; return 1
    elsif code == 8 ; return 2
    elsif code == 9 ; return 3
    else ; return 0 ; end
  end

  # 逓減,減点コードチェック
  def minas_code(code="00")
    return_code = false
    minas_point = [
      "630010001",
      "630010002",
      "630010003",
      "630010004",
      "630010005",
      "630010006",
      "630010007",
      "190076910",
      "190789710",
      "199000210",
      "199000410",
    ]
    minas_point.each do |check_code|
      if check_code.to_s == code.to_s
        return_code = true
        break
      end
    end
    return return_code
  end

  def osin_check(code)
    flg = 0
    if code.slice(0,3) == "114"
      # 往診（特別往診）
      case code
      when "114000110"
        flg = 1
      when "114001610"
        flg = 1
      when "114000970"
        flg = 1
      when "114002470"
        flg = 1
      when "114002970"
        flg = 1
      end

      # 夜間
      case code
      when "114000470"
        flg = 2
      when "114001970"
        flg = 2
      when "114011670"
        flg = 2
      when "114011970"
        flg = 2
      end

      # 深夜・緊急
      case code
      when "114000370"
        flg = 3
      when "114000570"
        flg = 3
      when "114001870"
        flg = 3
      when "114002070"
        flg = 3
      when "114011570"
        flg = 3
      when "114011770"
        flg = 3
      when "114011870"
        flg = 3
      when "114012070"
        flg = 3
      end

      if flg == 0
        flg = 4
      end
    end
    return flg
  end

  def medicine_type_check(code, type)
    flg = 0
    case type.to_s
    when "210"
      c1 = code.slice(0,1)
      c2 = code.slice(0,3)
      c3 = code.slice(0,7)
      if c1 == "6" or c1 == "7" or c1 == "8"
        flg = 0
      elsif c2 == "001" or c2 == "008" or c2 == "059" or c3 == "0992000"
        flg = 0
      else
        flg = 1
      end
    when "230"
      c1 = code.slice(0,1)
      c2 = code.slice(0,3)
      c3 = code.slice(0,7)
      if c1 == "6" or c1 == "7" or c1 == "8"
        flg = 0
      elsif c2 == "001" or c2 == "008" or c2 == "059" or c3 == "0992000"
        flg = 0
      else
        flg = 1
      end
    end

    return flg
  end

  # 職務上の事由
  def reason_on_duty(code, mode="")
    if mode == "pre"
      duty_code = {
        1 => "職務上",
        2 => "下船後３月以内",
        3 => "通勤災害",
      }
    else
      duty_code = {
        1 => "(職務上)",
        2 => "(下船３月)",
        3 => "(通勤災害)",
      }
    end
    return duty_code[code.to_i].to_s
  end

  # 状態区分
  def re_status_code(code)
    if code.nil?
      return " - "
    else
      red_code = {
        '001' => "妊婦",
      }

      ref = []
      code.scan(/\d{3}/).each do |c|
        ref.push(red_code[c.to_s])
      end
      return "　" + ref.join(",")
    end
  end

  # 減免区分
  def reduction_code(code, mode="")
    if mode == "pre"
      red_code = {
        1 => "減額",
        2 => "免除",
        3 => "支払猶予",
      }
    else
      red_code = {
        1 => "(減額)",
        2 => "(免除)",
        3 => "(支払猶予)",
      }
    end
    return red_code[code.to_i].to_s
  end

  # 生活療養費標準負担額区分
  def life_division(code)
    life_codes = {
      1 => "低所得２",
      2 => "低所得２",
      3 => "低所得１",
      4 => "低所得１",
    }
    return life_codes[code.to_i].to_s
  end

  # 標準負担額 9桁コードチェック
  def amount_meal_check(code)
    ref_status = false
    meal_codes = [
      "197000810",
      "197001110",
      "197000910",
      "197001010",
      "197001910",
      "197002010",
      "197002110",
      "197002210",
      "197002310",
      "197002410",
      "197002510",
      "197002710",
      "197002810",
      "197002910",
      "197003010",
      "197003110",
      "197003210",
      "197003510",
      "197003310",
      "197003410",
      "197003610",
      "197003710",
      "197003810",
      "197003910",
      "197004010",
      "197004110",
      "197004210",
      "197004310",
      "197004410",
      "197004510",
      "197004610",
      "197004710",
      "197004810",
      "197004910",
      "197005010",
      "197005110",
      "197005210"
    ]
    meal_codes.each do |ccode|
      if code.to_s == ccode
        ref_status = true
        break
      end
    end
    return ref_status
  end

  # 算定日表示用 9桁コードチェック
  def santei_si_check(kbn, code)
    ref_status = false
    si_kbn = '50'
    si_codes = [
    ]
    #si_kbn = '12'
    #si_codes = [
    #  "111000110",
    #  "112007410",
    #]

    if si_kbn == kbn
      si_codes.each do |ccode|
        if code.to_s == ccode
          ref_status = true
          break
        end
      end
    end
    return ref_status
  end

  # 算定日表示用 '(算定日: 1-31日)'
  def santei_si_string_add(si_santei_string)
    si_santei_ex = si_santei_string.gsub(/,/, "日,").sub(/,$/, "")
    return "(算定日: #{si_santei_ex})".toeuc
  end

  # 特定区分のカウントチェック
  def kbn_number_of_time(kbn_no_group, kanja_data, index)
    if !kanja_data[index+1].nil?
      kbn_next = kanja_data[index+1]["sry_kbn"].to_s
    else
      kbn_next = "no_data"
    end

    kanja_data_q = kanja_data[index].dup
    kanja_data_q["futan_kbn"] = ""
    kanja_data_join = ""
    kanja_data_q.each do |key, val| kanja_data_join << val.to_s end
    kbn_no = kbn_no_group[0..1]
    flag = false

    # 注射: [31,32,33]
    # 処置: [40]
    kbn_list = [
      "31",
      "32",
      "33",
      "40",
    ]

    kbn_list.each do |klist|
      if kbn_no == klist && kbn_next == "" && !kanja_data_join.empty?
        kanja_queue = []
        kanja_data[index+1].each do |key, val|
          kanja_queue.push(val) if val.to_s != ""
        end
        if kanja_queue.size != 3
          flag = true
          break
        end
      end
    end
    flag
  end

  # 労災 イロハ 【イ】小計点数金額換算[RR]
  def rosai_rr_A_total(rr_record)
    return rr_record[17]
  end

  # 労災 イロハ 【ロ】小計金額[RR]
  def rosai_rr_B_total(rr_record)
    return rr_record[18]
  end

  # 労災 イロハ 【ハ】食事療養合計金額[RR]
  def rosai_rr_C_total(rr_record)
    return rr_record[20]
  end

  # 労災 イロハ 合計金額[RR]
  def rosai_rr_ABC_total(rr_record)
    return rr_record[17].to_i + rr_record[18].to_i + rr_record[20].to_i
  end

  # 労災 傷病年月日コード[RR]
  def rosai_rr_sickname(rr_record)
    return rr_record[6]
  end

  # 労災 転帰事由コード[RR]
  def rosai_rr_tenki(rr_record)
    return rr_record[8]
  end

  # 労災 入院年月日
  def rosai_re_hospital_days(re_record)
    return re_record[8]
  end

  # 労災 転帰事由コード
  def code2rosai_tenki(num)
    rr_red = {
      1 => "治ゆ",
      3 => "継続",
      5 => "転医",
      7 => "中止",
      9 => "死亡"
    }
    if num.class == Array
      return rr_red[rosai_rr_tenki(num).to_i].to_s
    else
      return rr_red[num.to_i].to_s
    end
  end

  # 労災 新継再別コード[RR]
  def rosai_rr_sinkei(rr_record)
    return rr_record[7]
  end

  # 労災 新継再別コード
  def code2rosai_sinkei(num)
    rr_red = {
      1 => "初診",
      3 => "転医始診",
      5 => "継続",
      7 => "再発"
    }
    if num.class == Array
      return rr_red[rosai_rr_sinkei(num).to_i].to_s
    else
      return rr_red[num.to_i].to_s
    end
  end

  # 労災 回数
  def code2rosai_number(num)
    if num.class == Array
      number = rosai_rr_number(num).to_s
    else
      number = num.to_s
    end
    return "第#{number}回"
  end

  # 労災 回数[RR]
  def rosai_rr_number(rr_record)
    return rr_record[1]
  end

  # 労災 業務災害,通勤災害コード
  def code2rosai_saigai(num,mode="")
    rr_red = {
      1 => "業務災害",
      3 => "通勤災害"
    }
    rr_red_rece = {
      1 => "ギョウム",
      3 => "ツウサイ"
    }
    if num.class == Array
      if mode == 'rece'
        return rr_red_rece[rosai_rr_saigai(num).to_i].to_s
      else
        return rr_red[rosai_rr_saigai(num).to_i].to_s
      end
    else
      if mode == 'rece'
        return rr_red_rece[num.to_i].to_s
      else
        return rr_red[num.to_i].to_s
      end
    end
  end

  # 労災 業務災害,通勤災害[RR]
  def rosai_rr_saigai(rr_record)
    return rr_record[2]
  end

  # 労災 帳票種別コード
  def code2rosai_formdoc(num, mode="")
    rr_red = {
      2 => "34702 診療費請求内訳書 (入院用)",
      3 => "34703 診療費請求内訳書 (入院外用)",
      4 => "34704 診療費請求内訳書 (入院用傷)",
      5 => "34705 診療費請求内訳書 (入院外用傷)"
    }
    rr_rece = {
      2 => "34702",
      3 => "34703",
      4 => "34704",
      5 => "34705"
    }
    if num.class == Array
      if mode == "rece"
        rr_rece[rosai_rr_formdoc(num).to_i].to_s
        return rr_rece[rosai_rr_formdoc(num).to_i].to_s
      else
        return rr_red[rosai_rr_formdoc(num).to_i].to_s
      end
    else
      if mode == "rece"
        return rr_rece[num.to_i].to_s
      else
        return rr_red[num.to_i].to_s
      end
    end
  end

  # 労災 労働基準監督署
  def code2rosai_kikan(num)
    if num.class == Array
      return rosai_rs_kikan(num)
    else
      return rosai_rs_kikan(num.split(/,/))
    end
  end

  # 労災 指定病院番号 [RS]
  def code2rosai_medical_icode(num)
    if num.class == Array
      return rosai_rs_medical_icode(num)
    else
      return rosai_rs_medical_icode(num.split(/,/))
    end
  end

  # 労災点数単価[RS]
  def code2rosai_rs_tensu_tanka(num)
    if num.class == Array
      return rosai_rs_tensu_tanka(num)
    else
      return rosai_rs_tensu_tanka(num.split(/,/))
    end
  end

  # 労災 指定病院番号 [RS]
  def rosai_rs_medical_icode(rs_record)
    return rs_record[5]
  end

  # 労災 帳票種別 [RR]
  def rosai_rr_formdoc(rr_record)
    return rr_record[3]
  end

  # 労災診療日変換 [RR]
  def rosai_rr_act_term(rr_record)
    return rr_record[9][0..-3]
  end

  # 労災診療日変換 入院年月日より [RE]
  def rosai_re_act_term(re_record)
    return re_record[8][0..-3]
  end

  # 労災診療日変換 [RE]
  def rosai_rs_kikan(rs_record)
    if !rs_record[3].to_s.empty? and !rs_record[4].to_s.empty?
      seikyu_kikan = rs_record[3].to_s + "1" + rs_record[4].to_s
    else
      seikyu_kikan = ""
    end
    return seikyu_kikan
  end

  # 労災点数単価[RS]
  # 1150[11.5円] or 1200[12.0円]
  def rosai_rs_tensu_tanka(rs_record)
    if /\d+/ =~ rs_record[9].to_s
      tanka = rs_record[9].to_s.to_f / 100.0
    else
      tanka = 0.0
    end
    return tanka
  end

  module_function :hoken2kouhi?
  module_function :kouhi_check_size?
  module_function :tenki_code2str
  module_function :sex_code2str
  module_function :code2hoken
  module_function :code2syouki
  module_function :code2kizai_unit
  module_function :code2ken
  module_function :code2sinryoka
  module_function :code2siharai_kikan
  module_function :code2sinryo_dic
  module_function :s2send_hoken
  module_function :comment_check
  module_function :code2hutan
  module_function :syusyoku_check
  module_function :minas_code
  module_function :osin_check
  module_function :medicine_type_check
  module_function :reason_on_duty
  module_function :reduction_code
  module_function :life_division
  module_function :amount_meal_check
  module_function :code2rosai_sinkei
  module_function :code2rosai_tenki
  module_function :code2rosai_saigai
  module_function :code2rosai_formdoc
  module_function :code2rosai_kikan
  module_function :rosai_rr_A_total
  module_function :rosai_rr_B_total
  module_function :rosai_rr_C_total
  module_function :rosai_rr_ABC_total
  module_function :rosai_rr_sickname
  module_function :rosai_rr_sinkei
  module_function :rosai_rr_tenki
  module_function :rosai_rr_saigai
  module_function :rosai_rr_formdoc
  module_function :rosai_rr_act_term
  module_function :rosai_re_act_term
  module_function :rosai_re_hospital_days
  module_function :rosai_rs_kikan
  module_function :rosai_rs_medical_icode
  module_function :rosai_rs_tensu_tanka
end

