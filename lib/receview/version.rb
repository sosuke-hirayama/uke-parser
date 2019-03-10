# -*- encoding: utf-8 -*-

require 'jma/receview/generation'

if __FILE__ == $0
  case ARGV.last
  when 'gui', 'dialog', 'test'
    require 'jma/receview/gtk2_fix'
    require 'jma/receview/gui'
    require 'jma/receview/dialog'
    require 'jma/receview/yearconv'
    include YearConv
  end
end

# Version
class ReceViewVersion
  require 'jma/receview/env'
  require 'jma/receview/base'
  require 'jma/receview/config'
  require 'jma/receview/yearconv'
  require 'net/https'
  require 'uri'
  require "digest/md5"
  require "digest/sha2"

  include YearConv

  SETUP_NAME = "jma-receview.exe"
  PROGRAM_NAME = "jma-receview"
  VERSION = "2.1.18"
  LIB = "Gtk2+Ruby"+RUBY_VERSION.to_s
  CLIENT = "CLIENT"
  SERVER = "SERVER"
  CLIENT_SERVER = "CLIENT_SERVER"

  TIMEOUT_SMALL = 30
  TIMEOUT_LARGE = 1800

  PACKAGE = {
    CLIENT => ["jma-receview"],
    SERVER => ["jma-receview-server"],
    CLIENT_SERVER => ["jma-receview", "jma-receview-server"]
  }

  @@base = ReceView_Base.new
  @@local_download_size = 0
  @@remote_download_size = 0
  @@stream_download_size = 0
  @@last_error = []

  @@secure = true
  @@ca_file = @@base.secure_ca_file
  
  def initialize
    @version = VERSION
    @lib = LIB
    @program_name= PROGRAM_NAME
    @local_version = {}
    @online_version = {}
    @config = ReceViewConf.new
  end

  def ReceViewVersion::Error
    @@last_error
  end

  def ReceViewVersion::LastError
    if not @@last_error.last.nil?
      @@last_error.last.to_s
    else
      ""
    end
  end

  def ReceViewVersion::DownLoad_Size_Clear
    @@remote_download_size = 0
    @@local_download_size = 0
    @@stream_download_size = 0
    true
  end

  def ReceViewVersion::RemoteDownLoad_Size
    @@remote_download_size.to_s
  end

  def ReceViewVersion::LocalDownLoad_Size
    @@local_download_size.to_s
  end

  def ReceViewVersion::StreamDownLoad_Size
    @@stream_download_size.to_s
  end

  def ReceViewVersion::Check_URI(uri)
    case uri.scheme
    when "https"
      return true
    when "http"
      @@last_error.push("url_http_error")
      return false
    when "ftp"
      @@last_error.push("url_ftp_error")
      return false
    else
      @@last_error.push("url_other_error")
      raise "unexpected URI scheme: #{uri.scheme}"
      return false
    end
  end

  def ReceViewVersion::Dpkg_List(stance=CLIENT)
    version = ""
    if /linux/ =~ RUBY_PLATFORM.downcase
      package = PACKAGE[stance].first
      `dpkg -s #{package}`.split(/\n/).each do |e|
        if /^Version: (\d\.\d\.\d\S+)/ =~ e
          version = $1.to_s
        end
      end
    else
      version = VERSION
    end
    version
  end

  def ReceViewVersion::Update_Package_List
    file_list = {}
    file_list[SETUP_NAME] = ""
    if /linux/ =~ RUBY_PLATFORM.downcase
      gksu_msg = PROGRAM_NAME + @@base.msg_update["update_gksu"]
      if Gtk::platform_support_os_linux(Gtk::GTK_SUPPORT_VERSION_AMD64)
        file_list[SETUP_NAME] = system(%Q!LANG=C apt-get update > /dev/null!)
      else
        file_list[SETUP_NAME] = system(%Q!LANG=C gksu -k --message "#{gksu_msg}" "apt-get update" >/dev/null 2>&1!)
      end
    else
      ReceViewVersion.Get_Update_URL
      file_list = ReceViewVersion.Get_Update_URL_SHA256
    end
    file_list
  end

  def ReceViewVersion::Get_Update_URL
    user_update_file = [ENV['JRV_ETC'], ReceViewConf::UPDATE_CONF].join(@@base.path_char)
    if File.exist?(user_update_file)
      @config = ReceViewConf.new
      user_update_url = @config.setting_load_yaml(user_update_file)
      user_update_url.each do |key, user_url|
        if !user_url.to_s.empty?
          case key
          when "version_check_url"
            @@base.version_check_url = user_url
          when "version_md5_url"
            @@base.version_md5_url = user_url
          when "version_sha256_url"
            @@base.version_sha256_url = user_url
          when "version_base_url"
            @@base.version_base_url = user_url
          end
        end
      end
    end
    { "version_check_url" => @@base.version_check_url,
      "version_check_md5" => @@base.version_md5_url,
      "version_check_sha256" => @@base.version_sha256_url,
      "version_check_base" => @@base.version_base_url,
    }
  end

  def ReceViewVersion::Get_Update_URL_MD5
    file_list = {}
    url = ReceViewVersion.Get_Update_URL["version_check_md5"]
    if (web_data = ReceViewVersion::Get_File(url)).empty?
      file_list[SETUP_NAME] = ""
    else
      web_data.split(/\n/).each do |file_and_checksum|
        tfacs = file_and_checksum.split(/\s+/)
        file_list[tfacs[1].to_s] = tfacs[0].to_s
      end
    end
    return file_list
  end

  def ReceViewVersion::Get_Update_URL_SHA256
    file_list = {}
    url = ReceViewVersion.Get_Update_URL["version_check_sha256"]
    if (web_data = ReceViewVersion::Get_File(url)).empty?
      file_list[SETUP_NAME] = ""
    else
      web_data.split(/\n/).each do |file_and_checksum|
        tfacs = file_and_checksum.split(/\s+/)
        file_list[tfacs[1].to_s] = tfacs[0].to_s
      end
    end
    return file_list
  end

  def ReceViewVersion::Get_Update_URL_VERSION
    patch = Regexp.new(/^jma-receview (\d+.\d+.\d+) (jma\d+) ports/)
    url = ReceViewVersion.Get_Update_URL["version_check_url"]
    web_data = ReceViewVersion::Get_File(url)
    return web_data.gsub(/\n$/, "").scan(/#{patch}/).flatten[0].to_s
  end

  def ReceViewVersion::Check_Proof_FQDN(cert)
    cert_fqdn = cert.subject.to_s.scan(/CN=([-*.\w]+$)/).flatten.first
    p_fqdn = Regexp.new(/#{cert_fqdn.gsub(/\*/, "")}$/)
    request_fqdn = URI.parse(ReceViewVersion.Get_Update_URL["version_check_base"]).host

    if p_fqdn =~ request_fqdn
      return true
    else
      return false
    end
  end

  def ReceViewVersion::Get_File(url)
    web_file = ""
    Net::HTTP.version_1_2
    uri = URI.parse(url)

    if ReceViewVersion::Check_URI(uri)
      begin
        timeout(TIMEOUT_SMALL) {
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.ca_file = @@ca_file
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          http.verify_depth = 5
          http.start {
            raise unless ReceViewVersion::Check_Proof_FQDN(http.peer_cert)
            response = http.get(uri.request_uri)
            if response.code == "200"
              response.body.split(/\n/).each do |web_data|
                web_file << web_data
              end
            end
          }
        }
      rescue Timeout::Error => e
        @@last_error.push("timeout_error")
        web_file = ""
      rescue OpenSSL::SSL::SSLError => e
        @@last_error.push("url_https_error")
        web_file = ""
      rescue => e
        @@last_error.push(e)
        web_file = ""
      end
    end
    web_file
  end

  def ReceViewVersion::Get_File_TimeUniq_Name(url)
    time = Time.now
    ext_name = File.basename(url)
    rep_name = "-"+time.strftime("%Y%m%d%H%M%S") + time.usec.to_s + ".exe"
    return  ENV['TEMP']+"/"+ext_name.sub(/\.exe$/, rep_name)
  end

  def ReceViewVersion::Get_File_Streaming(file_url)
    ReceViewVersion.Get_Update_URL
    url = @@base.version_base_url + file_url
    filename = ReceViewVersion.Get_File_TimeUniq_Name(url)

    Net::HTTP.version_1_2
    uri = URI.parse(url)
    if ReceViewVersion::Check_URI(uri)
      begin
        download_data = ""
        download_md5 = ""
        download_sha256 = ""

        timeout(TIMEOUT_LARGE) {
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.ca_file = @@ca_file
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          http.verify_depth = 5

          request = Net::HTTP::Get.new(uri.path)
          http.request(request) do |response|
            raise unless ReceViewVersion::Check_Proof_FQDN(http.peer_cert)
            if response.code == "200"
              @@remote_download_size = response['Content-Length'].to_s
              response.read_body do |body_data|
                download_data << body_data
                @@stream_download_size = download_data.size
              end

              open(filename, 'wb') do |file|
                file << download_data
                @@local_download_size = file.tell.to_s
              end

              download_md5 = Digest::MD5.hexdigest(download_data)
              download_sha256 = Digest::SHA256.hexdigest(download_data)
            end
          end
        }
      rescue Timeout::Error => e
        @@last_error.push("timeout_error")
        filename = ""
      rescue OpenSSL::SSL::SSLError => e
        @@last_error.push("url_https_error")
        filename = ""
      rescue => e
        @@last_error.push(e)
        filename = ""
      end
    end

    return {
      "md5" => download_md5,
      "sha256" => download_sha256,
      "filename" => filename,
    }
  end

  def ReceViewVersion::Check(stances=[CLIENT])
    ReceViewVersion.Get_Update_URL

    if /linux/ =~ RUBY_PLATFORM.downcase
      @local_version, @online_version = ReceViewVersion.Check_Linux(stances)
    else
      @local_version, @online_version = ReceViewVersion.Check_Windows(stances)
    end

    return {
      "local"  => @local_version,
      "online" => @online_version,
    }
  end

  def ReceViewVersion::Check_Linux(stances=[CLIENT])
    local_version = {}
    online_version = {}
    if /linux/ =~ RUBY_PLATFORM.downcase
      gksu_msg = PROGRAM_NAME + @@base.msg_update["update_gksu"]
      if Gtk::platform_support_os_linux(Gtk::GTK_SUPPORT_VERSION_AMD64)
        system(%Q!LANG=C apt-get update > /dev/null!)
      else
        `LANG=C gksu -k --message "#{gksu_msg}" "apt-get update" >/dev/null 2>&1`
      end
      stances.each do |stance|
        PACKAGE[stance].each do |package|
          if Gtk::platform_support_os_linux(Gtk::GTK_SUPPORT_VERSION_AMD64)
             install_log = `LANG=C apt-get --force-yes -V -s -y install #{package} 2>&1`
          else
             install_log = `LANG=C gksu -k "apt-get --force-yes -V -s -y install #{package}" 2>&1`
          end
          install_log.split(/\n/).each do |status|
            if /^ +#{package} / =~ status
              if / => / =~ status
                data = status.gsub(/\r/, "").split(/  #{package} /)[1].to_s.split(/ => /)
                local_version[stance]  = data[0].gsub(/ |\(|\)/, "")
                online_version[stance] = data[1].gsub(/ |\)/, "")
              else
                data = status.gsub(/\r/, "").split(/  #{package} /)[1].to_s.split(/ \(/)
                local_version[stance]  = data[0].gsub(/ |\(|\)/, "")
                online_version[stance] = ""
              end
            end
          end
        end
      end
    end
    return local_version, online_version
  end

  def ReceViewVersion::Check_Windows(stances=[CLIENT])
    local_version = {}
    online_version = {}
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      web_version = ""
      stances = [ReceViewVersion::CLIENT]
      Net::HTTP.version_1_2
      begin
        timeout(TIMEOUT_SMALL) {
          web_version = ReceViewVersion.Get_Update_URL_VERSION
        }
      rescue Timeout::Error => e
        @@last_error.push("timeout_error")
        web_version = "0.0.0"
      rescue OpenSSL::SSL::SSLError => e
        @@last_error.push("url_https_error")
        web_version = "0.0.0"
      rescue => e
        @@last_error.push(e)
        web_version = "0.0.0"
      end

      stances.each do |stance|
        online_version[stance] = web_version
        local_version[stance] = VERSION.sub(/ rev\.\d+/, "")
      end

      local_version.each do |s, version|
        if !version.empty? and version != "0.0.0"
          v = version.split(/\./)
          local_version[s] = (v[0].to_i * 10000 + v[1].to_i * 100 + v[2].to_i).to_s
        end
      end

      online_version.each do |s, version|
        if !version.empty? and version != "0.0.0"
          v = version.split(/\./)
          online_version[s] = (v[0].to_i * 10000 + v[1].to_i * 100 + v[2].to_i).to_s
        end
      end
    end
    return local_version, online_version
  end

  def ReceViewVersion::Update(stances=[CLIENT])
    ReceViewVersion.Get_Update_URL
    status = {}

    if /linux/ =~ RUBY_PLATFORM.downcase
      gksu_msg = PROGRAM_NAME + @@base.msg_update["update_gksu"]
      if Gtk::platform_support_os_linux(Gtk::GTK_SUPPORT_VERSION_AMD64)
        system(%Q!LANG=C apt-get update > /dev/null!)
      else
        `LANG=C gksu -k --message "#{gksu_msg}" "apt-get update" >/dev/null 2>&1`
      end
      stances.each do |stance|
        PACKAGE[stance].each do |package|
          if Gtk::platform_support_os_linux(Gtk::GTK_SUPPORT_VERSION_AMD64)
            status[stance] = system("LANG=C apt-get --force-yes -y install #{package} 2>&1")
          else
            status[stance] = system("LANG=C gksu 'apt-get --force-yes -y install #{package}' 2>&1")
          end
        end
      end
    else
      stances = [ReceViewVersion::CLIENT]
      status = ReceViewVersion.Get_Update_URL_SHA256
    end
    status
  end

  def ReceViewVersion::Download(file_url, checksum)
    ref = ReceViewVersion::Get_File_Streaming(file_url)
    download_md5 = ref['md5']
    download_sha256 = ref['sha256']
    filename = ref['filename']

    case checksum.size
    when 32
      filename = "" if checksum != download_md5
    when 64
      filename = "" if checksum != download_sha256
    else
      filename = ""
    end
    return filename
  end

  def ReceViewVersion::Verify_Parse(verify_data)
    flg = ''
    verify_symbol = {}
    verify_data.gsub(/\r/, "").split(/\n/).each do |text|
      case text
      when /^Current PE checksum\s+:/
        string = text.split(/:/)[1].gsub(/^\s+/, '')
        verify_symbol[:Current_PE_checksum] = string.to_s
      when /^Calculated PE checksum:/
        string = text.split(/:/)[1].gsub(/^\s+/, '')
        verify_symbol[:Calculated_PE_checksum] = string.to_s
      when /^Message digest algorithm\s+:/
        string = text.split(/:/)[1].gsub(/^\s+/, '')
        verify_symbol[:Message_digest_algorithm] = string.to_s
      when /^Current message digest\s+:/
        string = text.split(/:/)[1].gsub(/^\s+/, '')
        verify_symbol[:Current_message_digest] = string.to_s
      when /^Calculated message digest\s+:/
        string = text.split(/:/)[1].gsub(/^\s+/, '')
        verify_symbol[:Calculated_message_digest] = string.to_s
      when /^Signature verification:/
        string = text.split(/:/)[1].gsub(/^\s+/, '')
        verify_symbol[:Signature_verification] = string.to_s
      when /^No signature found\./
        verify_symbol[:Signature_verification] = "no_sign"
      when /Number of signers:/
        string = text.split(/:/)[1].gsub(/^\s+/, '')
        string.to_i.times do
          if verify_symbol[:Number_of_signers].class == Array
            verify_symbol[:Number_of_signers].push("")
          else
            verify_symbol[:Number_of_signers] = [""]
          end
        end
      when /Signer/
        flg = 'Signer'
        verify_symbol[:Signer_No] = [] if verify_symbol[:Signer_No].class != Array
        string = text.scan(/Signer #(\d):/).flatten[0].gsub(/\s+/, '')
        verify_symbol[:Signer_No].push(string)
      when /Cert/
        flg = 'Cert'
        verify_symbol[:Cert_No] = [] if verify_symbol[:Cert_No].class != Array
        string = text.scan(/Cert #(\d):/).flatten[0].gsub(/\s+/, '')
        verify_symbol[:Cert_No].push(string)
      when /Subject:/
        verify_symbol[:Subject] = [] if verify_symbol[:Subject].class != Array
        string = text.split(/:/)[1].gsub(/^\s+/, '')
        verify_symbol[:Subject].push({"body"=>string, "flg"=>flg})
      when /Issuer :/
        verify_symbol[:Subject] = [] if verify_symbol[:Subject].class != Array
        string = text.split(/:/)[1].gsub(/^\s+/, '')
        verify_symbol[:Subject].push(string)
      when /^Succeeded$/
        verify_symbol[:Succeeded] = "exit"
      else
      end
    end
    return verify_symbol
  end

  def ReceViewVersion::Verify_Session(install_file)
    status = false
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      shell = WIN32OLE.new("WScript.Shell")
      begin
        # verify1
        # verify status stdout and console window popup.
        #sign_path = @@base.signcode_bin
        #verify_cmd = "\"#{sign_path}\" verify \"#{install_file}\""
        #verify_sh = shell.Exec(verify_cmd)
        #while verify_sh.Status.to_i == 0
        #  sleep 0.01
        #end
        #verify = {}
        #verify = ReceViewVersion::Verify_Parse(verify_sh.StdOut.ReadAll)
        #verify_sh.Terminate
        
        # verify2
        # verify status stdout and console window not popup.
        #sign_batch = @@base.signcode_bat
        #sign_path = @@base.signcode_bin
        #
        #sig_filename = uniq_Times+".sig"
        #sig_outfile = [ENV['TEMP'], sig_filename].join(@@base.path_char)
        #
        #verify_cmd = "cmd /s /c \"\"#{sign_batch}\" \"#{sign_path}\"  \"#{install_file}\" \"#{sig_outfile}\" \""
        #verify_flg = shell.Run(verify_cmd, 0, true)

        # verify3
        # verify status output file. non console window.
        sign_path = @@base.signcode_bin
        sig_filename = uniq_Times+".sig"
        sig_outfile = [ENV['TEMP'], sig_filename].join(@@base.path_char)
        verify_cmd = "\"#{sign_path}\" verify \"#{install_file}\" -out \"#{sig_outfile}\""
        verify_flg = shell.Run(verify_cmd, 0, true)

        if verify_flg
          sig_open = File.open(sig_outfile)
          verify = ReceViewVersion::Verify_Parse(sig_open.read)
          sig_open.close
          if File.exist?(sig_outfile)
            begin
              File.delete(sig_outfile)
            rescue
            end
          end
          if verify[:Signature_verification] == 'ok'
            verify[:Subject].each do |subjects|
              if subjects['flg']== 'Signer'
                if subjects['body'].to_s == @@base.signer
                  status = true
                else
                  status = false
                end
              end
            end
          else
            status = false
          end
        else
          status = false
        end
      rescue => e
        @@last_error.push(e)
        status = false
      end
    end
    return status
  end

  def ReceViewVersion::Install_Package(install_file)
    status = false
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      shell = WIN32OLE.new("WScript.Shell")
      begin
        status = shell.Run('"'+install_file+'"', 1, false)
        case status
        when 0
          status = true
        else
          status = false
        end
      rescue => e
        @@last_error.push(e)
        status = false
      end
    end
    status
  end

  def ReceViewVersion::Local_Version
    @local_version
  end

  def ReceViewVersion::Online_Version
    @online_version
  end

  def version_check
    ReceViewVersion::Check
  end

  def version_update
    ReceViewVersion::Update
  end

  def version_download(file_url, md5)
    ReceViewVersion::Download(file_url, md5)
  end

  def version_install_package(install_file)
    ReceViewVersion::Install_Package(install_file)
  end

  def ReceViewVersion::Text
    VERSION
  end

  def ReceViewVersion::Lib
    LIB
  end

  def ReceViewVersion::Program_Name
    PROGRAM_NAME
  end

  attr_reader :version
  attr_reader :lib
  attr_reader :program_name
end

if defined?(Gtk)

# VersionGUI
class ReceViewVersionGUI < Gtk::Dialog
  require 'jma/receview/env'
  require 'jma/receview/base'
  require 'jma/receview/gtk2_fix'

  def initialize(trans=nil)
    super()
    @base = ReceView_Base.new
    @package_status = false
    @proc_noupdate = true
    @download_thread = ThreadDummy.new
    @call_direct = false
    @trans = trans

    geometry = Gdk::Geometry.new
    geometry.set_min_width(360)
    geometry.set_min_height(280)
    geometry.set_max_width(360)
    geometry.set_max_height(280)
    mask = Gdk::Window::HINT_MIN_SIZE | 
           Gdk::Window::HINT_MAX_SIZE | Gdk::Window::HINT_RESIZE_INC
    self.set_title("JMA ReceView Updater")
    self.set_modal(true)
    self.set_transient_for(trans)
    self.set_geometry_hints(nil, geometry, mask)
    self.keep_above = true
    self.set_window_position(Gtk::Window::POS_CENTER)

    omsg = @base.msg_update["start"]
    @fixed = Gtk::Fixed.new
    @label_msg = Gtk::Label.new(omsg)
    @label_msg.set_size_request(-1, 200)
    @progress_bar = Gtk::ProgressBar.new
    @progress_bar.activity_mode = false
    @progress_bar.set_size_request(220, -1)
    @box = Gtk::HBox.new
    @vbox = Gtk::VBox.new(false)

    @image = ""
    image_list = ["jma-receview-icon.png", "/usr/share/pixmaps/jma-receview-icon.png"]
    image_list.each do |img_path|
      if File.exist?(img_path)
        @image = Gtk::Image.new(img_path)
        break
      end
    end

    @fixed.add(@progress_bar)
    @fixed.move(@progress_bar, 40, -20)

    @vbox.pack_start(@label_msg, true, false, 0)
    @vbox.pack_start(@fixed, true, false, 0)
    @box.pack_start(@image, false, false, 5)
    @box.pack_start(@vbox, true, true, 5)
    self.vbox.add(@box)

    @check_button = Gtk::Button.new("check")
    @update_button = Gtk::Button.new(:"update-gtk-refresh")
    @upstart_button = Gtk::Button.new(:"update-gtk-upstart")
    @close_button = Gtk::Button.new(Gtk::Stock::CLOSE)

    @update_button.set_image(Gtk::Image.new(Gtk::Stock::REFRESH, Gtk::IconSize::BUTTON))

    self.action_area.pack_start(@update_button)
    self.action_area.pack_start(@upstart_button)
    self.action_area.pack_start(@close_button)
    @update_button.set_sensitive(false)
    @upstart_button.set_sensitive(false)

    self.show_all
    @progress_bar.hide
    @upstart_button.hide

    self.event
    @stances = self.os_stances
  end

  def event
    @check_button.signal_connect("clicked") do
      self.update_list_exec
      if @package_status
        self.pre_update_exec
        if @package_status
          @update_button.set_sensitive(true)
        else
          @update_button.set_sensitive(false)
        end
      end
      @close_button.set_sensitive(true)
    end

    @update_button.signal_connect("clicked") do
      @update_button.set_sensitive(false)
      Thread.os do
        self.update_exec
      end
    end

    @upstart_button.signal_connect("clicked") do
      if @call_direct
        @package_status = true
        Gtk.main_quit
      else
        Thread.new do
          self.upstart_exec
        end
        Gtk.main_quit
      end
    end

    @close_button.signal_connect("clicked") do
      @download_thread.kill if @download_thread.class == Thread
      self.hide
      self.destroy
      if @call_direct
        @package_status = false
        Gtk.main_quit
      end
    end

    self.signal_connect("delete_event") do
      self.hide if @proc_noupdate
      if @call_direct
        @package_status = false
        Gtk.main_quit
      end
      true
    end
  end

  def os_stances
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      stances = [ReceViewVersion::CLIENT]
    else
      stances = [ReceViewVersion::CLIENT, ReceViewVersion::SERVER]
    end
    stances
  end

  def update_list_exec
    @proc_noupdate = false
    log_msg = ""
    @update_button.set_sensitive(false)
    @upstart_button.set_sensitive(false)
    if ReceViewVersion.Update_Package_List[ReceViewVersion::SETUP_NAME]
      log_msg += @base.msg_update["update"]
      @package_status = true
    else
      log_msg += @base.msg_update["update_fail"]
      log_msg += @base.msg_update[ReceViewVersion.LastError].to_s
      @package_status = false
    end
    @label_msg.set_markup(log_msg)
    @proc_noupdate = true
  end

  def pre_update_exec
    @proc_noupdate = false
    @package_status = false
    check_msg = ReceViewVersion.Check(@stances)
    log_msg = ""

    @stances.gtk_each do |stance|
      log_msg += @base.msg_update["tag_no_return"].sub(/BODY/, @base.msg_update["mark"])
      case stance
      when ReceViewVersion::CLIENT
        log_msg = self.pre_update_exec_client(stance, check_msg ,log_msg)
      when ReceViewVersion::SERVER
        log_msg = self.pre_update_exec_server(stance, check_msg, log_msg)
      end
    end
    @label_msg.set_markup(log_msg)
    @proc_noupdate = true
  end

  def pre_update_exec_client(stance, check_msg, log_msg)
    lserver = check_msg["local"][stance]
    oserver = check_msg["online"][stance]

    log_msg += @base.msg_update["tag"].sub(/BODY/, @base.msg_update["client_package_msg1"])
    log_msg += "\n"
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      if !lserver.to_s.empty? and oserver.to_i == 0
        log_msg += "  "
        log_msg += @base.msg_update["package_fail"]
        log_msg += "  "
        log_msg += @base.msg_update[ReceViewVersion.LastError].to_s
      elsif lserver.to_i >= oserver.to_i
        log_msg += @base.msg_update["present_version"].sub(/VERSION/, int2ver(lserver))
        log_msg += "  "
        log_msg += @base.msg_update["client_new"]
      else
        log_msg += "  "
        log_msg += @base.msg_update["update_exist"]
        log_msg += "\n"
        log_msg += @base.msg_update["present_version"].sub(/VERSION/, int2ver(lserver))
        log_msg += @base.msg_update["new_version"].sub(/VERSION/, int2ver(oserver))
        @package_status = true
      end
    else
      if lserver.to_s.empty? and oserver.to_s.empty?
        dpkg_version = ReceViewVersion::Dpkg_List(stance)
        log_msg += @base.msg_update["present_version"].sub(/VERSION/, dpkg_version)
        log_msg += "  "
        log_msg += @base.msg_update["client_new"]
      elsif !lserver.to_s.empty? and oserver.to_s.empty?
        log_msg += "  "
        log_msg += @base.msg_update["package_fail"]
      else
        log_msg += "  "
        log_msg += @base.msg_update["update_exist"]
        log_msg += "\n"
        log_msg += @base.msg_update["present_version"].sub(/VERSION/, lserver)
        log_msg += @base.msg_update["new_version"].sub(/VERSION/, oserver)
        @package_status = true
      end
    end
    log_msg += "\n"
    return log_msg
  end

  def pre_update_exec_server(stance, check_msg, log_msg)
    lserver = check_msg["local"][stance]
    oserver = check_msg["online"][stance]

    log_msg += @base.msg_update["tag"].sub(/BODY/, @base.msg_update["server_package_msg1"])
    log_msg += "\n"
    if lserver.to_s.empty? and oserver.to_s.empty?
      dpkg_version = ReceViewVersion::Dpkg_List(stance)
      log_msg += @base.msg_update["present_version"].sub(/VERSION/, dpkg_version)
      log_msg += "  "
      log_msg += @base.msg_update["server_new"]
    elsif !lserver.to_s.empty? and oserver.to_s.empty?
      log_msg += "  "
      log_msg += @base.msg_update["server_package_no"]
    else
      log_msg += "  "
      log_msg += @base.msg_update["update_exist"]
      log_msg += "\n"
      log_msg += @base.msg_update["present_version"].sub(/VERSION/, lserver)
      log_msg += @base.msg_update["new_version"].sub(/VERSION/, oserver)
      @package_status = true
    end
    log_msg += "\n"
    return log_msg
  end

  def update_exec
    @proc_noupdate = false
    msg_t = "JMA ReceView Updater"
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      msg_b = @base.msg_update["win_restart"]
    else
      msg_b = @base.msg_update["linux_restart"]
    end

    @rd = ReceView_Dialog.new
    dmsg = @rd.dialog_message_fixed(self, msg_t, msg_b, "no")
    dmsg.signal_connect("response") do |widget, response|
      case response
      when Gtk::Dialog::RESPONSE_OK
        dmsg.hide
        dmsg.destroy
        if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
          omsg = @base.msg_update["download"]
        else
          omsg = @base.msg_update["upgrade"]
        end
        @label_msg.set_markup(omsg)
        @download_thread = ThreadDummy.new

        Thread.os do
          upgrade_exec
        end
      else
        dmsg.hide
        dmsg.destroy
      end
    end
    dmsg.show_all
    @proc_noupdate = true
  end

  def upgrade_exec
    @proc_noupdate = false
    @update_flg = false
    local_version = ReceViewVersion.Local_Version
    online_version = ReceViewVersion.Online_Version
    log_msg = ""

    @stances.gtk_each do |stance|
      if local_version[stance] != nil and online_version[stance] != nil
        log_msg += @base.msg_update["tag_no_return"].sub(/BODY/, @base.msg_update["mark"])
        case stance
        when ReceViewVersion::CLIENT
          log_msg = self.upgrade_exec_client(log_msg, stance, local_version, online_version)
        when ReceViewVersion::SERVER
          log_msg = self.upgrade_exec_server(log_msg, stance, local_version, online_version)
        end
      end
    end

    self.upgrade_exec_widget(@update_flg)

    begin 
      @label_msg.set_markup(log_msg)
    rescue TypeError
    end

    @proc_noupdate = true
  end

  def upgrade_exec_client(log_msg, stance, local_ver, online_ver)
    log_msg += @base.msg_update["tag"].sub(/BODY/, @base.msg_update["client_package_msg2"])
    log_msg += "\n"

    update_status = ReceViewVersion.Update
    if update_status[stance]
      log_msg += @base.msg_update["update_success"]
      log_msg += "\n"
      log_msg += @base.msg_update["old_version"].sub(/VERSION/, local_ver[stance])
      log_msg += @base.msg_update["pre_version"].sub(/VERSION/, online_ver[stance])
      @update_flg = true
    else
      if /linux/ =~ RUBY_PLATFORM.downcase
        log_msg += @base.msg_update["error"]
      else
        update_status.each do |name, checksum|
          @progress_bar.show
          @label_msg.set_markup("\n"*7+@label_msg.text)
          dl_thread_flg = true
          install_file = ""

          @download_thread = Thread.new do
            install_file = ReceViewVersion::Download(name, checksum).to_s
            dl_thread_flg = false 
          end

          server_dl_size = 0
          while dl_thread_flg
            if ReceViewVersion.RemoteDownLoad_Size.to_i != 0
              if not Thread::platform_support_thread
                Gtk.iteration
              end
              server_dl_size = ReceViewVersion.RemoteDownLoad_Size.to_i / 1000
              server_dl_size = 0 if server_dl_size.to_i < 0
              break
            end
            sleep 0.01
          end

          stream_dl_size = 0
          while dl_thread_flg
            if not Thread::platform_support_thread
              Gtk.iteration
            end
            stream_dl_size = ReceViewVersion.StreamDownLoad_Size.to_i / 1000
            relative_size = (stream_dl_size.to_f/server_dl_size.to_f*100).to_s.sub(/\.\S+$/, "")
            prog_text = "#{stream_dl_size.to_s}KByte / #{server_dl_size.to_s}KByte (#{relative_size}%)"
            begin 
              @progress_bar.set_text(prog_text)
              @progress_bar.set_fraction(relative_size.to_f / 100)
            rescue TypeError => e
              install_file = ""
              dl_thread_flg = false 
              break
            end
            sleep 0.02
          end

          if not Thread::platform_support_thread
            Gtk.iteration
          end
          log_msg += @base.msg_update["win_update_download"]
          sleep 1.0

          if not install_file.empty?
            log_msg += @base.msg_update["win_checksum_ok"]
            if ReceViewVersion::Verify_Session(install_file)
              log_msg += @base.msg_update["win_update_signcode"]
              if ReceViewVersion::Install_Package(install_file)
                log_msg += @base.msg_update["win_update_program"]
                @upstart_button.signal_emit("clicked")
              else
                log_msg += @base.msg_update["installer_error"]
              end
            else
              log_msg += @base.msg_update["sign_error"]
            end
          else
            case checksum.size
            when 32
              log_msg += @base.msg_update["md5_error"]
            when 64
              log_msg += @base.msg_update["sha256_error"]
            else
              log_msg += @base.msg_update["checksum_error"]
            end
            begin 
              @label_msg.set_markup(log_msg)
            rescue TypeError => e
            end
          end
        end
      end
    end
    log_msg += "\n"
    return log_msg
  end

  def upgrade_exec_server(log_msg, stance, local_ver, online_ver)
    if /linux/ =~ RUBY_PLATFORM.downcase
      log_msg += @base.msg_update["tag"].sub(/BODY/, @base.msg_update["server_package_msg2"])
      log_msg += "\n"
      if local_ver[stance].to_s.empty? and online_ver[stance].to_s.empty?
        log_msg += @base.msg_update["server_new"]
      elsif !local_ver[stance].to_s.empty? and online_ver[stance].to_s.empty?
        log_msg += @base.msg_update["server_package_no"]
      else
        if ReceViewVersion.Update([stance])[stance]
          log_msg += @base.msg_update["update_success"]
          log_msg += "\n"
          log_msg += @base.msg_update["old_version"].sub(/VERSION/, local_ver[stance])
          log_msg += @base.msg_update["pre_version"].sub(/VERSION/, online_ver[stance])
          @update_flg = true
        else
          log_msg += @base.msg_update["error"]
        end
      end
    end
    return log_msg
  end

  def upgrade_exec_widget(flg)
    if flg
      @upstart_button.show
      @close_button.set_sensitive(false)
      @upstart_button.set_sensitive(true)
      @update_button.set_sensitive(false)
      @update_button.hide
      @progress_bar.hide
    end
  end

  def upstart_exec
    @base.up_scripts.each do |reboot_exec|
      if File.exist?(reboot_exec)
        if /linux/ =~ RUBY_PLATFORM.downcase
          `ruby #{reboot_exec}`
        end
        break
      end
    end
  end

  attr_accessor :call_direct
  attr_accessor :check_button
  attr_accessor :update_button
  attr_accessor :upstart_button
  attr_accessor :close_button
  attr_accessor :package_status
  attr_accessor :proc_noupdate
  attr_accessor :download_thread
end

end

if __FILE__ == $0
  require 'yaml'
  require 'jma/receview/env'
  require 'jma/receview/base'

  base = ReceView_Base.new
  if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
    ENV['JRV_ETC'] = [base.get_path, "etc"].join(base.path_char)
  else
    ENV['JRV_ETC'] = "/etc/jma-receview"
  end

  case ARGV.last
  when 'gui'
    require 'jma/receview/intconv'
    include IntConv

    gui = ReceViewGUI.new
    gui.init_gtk_stock
    dialog = ReceViewVersionGUI.new
    ReceViewGUI::SettingIcon(dialog)
    dialog.call_direct = true

    Thread.new do
      dialog.proc_noupdate = false
      dialog.close_button.set_sensitive(false)
      sleep 2
      dialog.check_button.signal_emit("clicked")
    end

    gui.main_loop

    if dialog.package_status == true
      exit 0
    else
      exit 1
    end
  when "dialog"
    ReceViewVersionGUI.new
    Gtk.main
    exit
  when 'test'
    # Test Setting URLFile.
    user_update_file = [ENV['JRV_ETC'], ReceViewConf::UPDATE_CONF].join(base.path_char)
    p "user_update_file: #{user_update_file}"

    if /linux/ =~ RUBY_PLATFORM.downcase
      verify_1 = ReceViewVersion::Verify_Parse(`cat osssign.log`)
      verify_2 = ReceViewVersion::Verify_Parse(`cat osssign_false.log`)
      p verify_1[:Signature_verification]
      p verify_2[:Signature_verification]
    else
      #install_file = "Z:/gtk/jma-receview-2_1_3.exe"
      #p ReceViewVersion::Verify_Session(install_file)
      #install_file = "Z:/gtk/jma-receview-2_1_4.exe"
      #p ReceViewVersion::Verify_Session(install_file)
      install_file = "C:\\jma-receview-2_1_4.exe"
      p ReceViewVersion::Verify_Session(install_file)
    end

    # Test GetUpdateURL,checksum
    p ReceViewVersion.Get_Update_URL_MD5
    p ReceViewVersion.Get_Update_URL_SHA256
    p ReceViewVersion.Get_Update_URL_VERSION

    # Test Package List Download [Windows Methotds for Linux]
    if /linux/ =~ RUBY_PLATFORM.downcase
      RUBY_PLATFORM = "mswin32"
      ENV['TEMP'] = "/tmp"
      p ReceViewVersion.Update_Package_List[ReceViewVersion::SETUP_NAME]
      RUBY_PLATFORM = "linux"
      p ReceViewVersion.Update_Package_List[ReceViewVersion::SETUP_NAME]
    end

    # HTTPS Test Access
    https = Net::HTTP.new('www.orca.med.or.jp',443)
    https.use_ssl = true
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      https.ca_file = 'c:/cert.pem'
      https.ca_file = 'c:/Program Files/jma-receview/etc/cert.pem'
    else
      https.ca_file = '/usr/lib/ssl/cert.pem'
    end
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    https.verify_depth = 5
    https.start {
      puts https.peer_cert.not_after
      response = https.get('/')
      response.body
    }
    sleep 2

    # Test Download [Windows Methotds for Linux]
    if /linux/ =~ RUBY_PLATFORM.downcase
      ENV['TEMP'] = "/tmp"
      dl_thread_flg = true

      Thread.new do
        p ReceViewVersion.Download("jma-receview.exe", "62e78d325afc5ae63903c282fdc9d39f")
        p "Donwload done."
        dl_thread_flg = false 
      end

      while dl_thread_flg
        if ReceViewVersion.RemoteDownLoad_Size.to_i != 0
          p ReceViewVersion.RemoteDownLoad_Size
          break
        end
        sleep 0.01
      end

      while dl_thread_flg
        p ReceViewVersion.StreamDownLoad_Size
        sleep 0.02
      end
    end

=begin
    # Other Test.
    p ReceViewVersion::Dpkg_List(ReceViewVersion::CLIENT)
    p ReceViewVersion::Dpkg_List(ReceViewVersion::SERVER)
    p ReceViewVersion.Check([ReceViewVersion::CLIENT])
    p ReceViewVersion.Get_Update_URL_MD5
    p ReceViewVersion.Get_Update_URL_SHA256
    p ReceViewVersion.Update_Package_List

    #p ReceViewVersion.Update([ReceViewVersion::CLIENT])
    #p ReceViewVersion.Download("jma-receview.exe", "31f36c9500b4a1f9003c955b1e3d9bbf")
    #p ReceViewVersion.Download("jma-receview.exe", "75a72326224d4991fcd64dbcf8ecd494a8e4bb912b4b5c03e25d7c7d72ebb908")
=end
  end
end
