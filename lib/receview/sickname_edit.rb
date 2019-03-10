# -*- encoding: utf-8 -*-

require 'jma/receview/generation'

class ReceView_ByomeiMake
  require 'kconv'
  require 'date'
  require 'jma/receview/strconv'
  require 'jma/receview/dbslib'
  require 'jma/receview/dbfile_lib'

  CANDIDATE1 = 0
  CANDIDATE2 = 1

  def initialize
    @db = nil
    @db_stat = nil
    @db_host = "localhost"
    @db_user = "user"
    @db_pass = "pass"
    @status = []
  end

  def con
    if @db.class == ReceView_DBFile
      @db_stat = ""
    elsif @db.class == DBSclient
      begin
        @db_stat = @db.con(@db_host, @db_user, @db_pass)
      rescue
        @db_stat = @db.ex_error
      end
    else
      @db_stat = "non"
    end
    return @db_stat
  end

  # 入力病名解体 [推奨病名:proper]
  def sickname_list(name, proper=false)
    sicknames = []
    if proper
      list = []
      sick_a = name.split(//)

      sick_a.size.times do ||
        sickname = ""
        sick_a.each do |str|
          sickname += str
          list.push(sickname)
        end
        sick_a.shift
      end
      sicknames = list.uniq
    else
      list   = []
      str_c  = []
      str_s  = ""
      if name.size >= 1
        name_arr = name.split(//)
        name_arr.each_with_index do |str, i|
          str_c.push(str)
          str_s = str_s + str
          if !list.include?(str)
            list.push(str)
          end
          if !list.include?(str_s)
            list.push(str_s)
          end
        end
        str_c[0] = ""
        list.concat(self.sickname_list(str_c.join))
      end
      sicknames = list.uniq.sort
    end
    return sicknames
  end

  # 配列utf8を配列eucへ
  def arr_utf2euc(arr)
    out_arr = []
    if arr.class == Array
      arr.each do |tmp|
        out_arr.push(NKF.nkf("-We", tmp))
      end
    else
      out_arr = arr
    end
    return out_arr
  end

  def make_receden(raw_code, make_code, sick, sick_sub)
    at_sy = raw_code.split(/,/, -1)

    at_sy[1] = ""
    at_sy[4] = ""
    at_sy[7] = sick_sub
    make_code.each do |code|
      if /^ZZZ/ =~ code
        at_sy[4]+= code.sub(/^ZZZ/, "")
      else
        at_sy[1] = code
      end
    end
    if at_sy[1] == "0000999"
      at_sy[5] = sick
    else
      at_sy[5] = ""
    end
    return at_sy.join(",")
  end

  # 病名コード数
  def disease_check(code_list)
    byomei_level = 0
    code_list.each do |name, code, size, index, etc_data|
      byomei_level+=1 if /^[0-9]+/ =~ code
    end
    return byomei_level
  end

  # 病名 接頭語,接尾語コード短縮 [ZZZxxxx]
  def sickname_prefix_marge(byomeis, byomei_list)
    byomeis.each do |blist|
      (blist.size-1).times do |i|
        if !blist[i].to_s.empty? and !blist[i+1].to_s.empty?
          if /^ZZZ/ =~ blist[i][1] and /^ZZZ/ =~ blist[i+1][1]
            byomei_list.each do |tname, tcode, tetc_data|
              if tname == (blist[i][0] + blist[i+1][0])
                blist[i][0] = tname
                blist[i][1] = tcode
                blist[i][2] = tname.split(//).size
                blist[i][3] = blist[i][3] + blist[i+1][3]
                blist[i][4] = tetc_data
                blist.delete_at(i+1)
              end
            end
          end
        end
      end
    end
    return byomeis
  end

  # サイズから病名組み立て
  def byomeicd_make(byomei_raw, byomei_list)
    b_size = [],[]
    purge_sickname = []

    byomei_list.each do |name, code, etc_data|
      purge_sickname.push(name) if name.split(//).size == 1
      if !etc_data.empty?
        if etc_data["ikosakiname"].empty?
          b_size[CANDIDATE2].push([name, code, name.split(//).size, etc_data])
        else
          b_size[CANDIDATE1].push([name, code, name.split(//).size, etc_data])
          b_size[CANDIDATE2].push([name, code, name.split(//).size, etc_data])
        end
      else
        b_size[CANDIDATE1].push([name, code, name.split(//).size, etc_data])
        b_size[CANDIDATE2].push([name, code, name.split(//).size, etc_data])
      end
    end

    byomei = [],[]
    b_size.each_with_index do |old_byomei, index|
      old_byomei.sort { |a, b| a[2] <=> b[2] }.each do |sick_data|
        nflg = true
        purge_sickname.each do |text|
          if /#{text}$/ =~ sick_data[0].to_s and sick_data[0].split(//).size == 2
            nflg = false
          end
        end
        byomei[index].push(sick_data) if nflg
      end
    end

    pre_bname = ""
    r_byomei = [],[]
    byomei.each_with_index do |byomei_p, bindex|
      sp = ""
      pre_bname = byomei_raw
      byomei_p.reverse.each do |name, code, size, etc_data|
        name_size = name.split(//).size
        name_size.times { sp << "＠"}
        byomei_cat = pre_bname

        while pre_bname.sub(/#{name}/, sp) != pre_bname
          byomei_cat = pre_bname
          pre_bname = pre_bname.sub(/#{name}/, sp)
          if pre_bname != byomei_cat
            index = ((byomei_cat.index(/#{name}/).to_i) / 3)
            r_byomei[bindex].push([name, code, size, index, etc_data])
          end
        end
        sp = ""
      end
    end

    byomei.each_with_index do |byomei_p, bindex|
      d_tmp = ""
      d_size  = 0
      d_index = 0
      (pre_bname+"＠").split(//).each_with_index do |d, i|
        if d != "＠"
          d_index = i if d_tmp == ""
          d_tmp = d_tmp + d
          d_size += 1
        end
        if (d == "＠" or d == "") and !d_tmp.empty?
          r_byomei[bindex].push([d_tmp, "0000999", d_size, d_index])
          d_tmp = ""
          d_size = 0
        end
      end
    end
    r_byomei.each { |ryomei| ryomei.sort! { |a, b| a[3] <=> b[3] } }
    return sickname_prefix_marge(r_byomei, byomei_list)
  end

  # 必要な病名を取得
  def get_sickname(find_aext, ym="")
    if ym.to_s.empty?
      year = Date.today.year.to_s
      mon  = Date.today.month.to_s
      mon = "0" + mon if mon.size == 1
      ym = year + mon
    end

    db = @db
    byomei = []

    db_byomei = Hash.new(nil)
    db_byomei= {
      :record => "tbl_byomei",
      :key    => "jrvpkey1",
      :count  => "50",
      :query  => {
        "byomeicds" => [find_aext],
      },
    }

    d = []
    begin
      db.transaction do ||
        db.select(db_byomei)
        d = db.fetch(db_byomei)
        d.each do |tmp|
          code = tmp["byomeicd"][:value].to_s
          name = tmp["byomei"][:value].to_s
          byomei.push([fix_utf8(name), code])
        end
      end
    rescue
    end
    return byomei
  end

  # 必要な病名コードを取得
  def get_sickcode(find_aext, ym="")
    if ym.to_s.empty?
      year = Date.today.year.to_s
      mon  = Date.today.month.to_s
      mon = "0" + mon if mon.size == 1
      ym = year + mon
    end

    db = @db
    byomei = []

    vercode = db.version.gsub(/\./, "0").to_s
    if (vercode == "10404") or (vercode == "10403") or (vercode == "file")
      find_aext = self.arr_utf2euc(find_aext)
    end

    db_byomei = Hash.new(nil)
    db_byomei= {
      :record => "tbl_byomei",
      :key    => "jrvpkey2",
      :count  => "50",
      :query  => {
        "byomeis" => find_aext,
      },
    }

    d = []
    begin
      db.transaction do ||
        db.select(db_byomei)
        d = db.fetch(db_byomei)
        d.each do |tmp|
          code = tmp["byomeicd"][:value].to_s
          name = tmp["byomei"][:value].to_s
          haisiymd  = tmp["haisiymd"][:value].to_s
          ikosakicd = tmp["ikosakicd"][:value].to_s.gsub(/ +/, "")
          etc_data  = {}

          ymd = ym.to_s + month2endday(ym).to_s
          if !ikosakicd.to_s.empty?
            ikosakiname = ""
            self.con
            self.get_sickname(ikosakicd).each do |next_name, next_code|
              ikosakiname = next_name
              ikosakicd   = next_code
            end
            etc_data = {
              "ikosakiname" => ikosakiname,
              "ikosakicd" => ikosakicd,
              "haisiymd" => haisiymd
            }
          else
            if ymd.to_i >= haisiymd.to_i
              ikosakiname = ""
              self.con
              self.get_sickname(ikosakicd).each do |next_name, next_code|
                ikosakiname = next_name
                ikosakicd   = next_code
              end
              ikosakiname = ""
              ikosakicd   = "0000000"
              etc_data = {
                "ikosakiname" => ikosakiname,
                "ikosakicd" => ikosakicd,
                "haisiymd" => haisiymd
              }
            else
              ikosakiname = ""
              ikosakicd   = "0000000"
            end
          end
          byomei.push([fix_utf8(name), code, etc_data])
        end
      end
    rescue
    end
    return byomei
  end

  attr_accessor :db
  attr_accessor :db_stat
  attr_accessor :db_host
  attr_accessor :db_user
  attr_accessor :db_pass
  attr_reader   :status
end

if __FILE__ == $0
end
