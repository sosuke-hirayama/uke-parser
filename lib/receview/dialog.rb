# -*- encoding: utf-8 -*-

require 'jma/receview/generation'

class ReceView_Dialog
  def initialize
    require 'jma/receview/gtk2_fix'
    require 'jma/receview/base'
    require 'jma/receview/dbslib'
    require 'jma/receview/gui'

    @base = ReceView_Base.new
    @path_char = @base.path_char
  end

  def windows_shell(shell)
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      @windows_shell = shell
    end
  end

  def main
    Gtk.main_with_queue(100)
  end

  def dialog_textview(trans="", title="")
    geometry = Gdk::Geometry.new
    geometry.set_min_width(480)
    geometry.set_min_height(420)
    geometry.set_max_width(480)
    geometry.set_max_height(420)
    mask = Gdk::Window::HINT_MIN_SIZE |
           Gdk::Window::HINT_MAX_SIZE | Gdk::Window::HINT_RESIZE_INC

    dialog = Gtk::Dialog.new
    dialog.set_title(title)
    dialog.set_modal(true)            
    ReceViewGUI::SettingIcon(dialog)
    ReceViewGUI::TransWindow(dialog, trans)

    sw   = Gtk::ScrolledWindow.new
    view = Gtk::TextView.new
    vbox = Gtk::VBox.new(true, 50)
    sw.add(view)
    vbox.add(sw)
    dialog.vbox.add(vbox)

    dialog.set_geometry_hints(nil, geometry, mask)
    dialog.add_button(Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK)
    dialog.set_default_response(Gtk::Dialog::RESPONSE_CANCEL)

    dialog.signal_connect("response") do |widget, response|
      case response
      when Gtk::Dialog::RESPONSE_OK
        dialog.hide
      end
    end 

    return {
      "dialog" => dialog, 
      "view" => view,
    }
  end

  def dialog_message(trans=nil, title="", msg="", mode="ok", stract=nil)
    geometry = Gdk::Geometry.new
    geometry.set_min_width(360)
    geometry.set_min_height(160)
    geometry.set_max_width(360)
    geometry.set_max_height(160)
    mask = Gdk::Window::HINT_MIN_SIZE |
           Gdk::Window::HINT_MAX_SIZE #| Gdk::Window::HINT_RESIZE_INC

    dialog = Gtk::Dialog.new
    dialog.set_title(title)
    dialog.set_modal(true)            
    ReceViewGUI::SettingIcon(dialog)
    ReceViewGUI::TransWindow(dialog, trans)

    box = Gtk::HBox.new
    image = Gtk::Image.new
    label_msg = Gtk::Label.new(msg)

    image.set(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
    box.pack_start(image, false, false, 5)
    box.pack_start(label_msg, true, false, 5)
    dialog.vbox.add(box)

    dialog.set_geometry_hints(nil, geometry, mask)
    
    dialog.add_button(Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK)

    if mode.class == Hash
      dialog.add_button(mode["stock"], mode["response"])
    else
      if mode != "ok"
        dialog.add_button(Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL)
      end
    end
    dialog.set_default_response(Gtk::Dialog::RESPONSE_CANCEL)

    dialog.signal_connect("delete_event") do
      true
    end

    if stract == "hash"
      return {
        "dialog" => dialog,
        "msg" => label_msg,
      }
    else
      dialog
    end
  end

  def dialog_message_fixed(trans=nil, title="", msg="", mode="ok", stract=nil)
    geometry = Gdk::Geometry.new
    geometry.set_min_width(320)
    geometry.set_min_height(160)
    geometry.set_max_width(320)
    geometry.set_max_height(160)
    mask = Gdk::Window::HINT_MIN_SIZE |
           Gdk::Window::HINT_MAX_SIZE #| Gdk::Window::HINT_RESIZE_INC

    dialog = Gtk::Dialog.new
    dialog.set_title(title)
    dialog.set_modal(true)            
    dialog.set_keep_above(true)
    ReceViewGUI::SettingIcon(dialog)
    ReceViewGUI::TransWindow(dialog, trans)

    box = Gtk::HBox.new
    image = Gtk::Image.new
    label_msg = Gtk::Label.new(msg)

    image.set(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
    box.pack_start(image, false, false, 5)
    box.pack_start(label_msg, true, false, 5)
    dialog.vbox.add(box)

    dialog.set_geometry_hints(nil, geometry, mask)
    
    dialog.add_button(Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK)

    if mode.class == Hash
      dialog.add_button(mode["stock"], mode["response"])
    else
      if mode != "ok"
        dialog.add_button(Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL)
      end
    end
    dialog.set_default_response(Gtk::Dialog::RESPONSE_CANCEL)

    dialog.signal_connect("delete_event") do
      true
    end

    if stract == "hash"
      return {
        "dialog" => dialog,
        "msg" => label_msg,
      }
    else
      dialog
    end
  end

  def dialog_message_list(trans=nil, title="", msg="", mode="ok", stract=nil)
    geometry = Gdk::Geometry.new
    geometry.set_min_width(320)
    geometry.set_min_height(280)
    geometry.set_max_width(320)
    geometry.set_max_height(360)
    mask = Gdk::Window::HINT_MIN_SIZE |
           Gdk::Window::HINT_MAX_SIZE | Gdk::Window::HINT_RESIZE_INC

    dialog = Gtk::Dialog.new
    dialog.set_title(title)
    dialog.set_modal(true)            
    ReceViewGUI::SettingIcon(dialog)
    ReceViewGUI::TransWindow(dialog, trans)

    box = Gtk::HBox.new
    vbox = Gtk::VBox.new
    image = Gtk::Image.new
    status_frame = Gtk::Frame.new("詳細情報")
    label_msg = Gtk::Label.new(msg)
    status_msg = Gtk::Label.new('')

    status_frame.add(status_msg)
    image.set(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
    vbox.pack_start(label_msg, true, false, 5)
    vbox.pack_start(status_frame, false, false, 5)
    box.pack_start(image, false, false, 5)
    box.pack_start(vbox, true, false, 5)
    dialog.vbox.add(box)

    dialog.set_geometry_hints(nil, geometry, mask)
    
    dialog.add_button(Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK)

    if mode.class == Hash
      dialog.add_button(mode["stock"], mode["response"])
    else
      if mode != "ok" && mode != "list"
        dialog.add_button(Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL)
      end
    end
    dialog.set_default_response(Gtk::Dialog::RESPONSE_CANCEL)

    dialog.signal_connect("delete_event") do
      true
    end

    if stract == "hash"
      return {
        "dialog" => dialog,
        "msg" => label_msg,
        "status" => status_msg,
        "frame" => status_frame,
      }
    else
      dialog
    end
  end

  def dialog_wait(trans=nil, title="", msg="")
    geometry = Gdk::Geometry.new
    geometry.set_min_width(320)
    geometry.set_min_height(160)
    geometry.set_max_width(320)
    geometry.set_max_height(160)
    mask = Gdk::Window::HINT_MIN_SIZE |
           Gdk::Window::HINT_MAX_SIZE | Gdk::Window::HINT_RESIZE_INC

    dialog = Gtk::Dialog.new
    dialog.set_title(title)
    dialog.set_modal(true)            
    dialog.set_has_separator(false)
    ReceViewGUI::SettingIcon(dialog)
    ReceViewGUI::TransWindow(dialog, trans)
=begin
    if trans.class == Gtk::Window or trans.class == Gtk::Dialog
      dialog.set_transient_for(trans)
    end
=end

    box = Gtk::HBox.new
    image = Gtk::Image.new
    image.set(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
    label_msg = Gtk::Label.new(msg)
    box.pack_start(image, false, false, 5)
    box.pack_start(label_msg, false, false, 5)
    dialog.vbox.add(box)

    dialog.set_geometry_hints(nil, geometry, mask)

    dialog.signal_connect("delete_event") do
      true
    end

    return {
      "dialog" => dialog,
      "msg" => label_msg,
    }
  end

  def set_dialog_layout_data(combo_active=0)
    @layout_combo_active = combo_active.to_i
    @layout_active_flg = combo_active.to_i
  end

  def dialog_layout(trans="", title="")
    geometry = Gdk::Geometry.new
    geometry.set_min_width(160)
    geometry.set_min_height(60)
    geometry.set_max_width(160)
    geometry.set_max_height(60)
    mask = Gdk::Window::HINT_MIN_SIZE | 
           Gdk::Window::HINT_MAX_SIZE | Gdk::Window::HINT_RESIZE_INC
    dialog = Gtk::Dialog.new
    dialog.set_title(title)
    dialog.set_modal(true)            
    ReceViewGUI::SettingIcon(dialog)
    ReceViewGUI::TransWindow(dialog, trans)
    
    # "指定なし",
    # "広域連合をまとめる"
    label_title = Gtk::Label.new("点数種別情報")
    label_res   = Gtk::Label.new("広域連合表示設定:")
    combo = Gtk::ComboBox.new

    @base.layout_combo.each_with_index do |val,index|
      combo.append_text(val)
    end
    combo.active = @layout_combo_active

    label_title.set_justify(Gtk::JUSTIFY_LEFT)

    hbox1 = Gtk::HBox.new
    hbox2 = Gtk::HBox.new
    vbox  = Gtk::VBox.new

    hbox2.pack_start(label_title, false, true, 5)
    hbox1.pack_start(label_res, false, true, 5)
    hbox1.pack_start(combo, true, true, 5)

    ok_button = Gtk::Button.new(Gtk::Stock::OK)
    ajs_button = Gtk::Button.new(Gtk::Stock::APPLY)
    cancel_button = Gtk::Button.new(Gtk::Stock::CLOSE)

    vbox.pack_start(hbox2, false, false, 5)
    vbox.pack_start(hbox1, true, false, 5)

    dialog.action_area.pack_start(ok_button)
    dialog.action_area.pack_start(ajs_button)
    dialog.action_area.pack_start(cancel_button)
    dialog.vbox.pack_start(vbox)

    accel = Gtk::AccelGroup.new
    accel.connect(Gdk::Keyval::GDK_C, Gdk::Window::CONTROL_MASK,
      Gtk::ACCEL_VISIBLE) do
        cancel_button.signal_emit("clicked")
    end
    dialog.add_accel_group(accel)

    dialog.set_geometry_hints(ok_button, geometry, mask)

    cancel_button.signal_connect("clicked") do
      dialog.hide
    end

    dialog.signal_connect("delete_event") do
      dialog.hide
      true
    end

    return {
      "dialog" => dialog,
      "combo" => combo,
      "ok_button" => ok_button,
      "ajs_button" => ajs_button,
      "cancel_button" => cancel_button,
    }
  end

  def set_dialog_command(mount_dir)
    @command_mount_dir = mount_dir.to_s
  end

  def set_dialog_command_mode(mount_mode)
    @command_mount_mode = mount_mode
  end

  def dialog_command(trans="", title="")
    geometry = Gdk::Geometry.new
    geometry.set_min_width(160)
    geometry.set_min_height(60)
    geometry.set_max_width(160)
    geometry.set_max_height(60)
    mask = Gdk::Window::HINT_MIN_SIZE | 
           Gdk::Window::HINT_MAX_SIZE | Gdk::Window::HINT_RESIZE_INC
    dialog = Gtk::Dialog.new
    dialog.set_title(title)
    dialog.set_modal(true)            
    ReceViewGUI::SettingIcon(dialog)
    ReceViewGUI::TransWindow(dialog, trans)

    label_mount = Gtk::Label.new(sprintf("Mount Dir:%-3s",""))
    entry_mount = Gtk::Entry.new
    label_space = Gtk::Label.new(sprintf("%-18s",""))
    combox_mount = Gtk::ComboBox.new

    @base.mount_combo.each_with_index do |val,index|
      combox_mount.append_text(val)
    end
    combox_mount.active = @command_mount_mode.to_i

    if @command_mount_dir.to_s.empty?
      rc = ReceView_Command.new
      entry_mount.set_text(@command_mount_dir.to_s)
      @command_mount_dir = rc.mount_dev
    else
      entry_mount.set_text(@command_mount_dir.to_s)
    end

    hbox1 = Gtk::HBox.new
    hbox2 = Gtk::HBox.new
    vbox = Gtk::VBox.new

    label_mount.set_justify(Gtk::JUSTIFY_LEFT)

    hbox1.pack_start(label_mount, false, true, 5)
    hbox1.pack_start(entry_mount, true, true, 5)
    hbox2.pack_start(label_space, false, true, 5)
    hbox2.pack_start(combox_mount, false, true, 5)

    ok_button = Gtk::Button.new(Gtk::Stock::OK)
    cancel_button = Gtk::Button.new(Gtk::Stock::CANCEL)
    auto_button = Gtk::Button.new(@base.dc["auto"])

    vbox.pack_start(hbox1, true, true, 5)
    vbox.pack_start(hbox2, false, false, 5)

    dialog.action_area.pack_start(ok_button)
    dialog.action_area.pack_start(cancel_button)
    dialog.action_area.pack_start(auto_button)
    dialog.vbox.pack_start(vbox)

    accel = Gtk::AccelGroup.new
    accel.connect(Gdk::Keyval::GDK_C, Gdk::Window::CONTROL_MASK,
      Gtk::ACCEL_VISIBLE) do
        cancel_button.signal_emit("clicked")
    end
    dialog.add_accel_group(accel)

    dialog.set_geometry_hints(ok_button, geometry, mask)

    dialog.signal_connect("delete_event") do
      dialog.hide
      true
    end

    return {
      "dialog" => dialog,
      "ok_button" => ok_button,
      "auto_button" => auto_button,
      "cancel_button" => cancel_button,
      "entry" => entry_mount,
      "combox" => combox_mount,
    }
  end

  def dialog_check_control(trans=nil)
    geometry = Gdk::Geometry.new
    geometry.set_min_width(320)
    geometry.set_min_height(60)
    geometry.set_max_width(320)
    geometry.set_max_height(60)
    mask = Gdk::Window::HINT_MIN_SIZE | 
           Gdk::Window::HINT_MAX_SIZE | Gdk::Window::HINT_RESIZE_INC
    dialog = Gtk::Dialog.new
    dialog.set_title("チェックファイル")
    dialog.set_modal(true)            
    ReceViewGUI::SettingIcon(dialog)
    ReceViewGUI::TransWindow(dialog, trans)

    vbox = Gtk::VBox.new
    dir_button = Gtk::Button.new("ディレクトリを開く(_O)")
    dir_button.set_image(Gtk::Image.new(Gtk::Stock::DIRECTORY, Gtk::IconSize::DIALOG))
    exit_button = Gtk::Button.new(Gtk::Stock::CLOSE)

    model= Gtk::TreeStore.new(String, String)
    tree_render = Gtk::CellRendererText.new
    ctree_cc = Gtk::TreeView.new(model)
    column_data = ["チェックファイル名"]
    column_data.each_with_index do |item, i|
      column = Gtk::TreeViewColumn.new(item, tree_render, 
        { :text => i
        })
      ctree_cc.append_column(column)
    end

    sw1 = Gtk::ScrolledWindow.new
    sw1.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    sw1.add_with_viewport(ctree_cc)
    vbox.pack_start(sw1, true, true, 5)

    dialog.action_area.pack_start(dir_button)
    dialog.action_area.pack_start(exit_button)
    dialog.vbox.pack_start(vbox)

    accel = Gtk::AccelGroup.new
    accel.connect(Gdk::Keyval::GDK_O, Gdk::Window::CONTROL_MASK,
      Gtk::ACCEL_VISIBLE) do
        dir_button.signal_emit("clicked")
    end
    accel.connect(Gdk::Keyval::GDK_C, Gdk::Window::CONTROL_MASK,
      Gtk::ACCEL_VISIBLE) do
        exit_button.signal_emit("clicked")
    end
    dialog.add_accel_group(accel)

    dialog.set_geometry_hints(exit_button, geometry, mask)

    dir_button.signal_connect("clicked") do
      check_dir = [ENV["HOME"], ReceViewConf::RECEVIEW_DIR].join(@path_char)
      if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
        @windows_shell.Run("EXPLORER.EXE #{check_dir}")
      else
        system("/usr/bin/gnome-open #{check_dir}")
      end
    end

    exit_button.signal_connect("clicked") do
      dialog.hide
    end

    dialog.signal_connect("delete_event") do
      dialog.hide
    end

    return {
      "dialog" => dialog,
      "treeview" => ctree_cc,
      "model" => model
    }
  end

  def dialog_view(trans=nil)
    geometry = Gdk::Geometry.new
    geometry.set_min_width(480)
    geometry.set_min_height(320)
    geometry.set_max_width(480)
    geometry.set_max_height(320)
    mask = Gdk::Window::HINT_MIN_SIZE | 
           Gdk::Window::HINT_MAX_SIZE | Gdk::Window::HINT_RESIZE_INC
    dialog = Gtk::Dialog.new
    dialog.set_title("レセ電データ [個別]")
    dialog.set_modal(false)
    ReceViewGUI::SettingIcon(dialog)
    ReceViewGUI::TransWindow(dialog, trans)

    ok_button = Gtk::Button.new(Gtk::Stock::CLOSE)
    sw        = Gtk::ScrolledWindow.new
    view      = Gtk::TextView.new
    vbox      = Gtk::VBox.new(true, 0)

    sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    
    view.editable = false
    view.grab_focus

    view.set_border_window_size(Gtk::TextView::WINDOW_LEFT, 2)
    view.set_border_window_size(Gtk::TextView::WINDOW_RIGHT, 2)
    view.set_border_window_size(Gtk::TextView::WINDOW_TOP, 2)
    view.set_border_window_size(Gtk::TextView::WINDOW_BOTTOM, 2)
    view.set_left_margin(10)
    view.set_right_margin(10)

    accel = Gtk::AccelGroup.new
    accel.connect(Gdk::Keyval::GDK_C, Gdk::Window::CONTROL_MASK,
      Gtk::ACCEL_VISIBLE) do
        ok_button.signal_emit("clicked")
    end
    dialog.add_accel_group(accel)

    sw.add(view)
    vbox.add(sw)

    dialog.action_area.pack_start(ok_button)
    dialog.vbox.pack_start(vbox)
    dialog.set_geometry_hints(ok_button, geometry, mask)

    ok_button.signal_connect("clicked") do
      dialog.hide
    end

    dialog.signal_connect("delete_event") do
      dialog.hide
      true
    end
    return {"view" => view, "dialog" => dialog}
  end

  def dialog_printer(trans=nil)
    geometry = Gdk::Geometry.new
    geometry.set_min_width(180)
    geometry.set_min_height(40)
    geometry.set_max_width(180)
    geometry.set_max_height(40)
    mask = Gdk::Window::HINT_MIN_SIZE | 
           Gdk::Window::HINT_MAX_SIZE | Gdk::Window::HINT_RESIZE_INC
    dialog = Gtk::Dialog.new
    dialog.set_title("プリンタ設定")
    dialog.set_modal(true)
    ReceViewGUI::SettingIcon(dialog)
    ReceViewGUI::TransWindow(dialog, trans)

    label_printer = Gtk::Label.new("プリンタ名:")
    label_pmethod = Gtk::Label.new("印刷方法:　")
    ok_button = Gtk::Button.new(Gtk::Stock::OK)
    cancel_button = Gtk::Button.new(Gtk::Stock::CLOSE)
    combox_printer = Gtk::ComboBox.new(true)
    combox_pmethod = Gtk::ComboBox.new(true)
    combox_printer.set_wrap_width(3)

    vbox = Gtk::VBox.new
    hbox = Gtk::HBox.new
    hbox2 = Gtk::HBox.new

    @base.print_method.each do |val|
      combox_pmethod.append_text(val)
    end

    combox_printer.active = 0
    combox_printer.grab_focus
    combox_pmethod.active = 0
    combox_pmethod.grab_focus

    accel = Gtk::AccelGroup.new
    accel.connect(Gdk::Keyval::GDK_C, Gdk::Window::CONTROL_MASK,
      Gtk::ACCEL_VISIBLE) do
        ok_button.signal_emit("clicked")
    end
    dialog.add_accel_group(accel)

    hbox.pack_start(label_printer, false, true, 5)
    hbox.pack_start(combox_printer, true, true, 5)
    hbox2.pack_start(label_pmethod, false, true, 5)
    hbox2.pack_start(combox_pmethod, true, true, 5)

    vbox.pack_start(hbox, false, true, 10)
    vbox.pack_start(hbox2, false, true, 10)

    dialog.action_area.pack_start(ok_button)
    dialog.action_area.pack_start(cancel_button)
    dialog.vbox.pack_start(vbox)
    dialog.set_geometry_hints(ok_button, geometry, mask)

    ok_button.signal_connect("clicked") do
      dialog.hide
    end

    cancel_button.signal_connect("clicked") do
      dialog.hide
    end

    dialog.signal_connect("delete_event") do
      dialog.hide
      true
    end

    return {
      "combox" => combox_printer,
      "pm_combox" => combox_pmethod,
      "dialog" => dialog,
      "ok_button" => ok_button,
    }
  end
end

# Test Code
if __FILE__ == $0
  $LOAD_PATH.unshift('../', '../../')

  require 'jma/receview/gtk2_fix'
  require 'jma/receview/dialog'
  require 'jma/receview/gui'

  def wait_test
    loop do
      sleep 1.0
      p "sleep"
    end
  end

  case ARGV[0].to_s
  when "head"
    d = ReceView_Dialog.new
    headline = d.dialog_headline_edit("頭書き修正")
    dialog = headline["dialog"]
    e_name = headline["entry_name"]
    c_sex  = headline["combox_sex"]
    e_hkno = headline["entry_hkno"]
    e_hkno_k = headline["entry_hkno_k"]
    e_hkno_b = headline["entry_hkno_b"]
    cancel_b = headline["cancel_button"]
    redo_b = headline["redo_button"]
    ok_b = headline["ok_button"]

    re_record = "RE,1,1310,41906,氏名　名前,1,3020310,80,,,,,,00444,,,," 
    ko_record = "RO,    5801,任継,２９３５４,2,1037,,,,27320019,1202456,,,"
    #ko_record = "KO,12321014,,,2,8341,,,,,,"
    re = re_record.split(/,/)
    ko = ko_record.split(/,/)

    e_name.set_text(re[4].to_s)
    c_sex.active = (re[5].to_i - 1)
    e_name.set_text(re[4].to_s)

    e_hkno.set_text(ko[1].gsub(/ /, ""))
    e_hkno_k.set_text(ko[2])
    e_hkno_b.set_text(ko[3])

    dialog.show_all

    c_sex.signal_connect("changed") do
      p c_sex.active.to_s
    end

    ok_b.signal_connect("clicked") do
      dialog.hide
    end

    cancel_b.signal_connect("clicked") do
      dialog.hide
    end

    redo_b.signal_connect("clicked") do
      dialog.hide
    end

    dialog.signal_connect("delete_event") do
    end
    d.main
  when "wait"
    @rd = ReceView_Dialog.new
    d_wait = @rd.dialog_wait(nil, "test title", "message body")
    dialog = d_wait["dialog"]
    message = d_wait["msg"]
    dialog.show_all
    thread = Thread.new do
      Gtk.main_with_queue(100)
    end
    wait_test
    thread.join
  when "message"
    @rd = ReceView_Dialog.new
    message = "aaaaaaaaaaaaaaaaaaaaaaaaaab!"
    dialog = @rd.dialog_message(nil, "注意", message)
    dialog.show_all
    Gtk.main_with_queue(100)
  end

  print "ruby ./#{$0} ARGV\n"
  print "ARGVs => head, wait, message\n"
  print "ex test $ ruby ./#{$0} head\n"
end
