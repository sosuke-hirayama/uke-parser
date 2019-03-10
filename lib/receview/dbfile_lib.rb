# -*- encoding: utf-8 -*-

require 'jma/receview/generation'

class ReceView_DBFile
  require 'date'
  require 'jma/receview/base'
  require 'jma/receview/strconv'

  attr_reader :ex_error
  attr_reader :all_error
  attr_reader :dbfile
  attr_reader :tbl_list
  attr_reader :index_tbl
  attr_reader :endex_tbl
  attr_reader :column
  attr_reader :version
  attr_accessor :ymd
  attr_accessor :oymd
  attr_accessor :dir_path
  attr_accessor :read_to
  attr_accessor :index_size

  def initialize
    @version = "1.4.3"
    @base = ReceView_Base.new
    @path_char = @base.path_char
    @ex_error = ""
    @all_error = []
    @transaction_stat = false

    @dbfile = {}
    @column = {}
    @filelist = {}
    @ymd = self.nowymd
    @oymd = self.oldymd

    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      @dir_path = "share" + @path_char
    else
      @dir_path = ""
    end
    @dir_path += "db" + @path_char

    install_path = @base.get_path
    home_drive   = ENV['HOMEDRIVE'].to_s

    @abslute_paths = [
      "",
      "db" + @path_char,
      ["share", "db", ""].join(@path_char),
      ["", "share", "local", "share", "jma-receview", ""].join(@path_char),
      ["", "usr", "share", "jma-receview", ""].join(@path_char),
      home_drive + @path_char,
      [install_path, "db"].join(@path_char),
      [install_path, "share", "db"].join(@path_char),
    ]

    # "file" or "memory"
    @read_to = "memory"
    
    @index_size = 8

    @index_tbl = {}
    @endex_tbl = {}

    @tbl_list= [
      "tbl_tensu",
      "tbl_byomei",
      "tbl_hknjainf",
      "tbl_labor_sio",
      "tbl_dbkanri",
      "tbl_syskanri"
    ]

    @tbl_list.each do |tbl|
      @dbfile[tbl] = []
      @column[tbl] = []
    end

    @column["tbl_tensu"].push(
      "hospnum",
      "srycd",
      "name",
      "tanicd",
      "yukostymd",
      "yukoedymd",
      "sstkijuncd1",
      "sstkijuncd2",
      "sstkijuncd3",
      "sstkijuncd4",
      "sstkijuncd5",
      "sstkijuncd6",
      "sstkijuncd7",
      "sstkijuncd8",
      "sstkijuncd9",
      "sstkijuncd10",
      "gaitenttlkbn",
      "nyutenttlkbn"
    )

    @column["tbl_byomei"].push(
      "byomei",
      "byomeicd",
      "haisiymd",
      "ikosakicd"
    )

    @column["tbl_hknjainf"].push(
      "hknjaname",
      "hknjanum",
      "hospnum"
    )

    @column["tbl_labor_sio"].push(
      "syocd",
      "yukostymd",
      "yukoedymd",
      "name"
    )

    @column["tbl_dbkanri"].push(
      "kanricd",
      "version",
      "dbsversion1",
      "dbsversion2",
      "termid",
      "opid",
      "creymd",
      "upymd",
      "upshms"
    )

    @column["tbl_syskanri"].push(
      "kanricd",
      "kbncd",
      "styukymd",
      "edyukymd",
      "kanritbl",
      "termid",
      "opid",
      "creymd",
      "upymd",
      "uphmd",
      "hospnum"
    )
  end

  def make_completion_model(tbl, comp_model, db_path)
    begin
      case tbl
      when "sickname"
        byomei_file = self.absolute_path(db_path) + "tbl_byomei.rdb"
        if RUBY_VERSION.to_s <= "1.8.7"
          open(byomei_file) do |csvdata|
            csvdata.read.split(/\n/).gtk_each do |v|
              vv = v.split(/,/)
              if vv[2] == "99999999"
                iter = comp_model.append
                iter[0] = vv[0].toutf8
              end
            end
          end
        else
          open(byomei_file, "r:euc-jp:utf-8") do |csvdata|
            csvdata.read.split(/\n/).gtk_each do |v|
              vv = v.split(/,/)
              if vv[2] == "99999999"
                iter = comp_model.append
                iter[0] = vv[0].toutf8
              end
            end
          end
        end
      when "sickname_prefix"
      end
    rescue
      comp_model
    end
    return comp_model
  end

  def absolute_path(path="")
    path += @path_char if path.split(//).last != @path_char
    p_stat = false
    ab_path = ""
    @abslute_paths.each do |bp|
      t_stat = 0
      if File.exist?(bp+path)
        @tbl_list.each do |tl|
          if !File.exist?(bp+path+tl+".rdb")
            t_stat += 1
          end
        end
        if t_stat == 0
          p_stat = true
          ab_path = bp+path
          break
        end
      elsif File.exist?(bp)
        @tbl_list.each do |tl|
          if !File.exist?(bp+tl+".rdb")
            t_stat += 1
          end
        end
        if t_stat == 0
          p_stat = true
          ab_path = bp
          break
        end
      end
      break if p_stat
    end
    ab_path = ["share", "db", ""].join(@path_char) if ab_path == ""
    return ab_path
  end

  def con(dir_path="db"+@path_char)
    @dir_path = absolute_path(dir_path)
    stat = ""
    begin
      self.column.each do |db_list|
        tbl_name = db_list[0].to_s
        file_path = @dir_path + tbl_name + ".rdb"

        if File.exist?(file_path)
          fmode = "%o" % File::stat(file_path).mode
          fmode.slice(3, 5).split(//).each do |m|
            if m.to_i <= 3
              stat = "Permission denied: #{tbl_name}"
              @all_error.push(stat)
              break
            end
          end
          @filelist[tbl_name] = file_path
          @index_tbl[tbl_name] = {}
          @endex_tbl[tbl_name] = {}
        else
          stat = "File not found: #{tbl_name}"
          @all_error.push(stat)
        end
      end
    rescue
      stat = "connection"
      @all_error.push(stat)
    end
    self.error(stat) if !stat.empty?
    return stat
  end

  def close(mode="")
    return true
  end

  def search_file(tbl, key, value, mode="dbs")
    file_path = @filelist[tbl]
    if File.exist?(file_path)
      ref = []
      File.open(file_path, "r:euc-jp:utf-8").read.toeuc.split(/\n/).each do |data|
        data_split = data.split(/,/)
        db_hash = {}
        ref_t = ""

        @column[tbl].each_with_index do |frm, index|
          db_hash[frm] = data_split[index]
        end
 
        ref_t = self.search_file_sub(db_hash, tbl, key, value, mode="dbs")
        if !ref_t.to_s.empty?
          ref_t.each do |ref_array|
            ref.push(ref_array)
          end
          if !value["srycds"].to_s.empty?
            break if value["srycds"].size == ref.size
          elsif !value["byomeicds"].to_s.empty?
            break if value["byomeicds"].size == ref.size
          end
        end
      end
      return ref
    else
      stat = "File not found: #{File.basename(file_path)}"
      @all_error.push(stat)
      # @all_error.push("Searching error")
      # self.error("Searching error")
    end
  end

  def search_file_sub(db_hash, tbl, key, value, mode="dbs")
    out_data = []
    dbs_hash = {}
    case tbl
    when "tbl_tensu"
      case key
      when "key1"
        v_name = value["name"]
        v_hospnum = value["hospnum"]

        d_name  = db_hash["name"].to_s
        d_srycd = db_hash["srycd"].to_s
        d_yukostymd = db_hash["yukostymd"].to_i
        d_yukoedymd = db_hash["yukoedymd"].to_i
        d_hospnum = db_hash["hospnum"].to_s

        if /#{v_name}/ =~ d_name and d_hospnum == v_hospnum
          name  = d_name
          srycd = d_srycd
          yukostymd = d_yukostymd
          yukoedymd = d_yukoedymd

          if mode == "dbs"
            dbs_hash = {}
            dbs_hash["srycd"] = {:value => srycd}
            dbs_hash["name"] = {:value => name}
            dbs_hash["yukostymd"] = {:value => yukostymd}
            dbs_hash["yukoedymd"] = {:value => yukoedymd}
            out_data.push(dbs_hash)
          else
            out_data.push(srycd, name, yukostymd, yukoedymd)
          end
        end
      when "jrvpkey1"
        v_srycds = value["srycds"]
        v_yukostymd = value["yukostymd"].to_i
        v_yukoedymd = value["yukoedymd"].to_i
        v_hospnum = value["hospnum"]

        d_name  = db_hash["name"].to_s
        d_srycd = db_hash["srycd"].to_s
        d_tanicd = db_hash["tanicd"].to_s
        d_yukostymd = db_hash["yukostymd"].to_i
        d_yukoedymd = db_hash["yukoedymd"].to_i
        d_sstkijuncd = []
        d_sstkijuncd.push(db_hash["sstkijuncd1"].to_s)
        d_sstkijuncd.push(db_hash["sstkijuncd2"].to_s)
        d_sstkijuncd.push(db_hash["sstkijuncd3"].to_s)
        d_sstkijuncd.push(db_hash["sstkijuncd4"].to_s)
        d_sstkijuncd.push(db_hash["sstkijuncd5"].to_s)
        d_sstkijuncd.push(db_hash["sstkijuncd6"].to_s)
        d_sstkijuncd.push(db_hash["sstkijuncd7"].to_s)
        d_sstkijuncd.push(db_hash["sstkijuncd8"].to_s)
        d_sstkijuncd.push(db_hash["sstkijuncd9"].to_s)
        d_sstkijuncd.push(db_hash["sstkijuncd10"].to_s)
        d_gaitenttlkbn = db_hash["gaitenttlkbn"].to_s
        d_nyutenttlkbn = db_hash["nyutenttlkbn"].to_s
        d_hospnum = db_hash["hospnum"].to_s

        v_srycds.gtk_each do |v_srycd|
          if d_srycd == v_srycd and d_hospnum == v_hospnum
            if d_yukostymd <= v_yukostymd
              if d_yukoedymd >= v_yukoedymd
                name  = d_name
                srycd = d_srycd
                tanicd = d_tanicd
                yukostymd = d_yukostymd
                yukoedymd = d_yukoedymd
                sstkijuncd1 = d_sstkijuncd[0]
                sstkijuncd2 = d_sstkijuncd[1]
                sstkijuncd3 = d_sstkijuncd[2]
                sstkijuncd4 = d_sstkijuncd[3]
                sstkijuncd5 = d_sstkijuncd[4]
                sstkijuncd6 = d_sstkijuncd[5]
                sstkijuncd7 = d_sstkijuncd[6]
                sstkijuncd8 = d_sstkijuncd[7]
                sstkijuncd9 = d_sstkijuncd[8]
                sstkijuncd10 = d_sstkijuncd[9]
                gaitenttlkbn = d_gaitenttlkbn
                nyutenttlkbn = d_nyutenttlkbn
                hospnum = d_hospnum

                if mode == "dbs"
                  dbs_hash = {}
                  dbs_hash["srycd"] = {:value => srycd}
                  dbs_hash["name"] = {:value => name}
                  dbs_hash["tanicd"] = {:value => tanicd}
                  dbs_hash["yukostymd"] = {:value => yukostymd}
                  dbs_hash["yukoedymd"] = {:value => yukoedymd}
                  dbs_hash["sstkijuncd1"] = {:value => sstkijuncd1}
                  dbs_hash["sstkijuncd2"] = {:value => sstkijuncd2}
                  dbs_hash["sstkijuncd3"] = {:value => sstkijuncd3}
                  dbs_hash["sstkijuncd4"] = {:value => sstkijuncd4}
                  dbs_hash["sstkijuncd5"] = {:value => sstkijuncd5}
                  dbs_hash["sstkijuncd6"] = {:value => sstkijuncd6}
                  dbs_hash["sstkijuncd7"] = {:value => sstkijuncd7}
                  dbs_hash["sstkijuncd8"] = {:value => sstkijuncd8}
                  dbs_hash["sstkijuncd9"] = {:value => sstkijuncd9}
                  dbs_hash["sstkijuncd10"] = {:value => sstkijuncd10}
                  dbs_hash["gaitenttlkbn"] = {:value => gaitenttlkbn}
                  dbs_hash["nyutenttlkbn"] = {:value => nyutenttlkbn}
                  dbs_hash["hospnum"] = {:value => hospnum}
                  out_data.push(dbs_hash)
                else
                  out_data.push(
                    srycd,
                    name,
                    tanicd,
                    yukostymd,
                    yukoedymd,
                    sstkijuncd1,
                    sstkijuncd2,
                    sstkijuncd3,
                    sstkijuncd4,
                    sstkijuncd5,
                    sstkijuncd6,
                    sstkijuncd7,
                    sstkijuncd8,
                    sstkijuncd9,
                    sstkijuncd10,
                    gaitenttlkbn,
                    nyutenttlkbn,
                    hospnum
                  )
                end
              end
            end
          end
        end
      when "jrvpkey2"
        v_srycds = value["srycds"]
        v_yukostymd = value["yukostymd"].to_i
        v_yukoedymd = value["yukoedymd"].to_i
        v_hospnum = value["hospnum"]

        d_name  = db_hash["name"].to_s
        d_srycd = db_hash["srycd"].to_s
        d_yukostymd = db_hash["yukostymd"].to_i
        d_yukoedymd = db_hash["yukoedymd"].to_i
        d_tanicd = db_hash["tanicd"].to_s
        d_sstkijuncd = []
        d_sstkijuncd.push(db_hash["sstkijuncd1"].to_s)
        d_sstkijuncd.push(db_hash["sstkijuncd2"].to_s)
        d_sstkijuncd.push(db_hash["sstkijuncd3"].to_s)
        d_sstkijuncd.push(db_hash["sstkijuncd4"].to_s)
        d_sstkijuncd.push(db_hash["sstkijuncd5"].to_s)
        d_sstkijuncd.push(db_hash["sstkijuncd6"].to_s)
        d_sstkijuncd.push(db_hash["sstkijuncd7"].to_s)
        d_sstkijuncd.push(db_hash["sstkijuncd8"].to_s)
        d_sstkijuncd.push(db_hash["sstkijuncd9"].to_s)
        d_sstkijuncd.push(db_hash["sstkijuncd10"].to_s)
        d_hospnum = db_hash["hospnum"]

        v_srycds.gtk_each do |v_srycd|
          if d_srycd == v_srycd and d_hospnum == v_hospnum
            if d_yukostymd <= v_yukostymd
              if d_yukoedymd >= v_yukoedymd
                name  = d_name
                srycd = d_srycd
                tanicd = d_tanicd
                sstkijuncd1 = d_sstkijuncd[0]
                sstkijuncd2 = d_sstkijuncd[1]
                sstkijuncd3 = d_sstkijuncd[2]
                sstkijuncd4 = d_sstkijuncd[3]
                sstkijuncd5 = d_sstkijuncd[4]
                sstkijuncd6 = d_sstkijuncd[5]
                sstkijuncd7 = d_sstkijuncd[6]
                sstkijuncd8 = d_sstkijuncd[7]
                sstkijuncd9 = d_sstkijuncd[8]
                sstkijuncd10 = d_sstkijuncd[9]

                if mode == "dbs"
                  dbs_hash = {}
                  dbs_hash["srycd"] = {:value => srycd}
                  dbs_hash["name"] = {:value => name}
                  dbs_hash["tanicd"] = {:value => tanicd}
                  dbs_hash["sstkijuncd1"] = {:value => sstkijuncd1}
                  dbs_hash["sstkijuncd2"] = {:value => sstkijuncd2}
                  dbs_hash["sstkijuncd3"] = {:value => sstkijuncd3}
                  dbs_hash["sstkijuncd4"] = {:value => sstkijuncd4}
                  dbs_hash["sstkijuncd5"] = {:value => sstkijuncd5}
                  dbs_hash["sstkijuncd6"] = {:value => sstkijuncd6}
                  dbs_hash["sstkijuncd7"] = {:value => sstkijuncd7}
                  dbs_hash["sstkijuncd8"] = {:value => sstkijuncd8}
                  dbs_hash["sstkijuncd9"] = {:value => sstkijuncd9}
                  dbs_hash["sstkijuncd10"] = {:value => sstkijuncd10}
                  out_data.push(dbs_hash)
                else
                  out_data.push(
                    srycd,
                    name,
                    tanicd,
                    sstkijuncd1,
                    sstkijuncd2,
                    sstkijuncd3,
                    sstkijuncd4,
                    sstkijuncd5,
                    sstkijuncd6,
                    sstkijuncd7,
                    sstkijuncd8,
                    sstkijuncd9,
                    sstkijuncd10
                  )
                end
              end
            end
          end
        end
      end
    when "tbl_byomei"
      case key
      when "key3"
        v_byomei = value["byomei"]

        d_byomei = db_hash["byomei"].to_s
        d_byomeicd = db_hash["byomeicd"].to_s

        if /#{fix_utf8(v_byomei)}/ =~ fix_utf8(d_byomei)
          byomei = d_byomei
          byomeicd = d_byomeicd

          if mode == "dbs"
            dbs_hash = {}
            dbs_hash["byomei"] = {:value => byomei}
            dbs_hash["byomeicd"] = {:value => byomeicd}
            out_data.push(dbs_hash)
          else
            out_data.push(byomei, byomeicd)
          end
        end
      when "jrvpkey1"
        v_byomeicds = value["byomeicds"]

        d_byomei = db_hash["byomei"].to_s
        d_byomeicd = db_hash["byomeicd"].to_s

        v_byomeicds.gtk_each do |vv_byomeicds|
          if vv_byomeicds == d_byomeicd
            byomei = d_byomei
            byomeicd = d_byomeicd

            if mode == "dbs"
              dbs_hash = {}
              dbs_hash["byomei"] = {:value => byomei}
              dbs_hash["byomeicd"] = {:value => byomeicd}
              out_data.push(dbs_hash)
            else
              out_data.push(byomei, byomeicd)
            end
          end
        end
      when "jrvpkey2"
        v_byomeis = value["byomeis"]

        d_byomei = db_hash["byomei"].to_s
        d_byomeicd = db_hash["byomeicd"].to_s
        d_haisiymd = db_hash["haisiymd"]
        d_ikosakicd = db_hash["ikosakicd"]

        v_byomeis.gtk_each do |vv_byomeis|
          if fix_utf8(vv_byomeis) == fix_utf8(d_byomei)
            byomei = d_byomei
            byomeicd = d_byomeicd
            haisiymd = d_haisiymd
            ikosakicd = d_ikosakicd

            if mode == "dbs"
              dbs_hash = {}
              dbs_hash["byomei"] = {:value => byomei}
              dbs_hash["byomeicd"] = {:value => byomeicd}
              dbs_hash["haisiymd"] = {:value => haisiymd}
              dbs_hash["ikosakicd"] = {:value => ikosakicd}
              out_data.push(dbs_hash)
            else
              out_data.push(byomei, byomeicd, haisiymd, ikosakicd)
            end
          end
        end
      end
    when "tbl_hknjainf"
      case key
      when "jrvpkey1"
        v_hknjanums = value["hknjanums"]
        v_hospnum = value["hospnum"]

        d_hknjanum = db_hash["hknjanum"].gsub(/ +/, "")
        d_hknjaname = db_hash["hknjaname"]
        d_hospnum = db_hash["hospnum"]

        v_hknjanums.gtk_each do |v_hknjanum|
          if d_hknjanum == v_hknjanum and d_hospnum == v_hospnum
            hknjanum = d_hknjanum
            hknjaname = d_hknjaname

            if mode == "dbs"
              dbs_hash = {}
              dbs_hash["hknjanum"] = {:value => hknjanum}
              dbs_hash["hknjaname"] = {:value => hknjaname}
              out_data.push(dbs_hash)
            else
              out_data.push(hknjanum, hkenjaname)
            end
          end
        end
      end
    when "tbl_labor_sio"
      case key
      when "key"
        @dbfile[tbl].split(/\n/).gtk_each do |data|
          v_syocd = value["syocd"]
          v_yukostymd = value["yukostymd"]
          v_yukoedymd = value["yukoedymd"]

          s_data = data.split(/,/)
          @column[tbl].each_with_index do |frm, index|
            db_hash[frm] = s_data[index]
          end
          d_name = db_hash["name"]
          d_syocd = db_hash["syocd"]
          d_yukostymd = db_hash["yukostymd"]
          d_yukoedymd = db_hash["yukoedymd"]

          if d_syocd == v_syocd
            if d_yukostymd <= v_yukostymd
              if d_yukoedymd >= v_yukoedymd
                name = d_name
                syocd = d_syocd
                yukostymd = d_yukostymd
                yukoedymd = d_yukoedymd

                if mode == "dbs"
                  dbs_hash = {}
                  dbs_hash["name"] = {:value => name}
                  dbs_hash["syocd"] = {:value => syocd}
                  dbs_hash["yukostymd"] = {:value => yukostymd}
                  dbs_hash["yukoedymd"] = {:value => yukoedymd}
                  out_data.push(dbs_hash)
                else
                  out_data.push(syocd, yukostymd, yukoedymd, name)
                end
              end
            end
          end
        end
      when "key2"
        @dbfile[tbl].split(/\n/).gtk_each do |data|
          v_syocd = value["syocd"]

          s_data = data.split(/,/)
          @column[tbl].each_with_index do |frm, index|
            db_hash[frm] = s_data[index]
          end
          d_name = db_hash["name"]
          d_syocd = db_hash["syocd"]
          d_yukostymd = db_hash["yukostymd"]
          d_yukoedymd = db_hash["yukoedymd"]

          if d_syocd == v_syocd
            name = d_name
            syocd = d_syocd
            yukostymd = d_yukostymd
            yukoedymd = d_yukoedymd

            if mode == "dbs"
              dbs_hash = {}
              dbs_hash["name"] = {:value => name}
              dbs_hash["syocd"] = {:value => syocd}
              dbs_hash["yukostymd"] = {:value => yukostymd}
              dbs_hash["yukoedymd"] = {:value => yukoedymd}
              out_data.push(dbs_hash)
            else
              out_data.push(syocd, yukostymd, yukoedymd, name)
            end
          end
        end
      when "all"
        @dbfile[tbl].split(/\n/).gtk_each do |data|
          s_data = data.split(/,/)
          @column[tbl].each_with_index do |frm, index|
            db_hash[frm] = s_data[index]
          end
          name = db_hash["name"]
          syocd = db_hash["syocd"]
          yukostymd = db_hash["yukostymd"]
          yukoedymd = db_hash["yukoedymd"]

          if mode == "dbs"
            dbs_hash = {}
            dbs_hash["name"] = {:value => name}
            dbs_hash["syocd"] = {:value => syocd}
            dbs_hash["yukostymd"] = {:value => yukostymd}
            dbs_hash["yukoedymd"] = {:value => yukoedymd}
            out_data.push(dbs_hash)
          else
            out_data.push(syocd, yukostymd, yukoedymd, name)
          end
        end
      end
    when "tbl_syskanri"
      case key
      when "key_hnum"
        v_hospid = value["hospid"]

        d_kanritbl = db_hash["kanritbl"].to_s
        d_hospnum = db_hash["hospnum"].to_s

        if /#{v_hospid}/ =~ d_kanritbl
          hospnum = d_hospnum

          if mode == "dbs"
            dbs_hash = {}
            dbs_hash["hospnum"] = {:value => hospnum}
            out_data.push(dbs_hash)
          else
            out_data.push(hospnum)
          end
        end
      end
    when "tbl_dbkanri"
      case key
      when "all"
        kanricd = db_hash["kanricd"]
        version = db_hash["version"]
        dbsversion1 = db_hash["dbsversion1"]
        dbsversion2 = db_hash["dbsversion2"]
        dbrversion1 = db_hash["dbrversion1"]
        dbrversion2 = db_hash["dbrversion2"]
        termid = db_hash["termid"]
        opid = db_hash["opid"]
        creymd = db_hash["creymd"]
        upymd = db_hash["upymd"]
        uphms = db_hash["uphms"]

        if mode == "dbs"
          dbs_hash = {}
          dbs_hash["kanricd"] = {:value => kanricd}
          dbs_hash["version"] = {:value => version}
          dbs_hash["dbsversion1"] = {:value => dbsversion1}
          dbs_hash["dbsversion2"] = {:value => dbsversion2}
          dbs_hash["dbrversion1"] = {:value => dbrversion1}
          dbs_hash["dbrversion2"] = {:value => dbrversion2}
          dbs_hash["termid"] = {:value => termid}
          dbs_hash["opid"] = {:value => opid}
          dbs_hash["creymd"] = {:value => creymd}
          dbs_hash["upymd"] = {:value => upymd}
          dbs_hash["uphms"] = {:value => uphms}
          out_data.push(dbs_hash)
        else
          out_data.push(hknjanum, hkenjaname)
        end
      end
    end
    return out_data
  end

  def clean_db
    @filelist.each do |tbl, file_path|
      tb = @dbfile[tbl].dup
      if tb.class == String
        @dbfile[tbl] = ""
      else
        tb.each do |t|
          @dbfile[tbl].clear
        end
      end
    end
  end

  def make_db
    @filelist.each do |tbl, file_path|
      if File.exist?(file_path) and !tbl.to_s.empty?
        @dbfile[tbl] = ""
        if RUBY_VERSION.to_s <= "1.8.7"
          @dbfile[tbl] = File.open(file_path).read
        else
          @dbfile[tbl] = File.open(file_path).read.toeuc
        end
      else
        @all_error.push("dbfile make")
        self.error("dbfile make")
      end
    end

    index = self.make_db_index(@dbfile["tbl_tensu"], 1)
    @index_tbl["tbl_tensu"] = index[0]
    @endex_tbl["tbl_tensu"] = index[1]

    index = self.make_db_index(@dbfile["tbl_byomei"], 1)
    @index_tbl["tbl_byomei"] = index[0]
    @endex_tbl["tbl_byomei"] = index[1]

    #@dbfile["tbl_byomei.name"] = self.make_db_custom(@dbfile["tbl_byomei"], 0)
    #index = self.make_db_index(@dbfile["tbl_byomei.name"], 1)
    #@index_tbl["tbl_byomei.name"] = index[0]
    #@endex_tbl["tbl_byomei.name"] = index[1]

    @read_to = "memory"
  end

  def make_db_custom(tbl_data, pindex)
     tbl_data_custom = tbl_data.sort do |a, b|
       a.split(',')[pindex] <=> b.split(',')[pindex]
     end
     return tbl_data_custom
  end

  def make_db_index(tbl_data, key)
    index_tbl = {}
    endex_tbl = {}
    index_old = ""

    tbl_data.to_s.split(/\n/).gtk_each_with_index do |data, loop_index|
      index_name = data.split(/,/)[key].slice(0, @index_size)

      if index_tbl[index_name].to_s.empty?
        endex_tbl[index_old] = loop_index - index_tbl[index_old].to_i
        index_tbl[index_name] = loop_index
        index_old = index_name
      end
    end
    return index_tbl, endex_tbl
  end

  def make_db_old(ys=00000000)
    @filelist.each do |tbl, file_path|
      if File.exist?(file_path) and !tbl.to_s.empty?
        tbl_index = 0
        old_index = 0
        @dbfile[tbl] = []
        File.open(file_path, "r:euc-jp:utf-8").read.split(/\n/).gtk_each do |data|
          data_split = data.split(/,/)
          tmp_hash = {}
          flash_ed_flg = false
          @column[tbl].each_with_index do |frm, index|
            data_split_tmp = data_split[index]
            if "yukoedymd" == frm
              if data_split_tmp.to_s == "99999999"
                tmp_hash[frm] = data_split_tmp
              elsif data_split_tmp.to_i == 0
                tmp_hash[frm] = data_split_tmp
              elsif ys.to_i > data_split_tmp.to_i
                flash_ed_flg = true
                break
              else
                tmp_hash[frm] = data_split_tmp
              end
            else
              tmp_hash[frm] = data_split_tmp
            end
          end

          if !flash_ed_flg
            s_index = tmp_hash["srycd"].to_s.slice(0, 2).to_s
            if @tbl_index[tbl][s_index].to_s.empty?
              @tbl_index_s[tbl][old_index] = tbl_index - @tbl_index[tbl][old_index].to_i
              @tbl_index[tbl][s_index] = tbl_index
              old_index = s_index
            end
            @dbfile[tbl].push(tmp_hash)
          end
          tbl_index += 1
        end
        @read_to = "memory"
      else
        @all_error.push("dbfile make")
        self.error("dbfile make")
      end
    end
  end

  def make_db_add(file_path="tbl_tensu.rdb", tbl="", ys=0, ye=0)
    if File.exist?(file_path) and !tbl.to_s.empty?
      File.open(file_path, "r:euc-jp:utf-8").read.split(/\n/).gtk_each do |data|
        data_split = data.split(/,/)
        tmp_hash = {}
        flash_flg = false
        @column[tbl].each_with_index do |frm, index|
          if "yukoedymd" == frm
            data_st = data_split[index]
            if ys.to_i <= data_st.to_i
              if ye.to_i > data_st.to_i
                tmp_hash[frm] = data_st
              else
                flash_flg = true
                break
              end
            elsif data_st.to_s == "00000000"
              tmp_hash[frm] = data_st
            elsif data_st.to_i == 0
              flash_flg = true
              break
            else
              flash_flg = true
              break
            end
          else
            tmp_hash[frm] = data_split[index]
          end
        end
        @dbfile[tbl].push(tmp_hash) if !flash_flg
      end
      return true
    else
      return false
    end
  end

  def nowymd
    ymd = Time.now.strftime("%Y%m%d")
    return ymd
  end

  def oldymd
    ymd = (Date.today.year.to_i - 1).to_s + "0331"
    return ymd
  end

  def key_record2tbl(record)
    res_tbl = record
    case record
    when "tbl_tensu_35"
      res_tbl = "tbl_tensu"
    when "tbl_hknjainf_35"
      res_tbl = "tbl_hknjainf"
    when "tbl_syskanri_35"
      res_tbl = "tbl_syskanri"
    end
    return res_tbl
  end

  def rsql2delete(str)
     sql_find_key = "%"
     if str.class == Array
       return str
     elsif str.class == String
       return str.gsub(/#{sql_find_key}/, "")
     else
       return str.to_s.gsub(/#{sql_find_key}/, "")
     end
  end

  def transaction
    begin
      yield
    rescue
    end
  end

  def select (st, num=nil)
     @transaction_stat = true
     return @transaction_stat
  end

  def fetch(st)
    re_d = ""
    tbl = self.key_record2tbl(st[:record])
    all_value = {}
    st[:query].each do |key, value|
      all_value[key] = rsql2delete(value)
    end
    if @transaction_stat
      case @read_to
      when "memory"
        re_d = self.fetch_sub(tbl, st[:key], all_value, "dbs")
      when "file"
        re_d = self.search_file(tbl, st[:key], all_value, "dbs")
      else
        re_d = self.fetch_sub(tbl, st[:key], all_value, "dbs")
      end
      @transaction_stat = false
    else
      re_d = ""
    end
    return re_d
  end

  def fetch_sub(tbl, key, value, mode="dbs")
    out_data = []
    dbs_hash = {}
    db_hash = {}
    raise "DBFile Error: Not Table[#{tbl}]" if @dbfile[tbl].class == Array
    case tbl
    when "tbl_tensu"
      case key
      when "key1"
        v_name = value["name"]
        v_hospnum = value["hospnum"]

        @dbfile[tbl].split(/\n/).gtk_each do |data|

          db_hash = data.split(/,/)
          
          d_name  = db_hash[2].to_s
          d_srycd = db_hash[1].to_s
          d_yukostymd = db_hash[4].to_i
          d_yukoedymd = db_hash[5].to_i
          d_hospnum = db_hash[0].to_s

          if /#{NKF.nkf("-Ew", v_name)}/ =~ NKF.nkf("-Ew", d_name)
            if d_hospnum == v_hospnum
              name  = d_name
              srycd = d_srycd
              yukostymd = d_yukostymd
              yukoedymd = d_yukoedymd

              if mode == "dbs"
                dbs_hash = {}
                dbs_hash["srycd"] = {:value => srycd}
                dbs_hash["name"] = {:value => name}
                dbs_hash["yukostymd"] = {:value => yukostymd}
                dbs_hash["yukoedymd"] = {:value => yukoedymd}
                out_data.push(dbs_hash)
              else
                out_data.push(srycd, name, yukostymd, yukoedymd)
              end
            end
          end
        end
      when "jrvpkey1"
        v_srycds = value["srycds"]
        v_yukostymd = value["yukostymd"].to_i
        v_yukoedymd = value["yukoedymd"].to_i
        v_hospnum = value["hospnum"].to_s

        v_srycds.sort.gtk_each do |srycd|
          scode = srycd.slice(0, @index_size)
          sindex = @index_tbl["tbl_tensu"][scode].to_i
          sloop  = @endex_tbl["tbl_tensu"][scode].to_i
          file_arr = @dbfile[tbl].to_s.split(/\n/)

          sloop.times do |index|
            db_hash = file_arr[sindex + index].split(/,/)
            d_name  = db_hash[2].to_s
            d_srycd = db_hash[1].to_s
            d_tanicd = db_hash[3].to_s
            d_yukostymd = db_hash[4].to_i
            d_yukoedymd = db_hash[5].to_i
            d_sstkijuncd = []
            d_sstkijuncd.push(db_hash[6].to_s)
            d_sstkijuncd.push(db_hash[7].to_s)
            d_sstkijuncd.push(db_hash[8].to_s)
            d_sstkijuncd.push(db_hash[9].to_s)
            d_sstkijuncd.push(db_hash[10].to_s)
            d_sstkijuncd.push(db_hash[11].to_s)
            d_sstkijuncd.push(db_hash[12].to_s)
            d_sstkijuncd.push(db_hash[13].to_s)
            d_sstkijuncd.push(db_hash[14].to_s)
            d_sstkijuncd.push(db_hash[15].to_s)
            d_gaitenttlkbn = db_hash[16].to_s
            d_nyutenttlkbn = db_hash[17].to_s
            d_hospnum = db_hash[0].to_s
        
            if d_srycd == srycd and d_hospnum == v_hospnum
              if d_yukostymd <= v_yukostymd
                if d_yukoedymd >= v_yukoedymd
                  name  = d_name
                  srycd = d_srycd
                  tanicd = d_tanicd
                  yukostymd = d_yukostymd
                  yukoedymd = d_yukoedymd
                  sstkijuncd1 = d_sstkijuncd[0]
                  sstkijuncd2 = d_sstkijuncd[1]
                  sstkijuncd3 = d_sstkijuncd[2]
                  sstkijuncd4 = d_sstkijuncd[3]
                  sstkijuncd5 = d_sstkijuncd[4]
                  sstkijuncd6 = d_sstkijuncd[5]
                  sstkijuncd7 = d_sstkijuncd[6]
                  sstkijuncd8 = d_sstkijuncd[7]
                  sstkijuncd9 = d_sstkijuncd[8]
                  sstkijuncd10 = d_sstkijuncd[9]
                  gaitenttlkbn = d_gaitenttlkbn
                  nyutenttlkbn = d_nyutenttlkbn
                  hospnum = d_hospnum

                  if mode == "dbs"
                    dbs_hash = {}
                    dbs_hash["srycd"] = {:value => srycd}
                    dbs_hash["name"] = {:value => name}
                    dbs_hash["tanicd"] = {:value => tanicd}
                    dbs_hash["yukostymd"] = {:value => yukostymd}
                    dbs_hash["yukoedymd"] = {:value => yukoedymd}
                    dbs_hash["sstkijuncd1"] = {:value => sstkijuncd1}
                    dbs_hash["sstkijuncd2"] = {:value => sstkijuncd2}
                    dbs_hash["sstkijuncd3"] = {:value => sstkijuncd3}
                    dbs_hash["sstkijuncd4"] = {:value => sstkijuncd4}
                    dbs_hash["sstkijuncd5"] = {:value => sstkijuncd5}
                    dbs_hash["sstkijuncd6"] = {:value => sstkijuncd6}
                    dbs_hash["sstkijuncd7"] = {:value => sstkijuncd7}
                    dbs_hash["sstkijuncd8"] = {:value => sstkijuncd8}
                    dbs_hash["sstkijuncd9"] = {:value => sstkijuncd9}
                    dbs_hash["sstkijuncd10"] = {:value => sstkijuncd10}
                    dbs_hash["gaitenttlkbn"] = {:value => gaitenttlkbn}
                    dbs_hash["nyutenttlkbn"] = {:value => nyutenttlkbn}
                    dbs_hash["hospnum"] = {:value => hospnum}
                    out_data.push(dbs_hash)
                  else
                    out_data.push(
                      srycd,
                      name,
                      tanicd,
                      yukostymd,
                      yukoedymd,
                      sstkijuncd1,
                      sstkijuncd2,
                      sstkijuncd3,
                      sstkijuncd4,
                      sstkijuncd5,
                      sstkijuncd6,
                      sstkijuncd7,
                      sstkijuncd8,
                      sstkijuncd9,
                      sstkijuncd10,
                      gaitenttlkbn,
                      nyutenttlkbn,
                      hospnum
                    )
                  end
                  break if v_srycds.size == out_data.size
                end
              end
            end
          end
        end
      when "jrvpkey2"
        v_srycds = value["srycds"]
        v_yukostymd = value["yukostymd"].to_i
        v_yukoedymd = value["yukoedymd"].to_i
        v_hospnum = value["hospnum"]

        @dbfile[tbl].split(/\n/).gtk_each do |data|
          s_data = data.split(/,/)
          @column[tbl].each_with_index do |frm, index|
            db_hash[frm] = s_data[index]
          end
          d_name  = db_hash["name"].to_s
          d_srycd = db_hash["srycd"].to_s
          d_yukostymd = db_hash["yukostymd"].to_i
          d_yukoedymd = db_hash["yukoedymd"].to_i
          d_tanicd = db_hash["tanicd"].to_s
          d_sstkijuncd = []
          d_sstkijuncd.push(db_hash["sstkijuncd1"].to_s)
          d_sstkijuncd.push(db_hash["sstkijuncd2"].to_s)
          d_sstkijuncd.push(db_hash["sstkijuncd3"].to_s)
          d_sstkijuncd.push(db_hash["sstkijuncd4"].to_s)
          d_sstkijuncd.push(db_hash["sstkijuncd5"].to_s)
          d_sstkijuncd.push(db_hash["sstkijuncd6"].to_s)
          d_sstkijuncd.push(db_hash["sstkijuncd7"].to_s)
          d_sstkijuncd.push(db_hash["sstkijuncd8"].to_s)
          d_sstkijuncd.push(db_hash["sstkijuncd9"].to_s)
          d_sstkijuncd.push(db_hash["sstkijuncd10"].to_s)
          d_hospnum = db_hash["hospnum"]

          v_srycds.gtk_each do |srycd|
            if d_srycd == srycd and d_hospnum == v_hospnum
              if d_yukostymd <= v_yukostymd
                if d_yukoedymd >= v_yukoedymd
                  name  = d_name
                  srycd = d_srycd
                  tanicd = d_tanicd
                  sstkijuncd1 = d_sstkijuncd[0]
                  sstkijuncd2 = d_sstkijuncd[1]
                  sstkijuncd3 = d_sstkijuncd[2]
                  sstkijuncd4 = d_sstkijuncd[3]
                  sstkijuncd5 = d_sstkijuncd[4]
                  sstkijuncd6 = d_sstkijuncd[5]
                  sstkijuncd7 = d_sstkijuncd[6]
                  sstkijuncd8 = d_sstkijuncd[7]
                  sstkijuncd9 = d_sstkijuncd[8]
                  sstkijuncd10 = d_sstkijuncd[9]

                  if mode == "dbs"
                    dbs_hash = {}
                    dbs_hash["srycd"] = {:value => srycd}
                    dbs_hash["name"] = {:value => name}
                    dbs_hash["tanicd"] = {:value => tanicd}
                    dbs_hash["sstkijuncd1"] = {:value => sstkijuncd1}
                    dbs_hash["sstkijuncd2"] = {:value => sstkijuncd2}
                    dbs_hash["sstkijuncd3"] = {:value => sstkijuncd3}
                    dbs_hash["sstkijuncd4"] = {:value => sstkijuncd4}
                    dbs_hash["sstkijuncd5"] = {:value => sstkijuncd5}
                    dbs_hash["sstkijuncd6"] = {:value => sstkijuncd6}
                    dbs_hash["sstkijuncd7"] = {:value => sstkijuncd7}
                    dbs_hash["sstkijuncd8"] = {:value => sstkijuncd8}
                    dbs_hash["sstkijuncd9"] = {:value => sstkijuncd9}
                    dbs_hash["sstkijuncd10"] = {:value => sstkijuncd10}
                    out_data.push(dbs_hash)
                  else
                    out_data.push(
                      srycd,
                      name,
                      tanicd,
                      sstkijuncd1,
                      sstkijuncd2,
                      sstkijuncd3,
                      sstkijuncd4,
                      sstkijuncd5,
                      sstkijuncd6,
                      sstkijuncd7,
                      sstkijuncd8,
                      sstkijuncd9,
                      sstkijuncd10
                    )
                  end
                end
              end
            end
          end
        end
      when "jrvpkey4"
        v_name = value["name"]
        v_hospnum = value["hospnum"]

        @dbfile[tbl].split(/\n/).gtk_each do |data|

          db_hash = data.split(/,/)
          
          d_name  = db_hash[2].to_s
          d_srycd = db_hash[1].to_s
          d_yukostymd = db_hash[4].to_i
          d_yukoedymd = db_hash[5].to_i
          d_hospnum = db_hash[0].to_s

          if /#{NKF.nkf("-Ew", v_name)}/ =~ NKF.nkf("-Ew", d_name)
            if d_hospnum == v_hospnum
              name  = d_name
              srycd = d_srycd
              yukostymd = d_yukostymd
              yukoedymd = d_yukoedymd

              if mode == "dbs"
                dbs_hash = {}
                dbs_hash["srycd"] = {:value => srycd}
                dbs_hash["name"] = {:value => name}
                dbs_hash["yukostymd"] = {:value => yukostymd}
                dbs_hash["yukoedymd"] = {:value => yukoedymd}
                out_data.push(dbs_hash)
              else
                out_data.push(srycd, name, yukostymd, yukoedymd)
              end
            end
          end
        end
      end
    when "tbl_byomei"
      case key
      when "key3"
        v_byomei = value["byomei"]

        @dbfile[tbl].split(/\n/).gtk_each do |data|
          s_data = data.split(/,/)
          @column[tbl].each_with_index do |frm, index|
            db_hash[frm] = s_data[index]
          end
          d_byomei = db_hash["byomei"].to_s
          d_byomeicd = db_hash["byomeicd"].to_s

          if /#{fix_utf8(v_byomei)}/ =~ fix_utf8(d_byomei)
            byomei = d_byomei
            byomeicd = d_byomeicd
            if mode == "dbs"
              dbs_hash = {}
              dbs_hash["byomei"] = {:value => byomei}
              dbs_hash["byomeicd"] = {:value => byomeicd}
              out_data.push(dbs_hash)
            else
              out_data.push(byomei, byomeicd)
            end
          end
        end
      when "jrvpkey1"
        v_byomeicds = value["byomeicds"]
        v_byomeicds.sort.gtk_each do |v_byomeicd|
          scode = v_byomeicd.slice(0, @index_size)
          sindex = @index_tbl["tbl_byomei"][scode].to_i
          sloop  = @endex_tbl["tbl_byomei"][scode].to_i
          file_arr = @dbfile[tbl].split(/\n/)

          sloop.times do |index|
            db_hash = file_arr[sindex + index].split(/,/)
            d_byomei    = db_hash[0].to_s
            d_byomeicd  = db_hash[1].to_s

            if v_byomeicd == d_byomeicd
              byomei    = d_byomei
              byomeicd  = d_byomeicd
              if mode == "dbs"
                dbs_hash = {}
                dbs_hash["byomei"]    = {:value => byomei}
                dbs_hash["byomeicd"]  = {:value => byomeicd}
                out_data.push(dbs_hash)
              else
                out_data.push(byomei, byomeicd)
              end
            end
          end
        end
      when "jrvpkey2"
        v_byomeis = value["byomeis"]

        @dbfile[tbl].split(/\n/).gtk_each do |data|
          s_data = data.split(/,/)
          @column[tbl].each_with_index do |frm, index|
            db_hash[frm] = s_data[index]
          end
          d_byomei = db_hash["byomei"].to_s
          d_byomeicd = db_hash["byomeicd"].to_s
          d_haisiymd = db_hash["haisiymd"]
          d_ikosakicd = db_hash["ikosakicd"]

          v_byomeis.each do |vv_byomeis|
            if vv_byomeis == d_byomei
              byomei = d_byomei
              byomeicd = d_byomeicd
              haisiymd = d_haisiymd
              ikosakicd = d_ikosakicd

              if mode == "dbs"
                dbs_hash = {}
                dbs_hash["byomei"] = {:value => byomei}
                dbs_hash["byomeicd"] = {:value => byomeicd}
                dbs_hash["haisiymd"] = {:value => haisiymd}
                dbs_hash["ikosakicd"] = {:value => ikosakicd}
                out_data.push(dbs_hash)
              else
                out_data.push(byomei, byomeicd, haisiymd, ikosakicd)
              end
            end
          end
        end
      end
    when "tbl_hknjainf"
      case key
      when "jrvpkey1"
        v_hknjanums = value["hknjanums"]
        v_hospnum = value["hospnum"]

        @dbfile[tbl].split(/\n/).gtk_each do |data|
          s_data = data.split(/,/)
          @column[tbl].each_with_index do |frm, index|
            db_hash[frm] = s_data[index]
          end
          d_hknjanum = db_hash["hknjanum"].gsub(/ +/, "")
          d_hknjaname = db_hash["hknjaname"]
          d_hospnum = db_hash["hospnum"]

          v_hknjanums.each do |v_hknjanum|
            if d_hknjanum == v_hknjanum and d_hospnum == v_hospnum
              hknjanum = d_hknjanum
              hknjaname = d_hknjaname

              if mode == "dbs"
                dbs_hash = {}
                dbs_hash["hknjanum"] = {:value => hknjanum}
                dbs_hash["hknjaname"] = {:value => hknjaname}
                out_data.push(dbs_hash)
              else
                out_data.push(hknjanum, hkenjaname)
              end
            end
          end
        end
      end
    when "tbl_labor_sio"
      case key
      when "key"
        @dbfile[tbl].split(/\n/).gtk_each do |data|
          v_syocd = value["syocd"]
          v_yukostymd = value["yukostymd"]
          v_yukoedymd = value["yukoedymd"]

          s_data = data.split(/,/)
          @column[tbl].each_with_index do |frm, index|
            db_hash[frm] = s_data[index]
          end
          d_name = db_hash["name"]
          d_syocd = db_hash["syocd"]
          d_yukostymd = db_hash["yukostymd"]
          d_yukoedymd = db_hash["yukoedymd"]

          if d_syocd == v_syocd
            if d_yukostymd <= v_yukostymd
              if d_yukoedymd >= v_yukoedymd
                name = d_name
                syocd = d_syocd
                yukostymd = d_yukostymd
                yukoedymd = d_yukoedymd

                if mode == "dbs"
                  dbs_hash = {}
                  dbs_hash["name"] = {:value => name}
                  dbs_hash["syocd"] = {:value => syocd}
                  dbs_hash["yukostymd"] = {:value => yukostymd}
                  dbs_hash["yukoedymd"] = {:value => yukoedymd}
                  out_data.push(dbs_hash)
                else
                  out_data.push(syocd, yukostymd, yukoedymd, name)
                end
              end
            end
          end
        end
      when "key2"
        @dbfile[tbl].split(/\n/).gtk_each do |data|
          v_syocd = value["syocd"]

          s_data = data.split(/,/)
          @column[tbl].each_with_index do |frm, index|
            db_hash[frm] = s_data[index]
          end
          d_name = db_hash["name"]
          d_syocd = db_hash["syocd"]
          d_yukostymd = db_hash["yukostymd"]
          d_yukoedymd = db_hash["yukoedymd"]

          if d_syocd == v_syocd
            name = d_name
            syocd = d_syocd
            yukostymd = d_yukostymd
            yukoedymd = d_yukoedymd

            if mode == "dbs"
              dbs_hash = {}
              dbs_hash["name"] = {:value => name}
              dbs_hash["syocd"] = {:value => syocd}
              dbs_hash["yukostymd"] = {:value => yukostymd}
              dbs_hash["yukoedymd"] = {:value => yukoedymd}
              out_data.push(dbs_hash)
            else
              out_data.push(syocd, yukostymd, yukoedymd, name)
            end
          end
        end
      when "all"
        @dbfile[tbl].split(/\n/).gtk_each do |data|
          s_data = data.split(/,/)
          @column[tbl].each_with_index do |frm, index|
            db_hash[frm] = s_data[index]
          end
          name = db_hash["name"]
          syocd = db_hash["syocd"]
          yukostymd = db_hash["yukostymd"]
          yukoedymd = db_hash["yukoedymd"]

          if mode == "dbs"
            dbs_hash = {}
            dbs_hash["name"] = {:value => name}
            dbs_hash["syocd"] = {:value => syocd}
            dbs_hash["yukostymd"] = {:value => yukostymd}
            dbs_hash["yukoedymd"] = {:value => yukoedymd}
            out_data.push(dbs_hash)
          else
            out_data.push(syocd, yukostymd, yukoedymd, name)
          end
        end
      end
    when "tbl_syskanri"
      case key
      when "key_hnum"
        v_hospid = value["hospid"]

        @dbfile[tbl].split(/\n/).gtk_each do |data|
          s_data = data.split(/,/)
          @column[tbl].each_with_index do |frm, index|
            db_hash[frm] = s_data[index]
          end
          d_kanritbl = db_hash["kanritbl"].to_s
          d_hospnum = db_hash["hospnum"].to_s

          if /#{v_hospid}/ =~ d_kanritbl
            hospnum = d_hospnum

            if mode == "dbs"
              dbs_hash = {}
              dbs_hash["hospnum"] = {:value => hospnum}
              out_data.push(dbs_hash)
            else
              out_data.push(hospnum)
            end
          end
        end
      end
    when "tbl_dbkanri"
      case key
      when "all"
        @dbfile[tbl].split(/\n/).gtk_each do |data|
          s_data = data.split(/,/)
          @column[tbl].each_with_index do |frm, index|
            db_hash[frm] = s_data[index]
          end

          kanricd = db_hash["kanricd"]
          version = db_hash["version"]
          dbsversion1 = db_hash["dbsversion1"]
          dbsversion2 = db_hash["dbsversion2"]
          dbrversion1 = db_hash["dbrversion1"]
          dbrversion2 = db_hash["dbrversion2"]
          termid = db_hash["termid"]
          opid = db_hash["opid"]
          creymd = db_hash["creymd"]
          upymd = db_hash["upymd"]
          uphms = db_hash["uphms"]

          if mode == "dbs"
            dbs_hash = {}
            dbs_hash["kanricd"] = {:value => kanricd}
            dbs_hash["version"] = {:value => version}
            dbs_hash["dbsversion1"] = {:value => dbsversion1}
            dbs_hash["dbsversion2"] = {:value => dbsversion2}
            dbs_hash["dbrversion1"] = {:value => dbrversion1}
            dbs_hash["dbrversion2"] = {:value => dbrversion2}
            dbs_hash["termid"] = {:value => termid}
            dbs_hash["opid"] = {:value => opid}
            dbs_hash["creymd"] = {:value => creymd}
            dbs_hash["upymd"] = {:value => upymd}
            dbs_hash["uphms"] = {:value => uphms}
            out_data.push(dbs_hash)
          else
            out_data.push(kanricd,
              version,
              dbsversion1,
              dbsversion2,
              dbrversion1,
              dbrversion2,
              termid,
              opid,
              creymd,
              upymd,
              uphms)
          end
        end
      end
    end
    return out_data
  end

  def error(comment)
    @ex_error = comment
    raise "Local DBFile Error: #{comment}"
  end
end

if __FILE__ == $0
end
