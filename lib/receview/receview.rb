# -*- encoding: utf-8 -*-

require 'jma/receview/generation'

class ReceModelData
  attr_accessor :old_general_hospital
  attr_accessor :status

  attr_accessor :raw_receden
  attr_accessor :org_receden
  attr_accessor :now_receden
  attr_accessor :now_raw_receden

  attr_accessor :raw_receden_arr
  attr_accessor :record
  attr_accessor :record_array

  attr_accessor :raw_ir_record
  attr_accessor :raw_rr_record
  attr_accessor :raw_re_record
  attr_accessor :raw_re_hen_record

  attr_accessor :user_index
  attr_accessor :ir_header
  attr_accessor :ir_record
  attr_accessor :re_all_index
  attr_accessor :re_all_record

  attr_accessor :re_index
  attr_accessor :re_index_h
  attr_accessor :re_hen_index
  attr_accessor :re_hen_index_h

  attr_accessor :uniq_count_no

  RECE_NON = 0
  RECE_IKANML = 1
  RECE_IKAHEN = 2
  RECE_ROSAI = 3
  RECE_ROHEN = 4

  ROSAI_34702 = 2 
  ROSAI_34703 = 3
  ROSAI_34704 = 4 
  ROSAI_34705 = 5

  RECEDEN_IR_FAKE = "IR,,,,,,,,00,,"
  RECEDEN_RS_FAKE = "RS,,,,,,,,,,,,99"
  RECEDEN_EOF = "\032"

  def initialize
    # レセ電ファイルステータス
    # 1:医科レセ, 2:返戻医科レセ, 3:労災レセ, 4:返戻労災レセ
    @receden_pt = 0

    # @receden_record to add
    @raw_receden = ""

    # @receden_record Original
    @org_receden = ""

    # dayning
    @now_receden = ""
    @now_raw_receden = ""

    @raw_receden_arr = []

    # [HI,HG] to [IR,GO]
    @record = ""

    # @receden_record array
    @record_array = []

    # @receden_record and fix henrei
    @raw_array_flatten = []

    # raws
    @raw_ir_record = []
    @raw_rr_record = []
    @raw_re_record = []
    @raw_re_hen_record = []

    @user_index = {}

    @ir_record = []
    @re_all_record = []
    @re_all_index = []

    @re_index = []
    @re_index_h = {}
    @re_hen_index = []
    @re_hen_index_h = {}

    @ir_header = []

    @receden_mode = 99
    @receden_mode_old = 99
    @receden_mode_error = 0

    @receden_filename = ""

    # マルチボリューム 最大値候補
    @max_volume_candidate = 0

    # マルチボリューム 最大値
    @max_volume = 0

    # GOレコード件数,点数
    @go_number = 0
    @go_point = 0

    # レセ電 合計人数,件数,点数,金額
    @sum_number_people = 0
    @sum_number_case = 0
    @sum_number_point = 0
    @sum_number_money = 0

    # 参照先が同じデータ [実態:true, 参照:false]
    @user_koui_SubStance = []

    # ユーザごとのレセ電データIndex
    @user_koui_LineIndex = []

    # IRヘッダのチェック
    @uniq_count_no = []

    # 請求年月日
    @sry_act_term = ""

    # 医療機関番号 (Not JPNxNumber)
    @hospid = ""

    # 初期化フラグ
    @format = false

    @old_general_hospital = nil
    @status = nil
  end

  def clear
  end

  def set_format(flg=true)
    @format = flg
  end

  def format
    @format
  end

  def get_receden_pt
    @receden_pt
  end

  def set_receden_pt(int)
    @receden_pt = int.to_i
  end

  def old_general_hospital?(ghosp_id)
    if ghosp_id.to_s.empty?
      # "通常病院"
      @old_general_hospital = false
    else
      # "旧総合病院"
      @old_general_hospital = true
    end
    return
  end

  def add_receden(rData)
    @org_receden << rData
  end

  def add_raw_receden(rData)
    @raw_receden << rData
  end

  def set_now_receden(nowRdata)
    @now_receden = nowRdata
  end

  def set_now_raw_receden(nowRdata)
    @now_raw_receden = nowRdata
  end

  def make_record
    @record << @now_receden.to_s
  end

  def make_record_array
    @record_array = @record.split(/\n/)
  end

  def record_array_flatten_henrei
    if @raw_array_flatten.size == 0
      @record_array.each do |t|
        @raw_array_flatten.push(t.gsub(/^(\d+,){3}/, ""))
      end
    end
    return @raw_array_flatten
  end

  # レセ電ファイルモード検出 
  def receden_mode(csvdata)
    no,gno,mode,status = 0,0,0,0
    top = 0
    cdata = []

    while !csvdata[no].to_s.empty?
      cdata = csvdata[no].split(/\s*,\s*/)
      case cdata[top]
      when "IR"
        if !@old_general_hospital
          cdata[0] = ""
          @ir_header.push(cdata.join.chop!)
        end
        @ir_record[gno] = csvdata[no]
        if cdata[5].to_s.empty?
          if cdata[8].to_i == 0
            if /^[a-zA-Z]/ =~ csvdata[-1]
              if csvdata[-1].nil?
                @receden_mode_error = 8
                mode = 0
                break
              else
                if /^GO,/ =~ csvdata[-1]
                  if csvdata[-1].split(/,/).size == 4
                    if csvdata[-1].split(/\s*,\s*/)[3].chop == "99"
                      mode = 0
                      break
                    else
                      mode = 2
                      break
                    end
                  elsif csvdata[-1].split(/,/).size > 4
                    if csvdata[-1].split(/\s*,\s*/)[12].chop == "99"
                      if /^#{ReceModelData::RECEDEN_RS_FAKE.sub(/RS/, "GO")}\S*/ =~ csvdata[-1]
                        @receden_pt = 4
                        mode = 0
                        break
                      else
                        @receden_pt = 3
                        mode = 0
                        break
                      end
                    else
                      mode = 2
                      break
                    end
                  else
                    @receden_mode_error = 9
                    mode = 0
                    break
                  end
                else
                  @receden_mode_error = 8
                  mode = 0
                  break
                end
              end
            else
              break
            end
          else
            mode = 2
            break
          end
        else
          if cdata[8].to_i == 0
            mode = 1
          else
            status = 1
            mode = 3
          end
        end
      when "GO"
        case mode
        when 0
          if cdata[3].chop == "99"
            mode = 0
          else
            mode = 2
          end
        when 1
          if cdata[3].chop == "99"
            mode = 1
          else
            mode = 3
          end
        when 2
          if cdata[3].chop == "99"
            mode = 2
          else
            mode = 2
          end
        when 3
          if cdata[3].chop == "99"
            if (csvdata[no].to_s.empty?) and (status == 1)
              mode = 3
            end
          else
            mode = 3
          end
        end
        gno+=1
      end
      no+=1
    end
    @receden_mode = mode
  end

  def set_receden_mode(mode)
    @receden_mode = mode
  end

  def get_receden_mode
    @receden_mode
  end

  def move_receden_mode
    @receden_mode_old = @receden_mode
  end

  def back_receden_mode
    @receden_mode = @receden_mode_old
  end

  def get_receden_mode_old
    @receden_mode_old
  end

  # 比べる new | old
  def check_receden_mode
    if @receden_mode_old == @receden_mode
      true
    else
      false
    end
  end

  # 0 = non
  # 1 = 新規登録
  # 3 = 他のボリューム
  # 4 = すでに登録済
  # 5 = 
  # 6 = 
  # 7 = 
  # 8 = GOレコードなし
  # 9 = GOレコード破損
  def set_receden_status(status)
    @receden_mode_error = status
  end

  def get_receden_status
    @receden_mode_error
  end

  def set_receden_filename(file)
    @receden_filename = file
  end

  def get_receden_filename
    @receden_filename
  end

  def update_max_volume
    @max_volume = @max_volume_candidate
  end

  def get_max_volume
    @max_volume
  end

  def set_max_volume_rc(volume)
    @max_volume_candidate = volume.to_i
  end

  def get_max_volume_rc
    @max_volume_candidate
  end

  def set_go_ken(no)
    @go_number = no.to_s
  end

  def get_go_ken
    @go_number
  end

  def set_go_ten(point)
    @go_point = point.to_s
  end

  def get_go_ten
    @go_point
  end

  def add_sum_Npeople(add_point)
    @sum_number_people += add_point.to_i
  end

  def sum_Npeople_format
    @sum_number_people = 0
  end

  def sum_Npeople
    @sum_number_people
  end

  def sum_Ncase
   @sum_number_case
  end

  def add_sum_Npoint(add_point)
    @sum_number_point += add_point.to_i
  end

  def sum_Npoint_format
    @sum_number_point = 0
  end

  def sum_Npoint
    @sum_number_point
  end

  def add_sum_Nmoney(add_point)
    @sum_number_money += add_point.to_i
  end

  def sum_Nmoney_format
    @sum_number_money = 0
  end

  def sum_Nmoney
    @sum_number_money
  end

  # sum_n*_[n|p]が全てない
  def sum_NCPP
    if @sum_number_people.to_s.empty? and 
      @sum_number_case.to_s.empty? and @sum_number_point.to_s.empty?
      true
    else
      false
    end
  end

  def check_go_record(record)
    arr_record = record.split(/,/)
    if check_go_record_size(arr_record)
      if check_go_record_data(arr_record)
        true
      else
        false
      end
    else
      false
    end
  end

  def check_go_record_data(record)
    cflag = 0
    if record[0] == 'GO'
      cflag += 1
    end
    if /\d+/ =~ record[1]
      cflag += 2
    end
    if /\d+/ =~ record[2]
      cflag += 4
    end
    if /\d+/ =~ record[3]
      cflag += 8
    end
    if cflag == 15
      true
    else
      false
    end
  end

  def check_go_record_size(record)
    if record.size == 4
      true
    else
      false
    end
  end

  # ユーザレセ電コード参照フラグ
  def User_SubStance_init
    @user_koui_SubStance = []
  end

  def User_SubStance_add(array_no)
    @user_koui_SubStance.push(array_no)
  end

  def User_SubStance(array_no)
    @user_koui_SubStance[array_no]
  end

  # ユーザ診療行為データインデックス
  def User_LineDataIndex_init
    @user_koui_LineIndex = []
  end

  def User_LineDataIndex_add(array_no)
    @user_koui_LineIndex.push(array_no)
  end

  def User_LineDataIndex(array_no)
    @user_koui_LineIndex[array_no]
  end

  # ユーザ傷病名データインデックス
  def User_LineSickIndex_init
    @user_sick_LineIndex = []
  end

  def User_LineSickIndex_add(array_no)
    @user_sick_LineIndex.push(array_no)
  end

  def User_LineSickIndex_rep(array_no, data)
    @user_sick_LineIndex[array_no] = data
  end

  def User_LineSickIndex(array_no)
    @user_sick_LineIndex[array_no]
  end

  # ユーザ傷病名データ
  def User_SickList_init
    @user_sicklist = []
  end

  def User_SickList_add(array_no)
    @user_sicklist.push(array_no)
  end

  def User_SickList_rep(array_no, data)
    @user_sicklist[array_no] = data
  end

  def User_SickList(array_no)
    @user_sicklist[array_no]
  end

  # ユーザ診療行為データ
  def User_LineData_init
    @user_koui_Line = []
  end

  def User_LineData_add(array_no)
    @user_koui_Line.push(array_no)
  end

  def User_LineData(array_no)
    @user_koui_Line[array_no]
  end

  def get_hospid
    if @hospid.empty?
      tag = '%'
      id = [nil, @ir_record[0].to_s.split(/,/)[2].to_s, nil]
      @hospid = id.join(tag)
    end
    return @hospid
  end

  def get_sry_act_term
    if @sry_act_term.empty?
      @record_array.each do |rlist|
        list = rlist.gsub(/^(\d+,){3}/, "")
        if /^IR,/ =~ list
          code = list.split(/,/)
          @sry_act_term = wa2sei(code[7].to_s).to_s
          break
        end
      end
    end
    return @sry_act_term
  end

  def rosai?
    case get_receden_pt
    when ReceModelData::RECE_ROSAI, ReceModelData::RECE_ROHEN
      return true
    else
      return false
    end
  end
end

