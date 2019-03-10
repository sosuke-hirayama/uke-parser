# -*- encoding: utf-8 -*-

require 'jma/receview/generation'

# Other CSV View
class Other_CSV
  attr_accessor :view
  TITLE = "Other CSV"

  def initialize
    begin
      require 'jma/receview/gtk2_fix'
    rescue Gtk::InitError
      print 'Gtk::InitError'
      exit 0
    end
    @lib_cdio = false
    @window = Gtk::Window.new
    @sw = Gtk::ScrolledWindow.new
    @view = Gtk::TextView.new
    @vbox = Gtk::VBox.new(true, 50)
    @sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    @view = Gtk::TextView.new
    @sw.add(@view)
    @vbox.add(@sw)
    @window.add(@vbox)

    # Option
    @view.editable = false
    @view.set_border_window_size(Gtk::TextView::WINDOW_LEFT, 2)
    @view.set_border_window_size(Gtk::TextView::WINDOW_RIGHT, 2)
    @view.set_border_window_size(Gtk::TextView::WINDOW_TOP, 2)
    @view.set_border_window_size(Gtk::TextView::WINDOW_BOTTOM, 2)
    @view.set_left_margin(10)
    @view.set_right_margin(10)

    @window.set_title("Other CSV View")
    @window.resize(640,480)
    @window.show_all
  end

  def set_libcdio(s=false)
    @lib_cdio = s
  end

  def event
    @window.signal_connect("delete_event") do
      false
    end

    @window.signal_connect("destroy") do
      Gtk.main_quit
    end
  end

  def gtk_loops
    Gtk.init
    Gtk.main_with_queue(100)
    #Gtk.main
  end

  def fileselect
    @fs = Gtk::FileSelection.new(TITLE)
  end

  def read(csvfile, pattern='99999999.csv')
    if File.exist?(csvfile)
      if @lib_cdio and /\.(iso|ISO)$/ =~ csvfile
        if (csv = ISOCDImage.open(csvfile, pattern)) == false
          csv = "Error: ISOファイルを読み込めませんでした。\n"
          csv += "FilePath:#{csvfile}\n"
          csv += "FilePattern: #{pattern}\n"
          csv += "参照先: '#{csvfile}->#{pattern}'\n\n"
          csv += "filelist:\n"
          ISOCDImage.list(csvfile).each do |file|
            csv += sprintf("%-2s"+file+"\n", "")
          end
          csv.rstrip!
        end
      else
        csv_o = open(csvfile)
        csv = csv_o.read
        csv_o.close
      end
    else
      path = File.dirname(csvfile)
      Dir::foreach(path) do |val|
        if val != "." and val != ".."
          begin
            if /#{pattern}/ =~ val
              csv_o = open([path, val].join("/"))
              csv = csv_o.read
              csv_o.close
              break
            end
          rescue
            csv = "#{csvfile}: ファイルパターン指定が不正です。\n"
            csv += "ファイルパターン: #{pattern}"
            break
          end
        end
      end
      if !csv.nil?
        if csv.empty?
          csv = "#{csvfile}: ファイルがありません。"
        end
      else
        csv = "#{csvfile}: ファイルがありません。"
      end
    end
    return csv
  end
end

class Other_CSV::PreCheck
  def initialize(filename)
    @filename = filename
    @othercsv_flg = false
  end

  def check(filename=@filename)
    @othercsv_flg = true

    if filename.empty?
      @othercsv_flg = false
    else
      @othercsv_flg = false if not check_filename(filename)

      if File.exist?(filename)
        if not File.directory?(filename)
          File.open(filename).read.toutf8.encode!("UTF-8").split(/\n/).each_with_index do |text, index|
            csv = text.gsub(/(\n|\r|\000)$/, "").split(/,/, -1)
            case index
            when 0
              if not check_gyymm(csv[7].to_s)
                @othercsv_flg = false
              end
            else
              if not(/\d+/ =~ csv[0].to_s)
                @othercsv_flg = false
              end
              if not(/\d+/ =~ csv[1].to_s)
                @othercsv_flg = false
              end
            end
          end
        end
      else
        @othercsv_flg = false
      end
    end
    return @othercsv_flg
  end

  def check_filename(filename)
    ref = false
    checkname = File.basename(filename).to_s
    if not checkname.empty?
      if not(/\d{2}*receiptc\.uke/ =~ checkname.downcase)
        if /^\d+\.(csv|uke|iso)$/ =~ checkname.downcase
          return true
        end
      end
    end
    return ref
  end

  def check_gyymm(gym)
    gym_arr = gym.split(/(\d{2})(\d{2})$/)
    gyymm_flg = true

    if not gym.size == 5
      gyymm_flg = false
    end

    if not gym_arr[0].to_i >= 4
      gyymm_flg = false
    end

    if not gym_arr[1].to_i >= 25
      gyymm_flg = false
    end
    return gyymm_flg
  end
end
