# -*- encoding: utf-8 -*-

require 'jma/receview/generation'
require 'yaml'

# revert Thu, 01 May 2014 15:10:56 +0900
# exURL: http://d.hatena.ne.jp/anagotan/20130304/1362370566
# exURL: http://projectzero-swb.blogspot.jp/2010/06/rubyyaml2.html
if RUBY_VERSION.to_s < "1.9.0"
  require "yaml/encoding"
  #class String
    #def is_binary_data?
    #  return false
    #end
  #end
end

class ReceViewConf
  RECEVIEW_DIR = ".receview"
  RECEVIEW_CONF = "receview.conf"
  UPDATE_CONF = "update.conf"

  USER_ONLY_RWX = 0700
  USER_ONLY_RW = 0600

  RE_USER_NO = 13

  def initialize
    require 'jma/receview/base'
    require "digest/md5"
    @base = ReceView_Base.new
    @setting_data = {}
    @history_version = 1
    @save_version = 2
    @print_version = 1
  end

  def set_setting_data(setting_data)
    @setting_data = setting_data
  end

  def set_version(version_int)
    @history_version = version_int.to_i
  end

  def version
    @history_version
  end

  # log directory.
  def setting_uniqmark(user_setting_save=false)
    savedir = Dir.pwd
    Dir.chdir
    begin
      if !File.exist?(RECEVIEW_DIR)
        Dir.mkdir(RECEVIEW_DIR, USER_ONLY_RWX)
      end
      File.chmod(USER_ONLY_RWX, RECEVIEW_DIR)
      Dir.chdir(RECEVIEW_DIR)
      if user_setting_save
        save_setting(RECEVIEW_CONF, @setting_data)
      end
      yield
    rescue
      ReceViewLog.save("setting save missing #{Dir.pwd} #{RECEVIEW_DIR}")
    end
    Dir.chdir(savedir)
  end

  # create history filename.
  def create_history_file(ir_record, re_record)
    v_file = []
    hoken = 0
    id  = 2 
    day = 5
    no  = 6
    ir_record.each_with_index do |records,index|
      if !records.to_s.empty?
        record = records.split(/,/)
        c_hoken = s2send_hoken(record[hoken]).to_s
        c_day = record[day].to_s
        c_id = record[id].to_s
        c_no = record[no].to_s
        if /[1-3]+/ =~ c_hoken
          if c_hoken.to_s == "3" and records.gsub(/,/, "").to_s == "なし00"
            c_hoken = "4" 
            re_record[index].each do |re|
              re_arr = re.split(/,/)
              c_id  = "ROSAI_HENREI"
              c_day = date_make(re_arr[19].to_s, true)
              # UniqNo re_arr[18]
              break
            end
          end
          if /[0-9]+/ =~ c_no
            v_file.push([c_hoken, c_day, c_id, c_no].join("_"))
          end
        end
      end
      return v_file
    end
  end

  # printspool history file
  def save_printspool_history_file(filename, data)
    if not data.empty?
      data = data.join("\n") if data.class == Array
      data << "\n"
      data << "print_version=#{@print_version.to_s}"
      file_v = open(filename, "w+", USER_ONLY_RW)
      file_v << data
      file_v.close
      File.chmod(USER_ONLY_RW, filename)
    end
  end

  # printspool history file
  def load_printspool_history_file(filename)
    out_data = []
    if File.exist?(filename)
      file = open(filename)
      data = file.read.toutf8.encode!("UTF-8")
      version_data = data.split(/\n/).last.split(/=/)
      file.close

      if version_data.size == 2
        case version_data[0].to_s
        when  "history_version"
          @print_version = 0
        when  "print_version"
          @print_version = version_data[1].to_i
        end
      else
        @print_version = 0
      end

      case @print_version.to_i
      when 0
        data.split(/\n/).each do |line|
          user_cs = line.sub(/\n/, "").split(/,/)
          if user_cs.size != 1
            user_status = ""
            @base.printspool_message_fix.each do |text|
              if /#{text}/ =~ user_cs[3].to_s
                user_cs[3] = user_cs[3].to_s.sub(/#{text}/, "")
                user_status = text
              end
            end
            out_data.push(
              { 
                "re"  => user_cs[0].to_s,
                "no"  => user_cs[1].to_s,
                "ymd" => user_cs[2].to_s,
                "runtime" => user_cs[3].to_s,
                "status"  => user_status,
                "time"    => user_cs[4].to_s,
                "pointer" => user_cs[5].to_s,
                "md5"     => user_cs[6].to_s,
             }
            )
          end
        end
      else
        data.split(/\n/).each do |line|
          user_cs = line.sub(/\n/, "").split(/,/)
          if user_cs.size != 1
            out_data.push(
              { 
                "re"  => user_cs[0].to_s,
                "no"  => user_cs[1].to_s,
                "ymd" => user_cs[2].to_s,
                "runtime" => user_cs[3].to_s,
                "status"  => user_cs[4].to_s,
                "time"    => user_cs[5].to_s,
                "pointer" => user_cs[6].to_s,
                "md5"     => user_cs[7].to_s,
             }
            )
          end
        end
      end
    end
    @print_version = 1
    return out_data
  end

  # view history file
  def save_history_file(filename, data)
    data << "history_version=#{@save_version.to_s}"
    file_v = open(filename, "w+", USER_ONLY_RW)
    file_v << data
    file_v.close
    File.chmod(USER_ONLY_RW, filename)
  end

  # check history data
  def load_history_recheck(files, index)
    out_data = {}
    file = open(files)
    data = file.read.toutf8.encode!("UTF-8")
    version_data = data.split(/\n/).last.split(/history_version=/)
    file.close

    if version_data.size == 2
      @history_version = version_data[1].to_i
    else
      @history_version = 1
    end

    data.split(/\n/).each do |line|
      user_cs = line.sub(/\n/, "").split(/,/)
      if user_cs.size != 1
        md5  = user_cs[0].to_s
        stat = user_cs[2].to_s
        time = user_cs[3].to_s
        ex_o = user_cs[4].to_s
        sc_o = user_cs[5].to_s

        if /^([a-z|0-9])+,#{index}(:[0-9]+)+,(\d|\w)+,/ =~ line
          out_data[md5] = [stat, time, ex_o, sc_o].join(",")
        else
          out_data[md5] = ["error", time].join(",")
        end
      end
    end
    return out_data
  end

  # Configuration data save
  def save_setting(filename, hash)
    begin
      hash["setting_version"] = ReceViewVersion.Text
      hash["file_history"] = @base.replace_non_line_path_char(hash["file_history"])
      hash["file_history"] = "" if hash["file_history_status"].to_i == 1

      file = open(filename, "w+", USER_ONLY_RW)
      yaml = YAML.dump(hash)
      if RUBY_VERSION.to_s < "1.9.0"
        yaml = YAML.unescape(yaml)
      end
      file.write(yaml)
      file.close
      File.chmod(USER_ONLY_RW, filename)
    rescue
      ReceViewLog.save("setting save error")
    end
  end

  # Check YAML file data
  def check_yaml_data?(filename)
    File.open(filename) do |io|
      begin
        YAML.load_stream(io)
        true
      rescue
        false
      end
    end
  end

  # Configuration file Version
  def setting_version?(filename)
    clinic_setting = {}
    if File.exist?(filename)
      begin
        if check_yaml_data?(filename)
          clinic_setting = self.setting_load_yaml(filename)
        else
          clinic_setting["setting_version"] = "break_yaml"
        end
      rescue Psych::SyntaxError
        clinic_setting["setting_version"] = "break_yaml"
      rescue
        clinic_setting["setting_version"] = "break_yaml"
      end
    else
      clinic_setting["setting_version"] = ""
    end

    if clinic_setting.nil?
      return ""
    else
      if clinic_setting["setting_version"].to_s.empty?
        return ""
      else
        return clinic_setting["setting_version"].to_s
      end
    end
  end

  # Configuration file read for YAML
  def setting_load_yaml(filename)
    clinic_setting = {}
    File.open(filename) do |io|
      y = YAML.load_stream(io)
      if y == nil
        clinic_setting["setting_version"] = "break_yaml"
      else
        if y.class == Array
          clinic_setting = y.last
        else
          clinic_setting = y.documents.last
        end
      end
    end
    return clinic_setting
  end

  # Configuration file read
  def setting_load(filename)
    ref_status = setting_version?(filename)
    if ref_status.empty? or ref_status == "break_yaml"
      temp = {}
      temp.store("setting_version", "")
      temp.store("main_window_size", "")
      temp.store("main_paned_size", "")
      temp.store("main_window_state", "")
      temp.store("main_screen_number", "")
      temp.store("find_dialog_size", "")
      temp.store("toolbox_pos", "")
      temp.store("toolbox_visible", "")
      temp.store("klist_scroll_size", "")
      temp.store("layout_total_point", "")
      temp.store("find_radio", "")
      temp.store("db_mode", "")
      temp.store("db_host", "")
      temp.store("db_user", "")
      temp.store("db_pass", "")
      temp.store("db_panda", "")
      temp.store("dbfile_get", "")
      temp.store("dbfile_url", "")
      temp.store("dbfile_ca", "")
      temp.store("dbfile_path", "")
      temp.store("dbfile_mode", "")
      temp.store("api_host", "")
      temp.store("api_mode", "")
      temp.store("api_user", "")
      temp.store("api_pass", "")
      temp.store("api_ca", "")
      temp.store("api_crt", "")
      temp.store("api_pem", "")
      temp.store("api_phrase", "")
      temp.store("mount_dir", "")
      temp.store("mount_mode", "")
      temp.store("printer_no", "")
      temp.store("printer_name", "")
      temp.store("printer_method", "")
      temp.store("font_main", "")
      temp.store("font_info", "")
      temp.store("font_sick", "")
      temp.store("font_teki", "")
      temp.store("font_sub", "")
      temp.store("font_santei", "")
      temp.store("font_other", "")
      temp.store("font_preview", "")
      temp.store("file_history", "")
      temp.store("file_history_status", "")
      begin
        raise if ref_status == "break_yaml"
        file = open(filename)
        file.each do |line|
          # ([a-zA-Z0-9.-_]*)
          if /\s*main_window_size\s*=\s*([\w\W]*)/ =~ line
            temp["main_window_size"] = $1.sub(/\n$/,"")
          elsif /\s*main_paned_size\s*=\s*([\w\W]*)/ =~ line
            temp["main_paned_size"] = $1.sub(/\n$/,"")
          elsif /\s*main_window_state\s*=\s*([\w\W]*)/ =~ line
            temp["main_window_state"] = $1.sub(/\n$/,"")
          elsif /\s*main_screen_number\s*=\s*([\w\W]*)/ =~ line
            temp["main_screen_number"] = $1.sub(/\n$/,"")
          elsif /\s*find_dialog_size\s*=\s*([\w\W]*)/ =~ line
            temp["find_dialog_size"] = $1.sub(/\n$/,"")
          elsif /\s*toolbox_visible\s*=\s*([\w\W]*)/ =~ line
            temp["toolbox_visible"] = $1.sub(/\n$/,"")
          elsif /\s*toolbox_pos\s*=\s*([\w\W]*)/ =~ line
            temp["toolbox_pos"] = $1.sub(/\n$/,"")
          elsif /\s*klist_scroll_size\s*=\s*([\w\W]*)/ =~ line
            temp["klist_scroll_size"] = $1.sub(/\n$/,"")
          elsif /\s*layout_total_point\s*=\s*([\w\W]*)/ =~ line
            temp["layout_total_point"] = $1.sub(/\n$/,"")
          elsif /\s*find_radio\s*=\s*([\w\W]*)/ =~ line
            temp["find_radio"] = $1.sub(/\n$/,"")
          elsif /\s*db_mode\s*=\s*([\w\W]*)/ =~ line
            temp["db_mode"] = $1.sub(/\n$/,"")
          elsif /\s*db_host\s*=\s*([\w\W]*)/ =~ line
            temp["db_host"] = $1.sub(/\n$/,"")
          elsif /\s*db_user\s*=\s+([\w\W]*)/ =~ line
            temp["db_user"] = $1.sub(/\n$/,"")
          elsif /\s*db_pass\s*=\s+([\w\W]*)/ =~ line
            temp["db_pass"] = $1.sub(/\n$/,"")
          elsif /\s*db_panda\s*=\s+([\w\W]*)/ =~ line
            temp["db_panda"] = $1.sub(/\n$/,"")
          elsif /\s*dbfile_get\s*=\s+([\w\W]*)/ =~ line
            temp["dbfile_get"] = $1.sub(/\n$/,"")
          elsif /\s*dbfile_url\s*=\s+([\w\W]*)/ =~ line
            temp["dbfile_url"] = $1.sub(/\n$/,"")
          elsif /\s*dbfile_ca\s*=\s+([\w\W]*)/ =~ line
            temp["dbfile_ca"] = $1.sub(/\n$/,"")
          elsif /\s*dbfile_path\s*=\s+([\w\W]*)/ =~ line
            temp["dbfile_path"] = $1.sub(/\n$/,"")
          elsif /\s*dbfile_mode\s*=\s+([\w\W]*)/ =~ line
            temp["dbfile_mode"] = $1.sub(/\n$/,"")
          elsif /\s*api_host\s*=\s+([\w\W]*)/ =~ line
            temp["api_host"] = $1.sub(/\n$/,"")
          elsif /\s*api_mode\s*=\s+([\w\W]*)/ =~ line
            temp["api_mode"] = $1.sub(/\n$/,"")
          elsif /\s*api_user\s*=\s+([\w\W]*)/ =~ line
            temp["api_user"] = $1.sub(/\n$/,"")
          elsif /\s*api_pass\s*=\s+([\w\W]*)/ =~ line
            temp["api_pass"] = $1.sub(/\n$/,"")
          elsif /\s*api_ca\s*=\s+([\w\W]*)/ =~ line
            temp["api_ca"] = $1.sub(/\n$/,"")
          elsif /\s*api_crt\s*=\s+([\w\W]*)/ =~ line
            temp["api_crt"] = $1.sub(/\n$/,"")
          elsif /\s*api_pem\s*=\s+([\w\W]*)/ =~ line
            temp["api_pem"] = $1.sub(/\n$/,"")
          elsif /\s*api_phrase\s*=\s+([\w\W]*)/ =~ line
            temp["api_phrase"] = $1.sub(/\n$/,"")
          elsif /\s*mount_dir\s*=\s+([\w\W]*)/ =~ line
            temp["mount_dir"] = $1.sub(/\n$/,"")
          elsif /\s*printer_no\s*=\s+([\w\W]*)/ =~ line
            temp["printer_no"] = $1.sub(/\n$/,"")
          elsif /\s*printer_name\s*=\s+([\w\W]*)/ =~ line
            temp["printer_name"] = $1.sub(/\n$/,"")
          elsif /\s*printer_method\s*=\s+([\w\W]*)/ =~ line
            temp["printer_method"] = $1.sub(/\n$/,"")
          elsif /^font_main/ =~ line
            font_tmp = (line.split(/\=/)[1].to_s).sub(/^\s+/, "")
            if font_tmp == ""
              temp["font_main"] = "Sans 10"
            else
              temp["font_main"] = font_tmp.chomp
            end
          elsif /^font_info/ =~ line
            font_tmp = (line.split(/\=/)[1].to_s).sub(/^\s+/, "")
            if font_tmp == ""
              temp["font_info"] = "Sans 12"
            else
              temp["font_info"] = font_tmp.chomp
            end
          elsif /^font_sick/ =~ line
            font_tmp = (line.split(/\=/)[1].to_s).sub(/^\s+/, "")
            if font_tmp == ""
              temp["font_sick"] = "Sans 12"
            else
              temp["font_sick"] = font_tmp.chomp
            end
          elsif /^font_teki/ =~ line
            font_tmp = (line.split(/\=/)[1].to_s).sub(/^\s+/, "")
            if font_tmp == ""
              temp["font_teki"] = "Sans 12"
            else
              temp["font_teki"] = font_tmp.chomp
            end
          elsif /^font_sub/ =~ line
            font_tmp = (line.split(/\=/)[1].to_s).sub(/^\s+/, "")
            if font_tmp == ""
              temp["font_sub"] = "Sans 12"
            else
              temp["font_sub"] = font_tmp.chomp
            end
          elsif /^font_santei/ =~ line
            font_tmp = (line.split(/\=/)[1].to_s).sub(/^\s+/, "")
            if font_tmp == ""
              temp["font_santei"] = "Sans 12"
            else
              temp["font_santei"] = font_tmp.chomp
            end
          elsif /^font_other/ =~ line
            font_tmp = (line.split(/\=/)[1].to_s).sub(/^\s+/, "")
            if font_tmp == ""
              temp["font_other"] = "Sans 15"
            else
              temp["font_other"] = font_tmp.chomp
            end
          elsif /^font_preview/ =~ line
            font_tmp = (line.split(/\=/)[1].to_s).sub(/^\s+/, "")
            if font_tmp == ""
              temp["font_preview"] = "Serif 10"
            else
              temp["font_preview"] = font_tmp.chomp
            end
          elsif /\s*file_history\s*=\s+([\w\W]*)/ =~ line
            if $1.to_s.empty?
              temp["file_history"] = ""
            else
              temp["file_history"] << $1.chomp
            end
          elsif /\s*file_history_status\s*=\s+([\w\W]*)/ =~ line
            temp["file_history_status"] = $1.sub(/\n$/,"")
          else
            ReceViewLog.save("setting load [Item that doesn't exist]")
            ReceViewLog.save("setting data [#{line}]")
          end
        end
      rescue
        ReceViewLog.save("setting YAML broken error") if ref_status == "break_yaml"
        ReceViewLog.save("setting load error")
        if temp["main_window_size"].to_s.empty?
          temp["main_window_size"] = "0,0,1017,745"
        end
        if temp["main_paned_size"].to_s.empty?
          temp["main_paned_size"] = "400"
        end
        if temp["main_window_state"].to_s.empty?
          temp["main_window_state"] = "none"
        end
        if temp["main_screen_number"].to_s.empty?
          temp["main_screen_number"] = "0"
        end
        if temp["find_dialog_size"].to_s.empty?
          temp["find_dialog_size"] = "0,0,320,240"
        end
        if temp["toolbox_visible"].to_s.empty?
          temp["toolbox_visible"] = false
        end
        if temp["toolbox_pos"].to_s.empty?
          temp["toolbox_pos"] = [0, 0]
        end
        if temp["klist_scroll_size"].to_s.empty?
          temp["klist_scroll_size"] = 0
        end
        if temp["layout_total_point"].to_s.empty?
          temp["layout_total_point"] = 0
        end
        if temp["find_radio"].to_s.empty?
          temp["find_radio"] = "name"
        end
        if temp["db_mode"].to_s.empty?
          temp["db_mode"] = "2"
        end
        if temp["db_host"].to_s.empty?
          temp["db_host"] = "localhost"
        end
        if temp["db_user"].to_s.empty?
          temp["db_user"] = "ormaster"
        end
        if temp["db_pass"].to_s.empty?
          temp["db_pass"] = "ormaster"
        end
        if temp["dbfile_get"].to_s.empty?
          temp["dbfile_get"] = false
        end
        if temp["dbfile_url"].to_s.empty?
          temp["dbfile_url"] = "https://ftp.orca.med.or.jp/pub/receview/db/"
        end
        if temp["dbfile_ca"].to_s.empty?
          temp["dbfile_ca"] = ""
        end
        if temp["dbfile_path"].to_s.empty?
          temp["dbfile_path"] = "db/"
        end
        if temp["dbfile_mode"].to_s.empty?
          temp["dbfile_mode"] = 0
        end
        if temp["api_host"].to_s.empty?
          temp["api_host"] = "http://localhost:8000"
        end
        if temp["api_mode"].to_s.empty?
          temp["api_mode"] = false
        end
        if temp["api_user"].to_s.empty?
          temp["api_user"] = "ormaster"
        end
        if temp["api_pass"].to_s.empty?
          temp["api_pass"] = "ormaster"
        end
        if temp["api_ca"].to_s.empty?
          temp["api_ca"] = "/usr/lib/ssl"
        end
        if temp["api_crt"].to_s.empty?
          temp["api_crt"] = "/usr/lib/ssl"
        end
        if temp["api_pem"].to_s.empty?
          temp["api_pem"] = "/usr/lib/ssl"
        end
        if temp["api_phrase"].to_s.empty?
          temp["api_phrase"] = ""
        end
        if temp["printer_no"].to_s.empty?
          temp["printer_no"] = 0
        end
        if temp["printer_name"].to_s.empty?
          temp["printer_name"] = ""
        end
        if temp["printer_method"].to_s.empty?
          temp["printer_method"] = 0
        end
        if temp["file_history_status"].to_s.empty?
          temp["file_history_status"] = 0
        end
        if temp["font_main"].to_s.empty?
          temp["font_main"] = "Sans 12"
        end
        if temp["font_info"].to_s.empty?
          temp["font_info"] = "Sans 12"
        end
        if temp["font_sick"].to_s.empty?
          temp["font_sick"] = "Sans 12"
        end
        if temp["font_teki"].to_s.empty?
          temp["font_teki"] = "Sans 12"
        end
        if temp["font_sub"].to_s.empty?
          temp["font_sub"] = "Sans 12"
        end
        if temp["font_santei"].to_s.empty?
          temp["font_santei"] = "Sans 12"
        end
        if temp["font_other"].to_s.empty?
          temp["font_other"] = "Sans 15"
        end
        if temp["font_preview"].to_s.empty?
          temp["font_preview"] = "Serif 12"
        end
      end
      return temp
    else
      ref_yaml = setting_load_yaml(filename)
      ref_yaml["file_history"] = @base.replace_on_line_path_char(ref_yaml["file_history"])
      return ref_yaml
    end
  end

  def md5_make(view_data_pre, feature=false)
    if @history_version == 1 and !feature
      user_no = ""
    else
      user_no = view_data_pre.split(/\n|,/)[RE_USER_NO].to_s + "\n"
    end

    md5_indata = user_no + view_data_pre.sub(/^RE,[^\s]+\n/, "")
    return Digest::MD5.hexdigest(md5_indata).to_s
  end

  def md5_remake(view_data_pre, feature=false, md5=nil)
    if @history_version == 1 and feature
      return md5_make(view_data_pre, feature)
    else
      return md5
    end
  end
end

if __FILE__ == $0
end
