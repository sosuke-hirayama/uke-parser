# -*- encoding: utf-8 -*-

require 'jma/receview/generation'

begin
  require 'jma/receview/gtk2_fix'
rescue LoadError
  require 'gtk2_fix'
end

class ReceViewGUI_Lock < Gtk::Dialog
  require 'jma/receview/base'
  def initialize
    super
    geometry = Gdk::Geometry.new
    geometry.set_min_width(320)
    geometry.set_min_height(200)
    geometry.set_max_width(320)
    geometry.set_max_height(200)
    mask = Gdk::Window::HINT_MIN_SIZE | 
           Gdk::Window::HINT_MAX_SIZE | Gdk::Window::HINT_RESIZE_INC
    self.set_title("起動エラー")
    self.set_modal(true)
    self.set_geometry_hints(nil, geometry, mask)
    self.set_type_hint(Gdk::Window::TYPE_HINT_DIALOG)
    self.set_window_position(Gtk::Window::Position::CENTER)
    self.set_keep_above(true)
    ReceViewGUI::SettingIcon(self)

    msg = "既にレセ電ビューアは起動処理中、\nまたは起動しています。\n\n起動中の場合はしばらくお待ちください。"
    @msg_label = Gtk::Label.new(msg)
    @close_button = Gtk::Button.new(Gtk::Stock::CLOSE)

    @box = Gtk::HBox.new
    image_list = ["jma-receview-icon.png", "/usr/share/pixmaps/jma-receview-icon.png"]
    image_list.each do |img_path|
      if File.exist?(img_path)
        @image = Gtk::Image.new(img_path)
        break
      end
    end
    @box.pack_start(@image, false, false, 5)
    @box.pack_start(@msg_label, true, false, 5)

    @accel = Gtk::AccelGroup.new
    self.event

    self.add_accel_group(@accel)
    self.vbox.add(@box)
    self.action_area.pack_start(@close_button)
  end

  def event
    @accel.connect(Gdk::Keyval::GDK_Escape, nil, Gtk::ACCEL_VISIBLE) do
      @close_button.signal_emit("clicked")
    end

    @close_button.signal_connect("clicked") do
      self.hide
      Gtk.main_quit
    end

    self.signal_connect("delete_event") do
      false
    end

    self.signal_connect("destroy") do
      Gtk.main_quit
    end
  end

  def main
    self.show_all
    self.present
    Gtk.main
  end
end

class ReceViewGUI
  attr_reader :platform_thread

  TAB_MAIN_CLASS = 0
  TAB_MAIN_KANJA = 1
  TAB_MAIN_CODE  = 2
  TAB_USER_INFO    = 0
  TAB_USER_SANTEI  = 1
  TAB_USER_PREVIEW = 2
  TAB_USER_CODE    = 3

  def initialize
    require 'jma/receview/base'

    @@init_maximize = false
    @platform_thread = Thread.platform_support_thread

    @base = ReceView_Base.new
    @fs = ReceViewGUI::FS.new(@base.file_title)
    @gtk_loop = ''

    @display_completion = false
    @print = false
    @preview_object = {}
    @viewbox_object = {}
    @toolbox_object = {}
    @main_window = nil
    @window_icon = nil
    @icon_image = nil
    @main_tab = nil
    @user_tab = nil

    @ir_tree = nil
    @re_tree = nil
    @byomei_tree = nil
    @tekiyo_tree = nil
    @santei_tree = nil
    @recal_tree = nil
    @print_tree = nil
    @print_pdf_tree = nil
    @print_history_tree = nil

    @kanja_box = nil
    @user_viewbox = nil
    @all_code = nil
    @raw_code_view = nil
    @d_search_thread = Thread.new {}

    @tree_model_ir = self.tree_model_ir_init
    @tree_model_re = self.tree_model_re_init
    @tree_model_sick = self.tree_model_sick_init
    @tree_model_rsick = self.tree_model_rsick_init
    @tree_model_teki = self.tree_model_teki_init
    @tree_model_santei = self.tree_model_santei_init
    @tree_model_print = self.tree_model_print_init
    @tree_model_print_pdf  = self.tree_model_print_pdf_init
    @tree_model_print_history = self.tree_model_print_history_init
    @tree_model_ir_size = 0
    @tree_model_re_size = 0
    @tree_model_sick_size = 0
    @tree_model_rsick_size = 0
    @tree_model_teki_size = 0
    @tree_model_santei_size = 0
    @tree_model_print_size = 0
    @tree_model_print_pdf_size = 0
    @tree_model_print_history_size = 0
    @tree_model_search_size = 0
    @tree_model_search_csvsize = 0

    @treeview_search_class = Gtk::TreeView

    @dnd_lock = false
  end

  def init_maximize?
    @@init_maximize
  end

  def set_init_maximize(flg)
    if @@init_maximize
      false
    else
      @@init_maximize = true
    end
  end

  def set_display_completion(v)
    @display_completion = v
  end

  def display_completion
    @display_completion
  end

  def main_loop
    @gtk_loop = 'START'
    Gtk.main_with_queue(100)
    #Gtk.main
  end

  def main_end
    @gtk_loop = 'STOP'
  end

  def main_status
    @gtk_loop
  end

  def fs
    @fs
  end

  def main_window
    @main_window
  end

  def window_event_state
    @window_event_state
  end

  def window_event_state_none?(state)
    flg = true
    if state.iconified?
      flg = false
    elsif state.maximized?
      flg = false
    elsif state.fullscreen?
      flg = false
    end
    return flg
  end

  def set_window_event_state(state)
    m = ""
    if state.iconified?
      m = "iconified"
    elsif state.maximized?
      m = "maximized"
    else
      m = "none"
    end
    @window_event_state = m
  end

  def init_window_event?(x, y)
    if x == 200 and y == 200
      true
    else
      false
    end
  end

  def set_user_viewbox(widget)
    @user_viewbox = widget
  end

  def user_viewbox
    @user_viewbox
  end

  def all_code
    @all_code
  end

  def set_print(print)
    @print = print
  end

  def print
    @print
  end

  def preview_object
    @preview_object
  end

  def viewbox_object
    @viewbox_object
  end

  def toolbox_object
    @toolbox_object
  end

  def status_bar
    @status_bar
  end

  def icon_image
    @icon_image
  end

  def tree_model_ir
    @tree_model_ir
  end

  def tree_model_re
    @tree_model_re
  end

  def tree_model_sick
    @tree_model_sick
  end

  def tree_model_rsick
    @tree_model_rsick
  end

  def tree_model_teki
    @tree_model_teki
  end

  def tree_model_santei
    @tree_model_santei
  end

  def tree_model_print
    @tree_model_print
  end

  def tree_model_print_pdf
    @tree_model_print_pdf
  end

  def tree_model_print_history
    @tree_model_print_history
  end

  def tree_model_ir_size
    @tree_model_ir_size
  end

  def tree_model_re_size
    @tree_model_re_size
  end

  def tree_model_sick_size
    @tree_model_sick_size
  end
 
  def tree_model_teki_size
    @tree_model_teki_size
  end

  def tree_model_santei_size
    @tree_model_santei_size
  end

  def tree_model_print_size
    @tree_model_print_size
  end

  def tree_model_print_pdf_size
    @tree_model_print_pdf_size
  end

  def tree_model_print_history_size
    @tree_model_print_history_size
  end

  def tree_model_search_size
    @tree_model_search_size
  end

  def tree_model_search_csvsize
    @tree_model_search_csvsize
  end

  def set_search_thread(thread)
    @d_search_thread = thread
  end

  def search_thread
    @d_search_thread
  end

  def set_ir_tree(tree)
    @ir_tree = tree
  end

  def ir_tree
    @ir_tree
  end

  def set_re_tree(tree)
    @re_tree = tree
  end

  def re_tree
    @re_tree
  end

  def set_byomei_tree(tree)
    @byomei_tree = tree
  end

  def byomei_tree
    @byomei_tree
  end
  
  def set_tekiyo_tree(tree)
    @tekiyo_tree = tree
  end

  def tekiyo_tree
    @tekiyo_tree
  end

  def set_santei_tree(tree)
    @santei_tree = tree
  end

  def santei_tree
    @santei_tree
  end

  def set_recal_tree(tree)
    @recal_tree = tree
  end

  def recal_tree
    @recal_tree
  end

  def set_print_tree(tree)
    @print_tree = tree
  end

  def set_print_pdf_tree(tree)
    @print_pdf_tree = tree
  end

  def set_print_history_tree(tree)
    @print_history_tree = tree
  end

  def print_tree
    @print_tree
  end

  def print_pdf_tree
    @print_pdf_tree
  end

  def print_history_tree
    @print_history_tree
  end

  def kanja_box
    @kanja_box
  end

  def user_view
    @kanja_out
  end

  def kanja_out
    @kanja_out
  end

  def kanja_status_bar
    @kanja_hbox[17]
  end

  def kanja_hoken_box
    @kanja_hbox[16]
  end

  def henrei_sep
    @henrei_sep
  end

  def hoken_button
    @hoken_b
  end

  def sw_ir
    @sw_ir
  end

  def sw_re
    @sw_re
  end

  def sw_kanja
    @sw_kanja
  end

  def sw_tekiyo
    @sw_tekiyo
  end

  def popmenu_kanja
    @popmenu_kanja = ReceViewGUI::PopUP.new
  end

  def popmenu_byomei
    @popmenu_byomei = ReceViewGUI::PopUP.new
  end

  def main_tab
    @main_tab
  end

  def user_tab
    @user_tab
  end

  def raw_code_view
    @raw_code_view
  end

  def defalt_hide
    @all_code["search"].hide
    @kanja_out["henrei_data"].hide
    @henrei_sep.hide
  end

  def henrei_view(stat=true)
    if stat
      @kanja_out["henrei_data"].show
      @henrei_sep.show
    else
      @kanja_out["henrei_data"].hide
      @henrei_sep.hide
    end
  end

  def hosp_view(stat=true)
    if stat
      @kanja_out["hosp_day"].show
      @kanja_out["hosp_day_space"].show
      @kanja_out["hosp_day_line1"].show
      @kanja_out["hosp_day_line2"].show
    else
      @kanja_out["hosp_day"].hide
      @kanja_out["hosp_day_space"].hide
      @kanja_out["hosp_day_line1"].hide
      @kanja_out["hosp_day_line2"].hide
    end
  end

  def kouhi_view(stat=true)
    if stat
      @kanja_out["kouhi_uke_3"].show
      @kanja_out["kouhi_hutan_3"].show
      @kanja_out["kouhi_uke_3_space"].show
      @kanja_out["kouhi_hutan_3_space"].show
      @kanja_out["kouhi_uke_4"].show
      @kanja_out["kouhi_hutan_4"].show
      @kanja_out["kouhi_uke_4_space"].show
      @kanja_out["kouhi_hutan_4_space"].show

      @kanja_out["kouhi_line1_3"].show
      @kanja_out["kouhi_line2_3"].show
      @kanja_out["kouhi_line3_3"].show
      @kanja_out["kouhi_line4_3"].show
      @kanja_out["kouhi_line1_4"].show
      @kanja_out["kouhi_line2_4"].show
      @kanja_out["kouhi_line3_4"].show
      @kanja_out["kouhi_line4_4"].show
    else
      @kanja_out["kouhi_uke_3"].hide
      @kanja_out["kouhi_hutan_3"].hide
      @kanja_out["kouhi_uke_3_space"].hide
      @kanja_out["kouhi_hutan_3_space"].hide
      @kanja_out["kouhi_uke_4"].hide
      @kanja_out["kouhi_hutan_4"].hide
      @kanja_out["kouhi_uke_4_space"].hide
      @kanja_out["kouhi_hutan_4_space"].hide

      @kanja_out["kouhi_line1_3"].hide
      @kanja_out["kouhi_line2_3"].hide
      @kanja_out["kouhi_line3_3"].hide
      @kanja_out["kouhi_line4_3"].hide
      @kanja_out["kouhi_line1_4"].hide
      @kanja_out["kouhi_line2_4"].hide
      @kanja_out["kouhi_line3_4"].hide
      @kanja_out["kouhi_line4_4"].hide
    end
  end

  def rosai_view(stat=true)
    if stat
      self.hoken_button["kouhi_1"].hide
      self.hoken_button["kouhi_2"].hide
      self.hoken_button["kouhi_3"].hide
      self.hoken_button["kouhi_4"].hide

      @kanja_out["bango"].hide
      @kanja_out["bango_space"].hide
      @kanja_out["roujin_iryou_no"].hide
      @kanja_out["roujin_iryou_no_space"].hide
      @kanja_out["towns_no"].hide
      @kanja_out["towns_no_space"].hide

      @kanja_out["kouhi_1_space_r"].hide
      @kanja_out["kouhi_2_space_r"].hide
      @kanja_out["kouhi_3_space_r"].hide
      @kanja_out["kouhi_4_space_r"].hide
      @kanja_out["kouhi_1_space_s"].hide
      @kanja_out["kouhi_2_space_s"].hide
      @kanja_out["kouhi_3_space_s"].hide
      @kanja_out["kouhi_4_space_s"].hide
      @kanja_out["kouhi_1_space_h"].hide
      @kanja_out["kouhi_2_space_h"].hide
      @kanja_out["kouhi_3_space_h"].hide
      @kanja_out["kouhi_4_space_h"].hide

      @kanja_out["kouhi_1_line"].hide
      @kanja_out["kouhi_2_line"].hide
      @kanja_out["kouhi_3_line"].hide
      @kanja_out["kouhi_4_line"].hide
      @kanja_out["kouhi_e_line"].hide
      @kanja_out["kouhi_1_space_r_line"].hide
      @kanja_out["kouhi_2_space_r_line"].hide
      @kanja_out["kouhi_3_space_r_line"].hide
      @kanja_out["kouhi_4_space_r_line"].hide
      @kanja_out["kouhi_e_space_r_line"].hide
      @kanja_out["kouhi_1_space_s_line"].hide
      @kanja_out["kouhi_2_space_s_line"].hide
      @kanja_out["kouhi_3_space_s_line"].hide
      @kanja_out["kouhi_4_space_s_line"].hide
      @kanja_out["kouhi_e_space_s_line"].hide
      @kanja_out["kouhi_1_space_h_line"].hide
      @kanja_out["kouhi_2_space_h_line"].hide
      @kanja_out["kouhi_3_space_h_line"].hide
      @kanja_out["kouhi_4_space_h_line"].hide
      @kanja_out["kouhi_e_space_h_line"].hide

      @kanja_out["kouhi_uke_1"].hide
      @kanja_out["kouhi_hutan_1"].hide
      @kanja_out["kouhi_uke_1_space"].hide
      @kanja_out["kouhi_hutan_1_space"].hide
      @kanja_out["kouhi_uke_2"].hide
      @kanja_out["kouhi_hutan_2"].hide
      @kanja_out["kouhi_uke_2_space"].hide
      @kanja_out["kouhi_hutan_2_space"].hide
      @kanja_out["kouhi_uke_3"].hide
      @kanja_out["kouhi_hutan_3"].hide
      @kanja_out["kouhi_uke_3_space"].hide
      @kanja_out["kouhi_hutan_3_space"].hide
      @kanja_out["kouhi_uke_4"].hide
      @kanja_out["kouhi_hutan_4"].hide
      @kanja_out["kouhi_uke_4_space"].hide
      @kanja_out["kouhi_hutan_4_space"].hide

      @kanja_out["kouhi_line1_1"].hide
      @kanja_out["kouhi_line2_1"].hide
      @kanja_out["kouhi_line3_1"].hide
      @kanja_out["kouhi_line4_1"].hide
      @kanja_out["kouhi_line1_2"].hide
      @kanja_out["kouhi_line2_2"].hide
      @kanja_out["kouhi_line3_2"].hide
      @kanja_out["kouhi_line4_2"].hide
      @kanja_out["kouhi_line1_3"].hide
      @kanja_out["kouhi_line2_3"].hide
      @kanja_out["kouhi_line3_3"].hide
      @kanja_out["kouhi_line4_3"].hide
      @kanja_out["kouhi_line1_4"].hide
      @kanja_out["kouhi_line2_4"].hide
      @kanja_out["kouhi_line3_4"].hide
      @kanja_out["kouhi_line4_4"].hide
      @kanja_out["kouhi_line5_0"].hide
      @kanja_out["kouhi_line5_1"].hide
      @kanja_out["kouhi_line5_2"].hide
      @kanja_out["kouhi_line6_0"].hide

      self.kanja_hoken_box.hide

      @kanja_out["rr_sick_ymd"].show
      @kanja_out["rr_sick_ymd_space"].show
      @kanja_out["rr_sinkei"].show
      @kanja_out["rr_sinkei_space"].show
      @kanja_out["rr_tenki"].show
      @kanja_out["rr_tenki_space"].show

      @kanja_out["rr_ryoyo_ymd"].show
      @kanja_out["rr_ryoyo_ymd_space"].show
      @kanja_out["rr_sinryo_ymd"].show
      @kanja_out["rr_sinryo_ymd_space"].show
      @kanja_out["rr_sum_money"].show
      @kanja_out["rr_sum_money_space"].show

      @kanja_out["rr_subtotal_tensu"].show
      @kanja_out["rr_subtotal_tensu_space"].show
      @kanja_out["rr_subtotal_tensu2money"].show
      @kanja_out["rr_subtotal_tensu2money_space"].show
      @kanja_out["rr_subtotal_money"].show
      @kanja_out["rr_subtotal_money_space"].show
      @kanja_out["rr_subtotal_lunchmoney"].show
      @kanja_out["rr_subtotal_lunchmoney_space"].show
      @kanja_out["rr_subtotal_lunchnumber"].show
      @kanja_out["rr_subtotal_lunchnumber_space"].show
      @kanja_out["rr_enterprise_name"].show
      @kanja_out["rr_enterprise_name_space"].show
      @kanja_out["rr_enterprise_addr"].show
      @kanja_out["rr_enterprise_addr_space"].show
      @kanja_out["rr_sickname_after"].show
      @kanja_out["rr_sickname_after_space"].show

      @kanja_out["rr_line0_0"].show
      @kanja_out["rr_line0_1"].show
      @kanja_out["rr_line1_0"].show
      @kanja_out["rr_line1_1"].show
      @kanja_out["rr_line1_2"].show
      @kanja_out["rr_line1_3"].show
      @kanja_out["rr_line1_4"].show
      @kanja_out["rr_line1_5"].show
      @kanja_out["rr_line2_0"].show
      @kanja_out["rr_line2_1"].show
      @kanja_out["rr_line2_2"].show
      @kanja_out["rr_line2_3"].show
      @kanja_out["rr_line2_4"].show
      @kanja_out["rr_line3_0"].show
      @kanja_out["rr_line3_1"].show
      @kanja_out["rr_line3_2"].show
      @kanja_out["rr_line3_3"].show
      @kanja_out["rr_line3_4"].show
      @kanja_out["rr_line3_5"].show
      @kanja_out["rr_line4_0"].show
      @kanja_out["rr_line4_1"].show
      @kanja_out["rr_line4_2"].show
      @kanja_out["rr_line4_3"].show
      @kanja_out["rr_line5_0"].show
      @kanja_out["rr_line5_1"].show
      @kanja_out["rr_line5_2"].show
      @kanja_out["rr_line6_0"].show
      @kanja_out["rr_line6_1"].show
      @kanja_out["rr_line6_2"].show
      @kanja_out["rr_line7_0"].show
      @kanja_out["rr_line7_1"].show
      @kanja_out["rr_line7_2"].show
    else
      self.hoken_button["kouhi_1"].show
      self.hoken_button["kouhi_2"].show

      @kanja_out["bango"].show
      @kanja_out["bango_space"].show
      @kanja_out["roujin_iryou_no"].show
      @kanja_out["roujin_iryou_no_space"].show
      @kanja_out["towns_no"].show
      @kanja_out["towns_no_space"].show

      @kanja_out["kouhi_1_space_r"].show
      @kanja_out["kouhi_2_space_r"].show
      @kanja_out["kouhi_1_space_s"].show
      @kanja_out["kouhi_2_space_s"].show
      @kanja_out["kouhi_1_space_h"].show
      @kanja_out["kouhi_2_space_h"].show

      @kanja_out["kouhi_1_line"].show
      @kanja_out["kouhi_2_line"].show
      @kanja_out["kouhi_e_line"].show
      @kanja_out["kouhi_1_space_r_line"].show
      @kanja_out["kouhi_2_space_r_line"].show
      @kanja_out["kouhi_e_space_r_line"].show
      @kanja_out["kouhi_1_space_s_line"].show
      @kanja_out["kouhi_2_space_s_line"].show
      @kanja_out["kouhi_e_space_s_line"].show
      @kanja_out["kouhi_1_space_h_line"].show
      @kanja_out["kouhi_2_space_h_line"].show
      @kanja_out["kouhi_e_space_h_line"].show

      @kanja_out["kouhi_uke_1"].show
      @kanja_out["kouhi_hutan_1"].show
      @kanja_out["kouhi_uke_1_space"].show
      @kanja_out["kouhi_hutan_1_space"].show
      @kanja_out["kouhi_uke_2"].show
      @kanja_out["kouhi_hutan_2"].show
      @kanja_out["kouhi_uke_2_space"].show
      @kanja_out["kouhi_hutan_2_space"].show

      @kanja_out["kouhi_line1_1"].show
      @kanja_out["kouhi_line2_1"].show
      @kanja_out["kouhi_line3_1"].show
      @kanja_out["kouhi_line4_1"].show
      @kanja_out["kouhi_line1_2"].show
      @kanja_out["kouhi_line2_2"].show
      @kanja_out["kouhi_line3_2"].show
      @kanja_out["kouhi_line4_2"].show
      @kanja_out["kouhi_line1_3"].show
      @kanja_out["kouhi_line2_3"].show
      @kanja_out["kouhi_line3_3"].show
      @kanja_out["kouhi_line4_3"].show
      @kanja_out["kouhi_line1_4"].show
      @kanja_out["kouhi_line2_4"].show
      @kanja_out["kouhi_line3_4"].show
      @kanja_out["kouhi_line4_4"].show
      @kanja_out["kouhi_line5_0"].show
      @kanja_out["kouhi_line5_1"].show
      @kanja_out["kouhi_line5_2"].show
      @kanja_out["kouhi_line5_3"].show
      @kanja_out["kouhi_line6_0"].show

      self.kanja_hoken_box.show

      @kanja_out["rr_sick_ymd"].hide
      @kanja_out["rr_sick_ymd_space"].hide
      @kanja_out["rr_sinkei"].hide
      @kanja_out["rr_sinkei_space"].hide
      @kanja_out["rr_tenki"].hide
      @kanja_out["rr_tenki_space"].hide
     
      @kanja_out["rr_ryoyo_ymd"].hide
      @kanja_out["rr_ryoyo_ymd_space"].hide
      @kanja_out["rr_sinryo_ymd"].hide
      @kanja_out["rr_sinryo_ymd_space"].hide
      @kanja_out["rr_sum_money"].hide
      @kanja_out["rr_sum_money_space"].hide

      @kanja_out["rr_subtotal_tensu"].hide
      @kanja_out["rr_subtotal_tensu_space"].hide
      @kanja_out["rr_subtotal_tensu2money"].hide
      @kanja_out["rr_subtotal_tensu2money_space"].hide
      @kanja_out["rr_subtotal_money"].hide
      @kanja_out["rr_subtotal_money_space"].hide
      @kanja_out["rr_subtotal_lunchmoney"].hide
      @kanja_out["rr_subtotal_lunchmoney_space"].hide
      @kanja_out["rr_subtotal_lunchnumber"].hide
      @kanja_out["rr_subtotal_lunchnumber_space"].hide
      @kanja_out["rr_enterprise_name"].hide
      @kanja_out["rr_enterprise_name_space"].hide
      @kanja_out["rr_enterprise_addr"].hide
      @kanja_out["rr_enterprise_addr_space"].hide
      @kanja_out["rr_sickname_after"].hide
      @kanja_out["rr_sickname_after_space"].hide

      @kanja_out["rr_line0_0"].hide
      @kanja_out["rr_line0_1"].hide
      @kanja_out["rr_line1_0"].hide
      @kanja_out["rr_line1_1"].hide
      @kanja_out["rr_line1_2"].hide
      @kanja_out["rr_line1_3"].hide
      @kanja_out["rr_line1_4"].hide
      @kanja_out["rr_line1_5"].hide
      @kanja_out["rr_line2_0"].hide
      @kanja_out["rr_line2_1"].hide
      @kanja_out["rr_line2_2"].hide
      @kanja_out["rr_line2_3"].hide
      @kanja_out["rr_line2_4"].hide
      @kanja_out["rr_line3_0"].hide
      @kanja_out["rr_line3_1"].hide
      @kanja_out["rr_line3_2"].hide
      @kanja_out["rr_line3_3"].hide
      @kanja_out["rr_line3_4"].hide
      @kanja_out["rr_line3_5"].hide
      @kanja_out["rr_line4_0"].hide
      @kanja_out["rr_line4_1"].hide
      @kanja_out["rr_line4_2"].hide
      @kanja_out["rr_line4_3"].hide
      @kanja_out["rr_line5_0"].hide
      @kanja_out["rr_line5_1"].hide
      @kanja_out["rr_line5_2"].hide
      @kanja_out["rr_line6_0"].hide
      @kanja_out["rr_line6_1"].hide
      @kanja_out["rr_line6_2"].hide
      @kanja_out["rr_line7_0"].hide
      @kanja_out["rr_line7_1"].hide
      @kanja_out["rr_line7_2"].hide
    end
  end

  # 患者個別情報画面
  def user_view_init
    @kanja_out = {}
    @kanja_box = Gtk::VBox.new(false, 0)
    @kanja_hbox = []
    @henrei_hbox = Gtk::HBox.new(false, 0)
    @henrei_sep  = Gtk::HSeparator.new

    25.times do |i|
      @kanja_hbox[i] = Gtk::HBox.new(false, 0)
    end

    @base.kanja_object.each do |key, name|
      @kanja_out[key] = Gtk::Label.new(name)
    end

    # ラベルの寄せ
    @kanja_out["receipt_syubetu"].set_justify(Gtk::JUSTIFY_LEFT)
    @kanja_out["kanja_status"].set_justify(Gtk::JUSTIFY_RIGHT)
    @kanja_out["kanja_no_space"].set_justify(Gtk::JUSTIFY_RIGHT)
    @kanja_out["receipt_no_space"].set_justify(Gtk::JUSTIFY_RIGHT)
    @kanja_out["name_space"].set_justify(Gtk::JUSTIFY_LEFT)
    @kanja_out["rr_enterprise_name_space"].set_justify(Gtk::JUSTIFY_LEFT)
    @kanja_out["rr_enterprise_addr_space"].set_justify(Gtk::JUSTIFY_LEFT)
    @kanja_out["rr_sickname_after_space"].set_justify(Gtk::JUSTIFY_LEFT)
    
    @base.kanja_button.each do |key, name|
      @kanja_out[key] = Gtk::Label.new(name)
    end

    @raw_code_view = Gtk::Entry.new
    @raw_code_view.set_editable(false)

    @kanja_out["raw_code_view"] = @raw_code_view
    @kanja_out["user_progress"] = Gtk::ProgressBar.new
    @kanja_out["user_progress"].activity_mode = false

    @henrei_hbox.pack_start(@kanja_out["henrei_data"], false, false, 0)

    @kanja_out["hosp_day_line1"] = Gtk::VSeparator.new
    @kanja_out["hosp_day_line2"] = Gtk::VSeparator.new
    
    @kanja_hbox[0].pack_start(@kanja_out["sinryo_ymd"], false, false, 0)
    @kanja_hbox[0].pack_start(Gtk::VSeparator.new, false, false, 0)
    @kanja_hbox[0].pack_start(@kanja_out["receipt_syubetu"], false, false, 0)
    @kanja_hbox[0].pack_start(Gtk::VSeparator.new, false, false, 0)
    @kanja_hbox[0].pack_start(@kanja_out["kanja_status"], false, false, 0)

    @kanja_hbox[1].pack_start(@kanja_out["kanja_no"], false, true, 0)
    @kanja_hbox[1].pack_start(Gtk::VSeparator.new, false, false, 0)
    @kanja_hbox[1].pack_start(@kanja_out["kanja_no_space"], true, true, 0)

    @kanja_hbox[1].pack_start(@kanja_out["hosp_day_line1"], false, false, 0)
    @kanja_hbox[1].pack_start(@kanja_out["hosp_day"], false, true, 0)
    @kanja_hbox[1].pack_start(@kanja_out["hosp_day_line2"], false, false, 0)
    @kanja_hbox[1].pack_start(@kanja_out["hosp_day_space"], true, true, 0)

    @kanja_hbox[2].pack_start(@kanja_out["receipt_no"], false, true, 0)
    @kanja_hbox[2].pack_start(Gtk::VSeparator.new, false, false, 0)
    @kanja_hbox[2].pack_start(@kanja_out["receipt_no_space"], true, true, 0)

    @kanja_hbox[3].pack_start(@kanja_out["name"], false, true, 0)
    @kanja_hbox[3].pack_start(Gtk::VSeparator.new, false, false, 0)
    @kanja_hbox[3].pack_start(@kanja_out["name_space"], true, true, 0)

    @kanja_hbox[4].pack_start(@kanja_out["sex"], false, true, 0)
    @kanja_hbox[4].pack_start(Gtk::VSeparator.new, false, false, 0)
    @kanja_hbox[4].pack_start(@kanja_out["sex_space"], true, true, 0)
    @kanja_hbox[4].pack_start(Gtk::VSeparator.new, false, false, 0)
    @kanja_hbox[4].pack_start(@kanja_out["age"], false, true, 0)
    @kanja_hbox[4].pack_start(Gtk::VSeparator.new, false, false, 0)
    @kanja_hbox[4].pack_start(@kanja_out["age_space"], true, true, 0)
    @kanja_hbox[4].pack_start(Gtk::VSeparator.new, false, false, 0)
    @kanja_hbox[4].pack_start(@kanja_out["birthday"], false, true, 0)
    @kanja_hbox[4].pack_start(Gtk::VSeparator.new, false, false, 0)
    @kanja_hbox[4].pack_start(@kanja_out["birthday_space"], true, true, 0)

    @kanja_hbox[5].pack_start(@kanja_out["hoken_no"], false, true, 0)
    @kanja_hbox[5].pack_start(Gtk::VSeparator.new, false, false, 0)
    @kanja_hbox[5].pack_start(@kanja_out["hoken_no_space"], true, true, 0)
    @kanja_hbox[5].pack_start(Gtk::VSeparator.new, false, false, 0)
    @kanja_hbox[5].pack_start(@kanja_out["sign"], false, true, 0)
    @kanja_hbox[5].pack_start(Gtk::VSeparator.new, false, false, 0)
    @kanja_hbox[5].pack_start(@kanja_out["sign_space"], true, true, 0)
    @kanja_hbox[5].pack_start(Gtk::VSeparator.new, false, false, 0)
    @kanja_hbox[5].pack_start(@kanja_out["bango"], false, true, 0)
    @kanja_hbox[5].pack_start(Gtk::VSeparator.new, false, false, 0)
    @kanja_hbox[5].pack_start(@kanja_out["bango_space"], true, true, 0)

    @vbox_hoken_menu  = Gtk::VBox.new(false, 0)
    @vbox_hoken_data  = Gtk::VBox.new(false, 0)
    @vbox_hoken2_menu = Gtk::VBox.new(false, 0)
    @vbox_hoken2_data = Gtk::VBox.new(false, 0)

    @vbox_hoken_menu1 = Gtk::VBox.new(false, 0)
    @vbox_hoken_menu2 = Gtk::VBox.new(false, 0)
    @vbox_hoken_menu3 = Gtk::VBox.new(false, 0)
    @vbox_hoken_menu4 = Gtk::VBox.new(false, 0)
    @vbox_hoken_menu5 = Gtk::VBox.new(false, 0)
    @vbox_hoken_data1 = Gtk::VBox.new(false, 0)
    @vbox_hoken_data2 = Gtk::VBox.new(false, 0)
    @vbox_hoken_data3 = Gtk::VBox.new(false, 0)
    @vbox_hoken_data4 = Gtk::VBox.new(false, 0)
    @vbox_hoken_data5 = Gtk::VBox.new(false, 0)
    @vbox_hoken2_menu1 = Gtk::VBox.new(false, 0)
    @vbox_hoken2_menu2 = Gtk::VBox.new(false, 0)
    @vbox_hoken2_menu3 = Gtk::VBox.new(false, 0)
    @vbox_hoken2_menu4 = Gtk::VBox.new(false, 0)
    @vbox_hoken2_menu5 = Gtk::VBox.new(false, 0)
    @vbox_hoken2_data1 = Gtk::VBox.new(false, 0)
    @vbox_hoken2_data2 = Gtk::VBox.new(false, 0)
    @vbox_hoken2_data3 = Gtk::VBox.new(false, 0)
    @vbox_hoken2_data4 = Gtk::VBox.new(false, 0)
    @vbox_hoken2_data5 = Gtk::VBox.new(false, 0)

    @kanja_out["kouhi_line1_0"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line1_1"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line1_2"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line1_3"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line1_4"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line2_0"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line2_1"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line2_2"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line2_3"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line2_4"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line3_0"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line3_1"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line3_2"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line3_3"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line3_4"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line4_0"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line4_1"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line4_2"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line4_3"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line4_4"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line5_0"] = Gtk::VSeparator.new
    @kanja_out["kouhi_line5_1"] = Gtk::VSeparator.new
    @kanja_out["kouhi_line5_2"] = Gtk::VSeparator.new
    @kanja_out["kouhi_line5_3"] = Gtk::HSeparator.new
    @kanja_out["kouhi_line6_0"] = Gtk::HSeparator.new

    @vbox_hoken_menu1.pack_start(@kanja_out["roujin_iryou_no"], false, true, 0)
    @vbox_hoken_menu1.pack_start(@kanja_out["kouhi_line1_0"], false, false, 0)

    @vbox_hoken_menu2.pack_start(@kanja_out["kouhi_hutan_1"], false, true, 0)
    @vbox_hoken_menu2.pack_start(@kanja_out["kouhi_line1_1"], false, false, 0)

    @vbox_hoken_menu3.pack_start(@kanja_out["kouhi_hutan_2"], false, true, 0)
    @vbox_hoken_menu3.pack_start(@kanja_out["kouhi_line1_2"], false, false, 0)

    @vbox_hoken_menu4.pack_start(@kanja_out["kouhi_hutan_3"], false, true, 0)
    @vbox_hoken_menu4.pack_start(@kanja_out["kouhi_line1_3"], false, false, 0)

    @vbox_hoken_menu5.pack_start(@kanja_out["kouhi_hutan_4"], false, true, 0)
    @vbox_hoken_menu5.pack_start(@kanja_out["kouhi_line1_4"], false, false, 0)

    @vbox_hoken_data1.pack_start(@kanja_out["roujin_iryou_no_space"], false, false, 0)
    @vbox_hoken_data1.pack_start(@kanja_out["kouhi_line2_0"], false, false, 0)

    @vbox_hoken_data2.pack_start(@kanja_out["kouhi_hutan_1_space"], false, false, 0)
    @vbox_hoken_data2.pack_start(@kanja_out["kouhi_line2_1"], false, false, 0)

    @vbox_hoken_data3.pack_start(@kanja_out["kouhi_hutan_2_space"], false, false, 0)
    @vbox_hoken_data3.pack_start(@kanja_out["kouhi_line2_2"], false, false, 0)

    @vbox_hoken_data4.pack_start(@kanja_out["kouhi_hutan_3_space"], false, false, 0)
    @vbox_hoken_data4.pack_start(@kanja_out["kouhi_line2_3"], false, false, 0)

    @vbox_hoken_data5.pack_start(@kanja_out["kouhi_hutan_4_space"], false, false, 0)
    @vbox_hoken_data5.pack_start(@kanja_out["kouhi_line2_4"], false, false, 0)

    @vbox_hoken2_menu1.pack_start(@kanja_out["towns_no"], false, true, 0)
    @vbox_hoken2_menu1.pack_start(@kanja_out["kouhi_line3_0"], false, false, 0)
    
    @vbox_hoken2_menu2.pack_start(@kanja_out["kouhi_uke_1"], false, true, 0)
    @vbox_hoken2_menu2.pack_start(@kanja_out["kouhi_line3_1"], false, false, 0)

    @vbox_hoken2_menu3.pack_start(@kanja_out["kouhi_uke_2"], false, true, 0)
    @vbox_hoken2_menu3.pack_start(@kanja_out["kouhi_line3_2"], false, false, 0)

    @vbox_hoken2_menu4.pack_start(@kanja_out["kouhi_uke_3"], false, true, 0)
    @vbox_hoken2_menu4.pack_start(@kanja_out["kouhi_line3_3"], false, false, 0)
    
    @vbox_hoken2_menu5.pack_start(@kanja_out["kouhi_uke_4"], false, true, 0)
    @vbox_hoken2_menu5.pack_start(@kanja_out["kouhi_line3_4"], false, false, 0)

    @vbox_hoken2_data1.pack_start(@kanja_out["towns_no_space"], false, false, 0)
    @vbox_hoken2_data1.pack_start(@kanja_out["kouhi_line4_0"], false, false, 0)
    
    @vbox_hoken2_data2.pack_start(@kanja_out["kouhi_uke_1_space"], false, false, 0)
    @vbox_hoken2_data2.pack_start(@kanja_out["kouhi_line4_1"], false, false, 0)

    @vbox_hoken2_data3.pack_start(@kanja_out["kouhi_uke_2_space"], false, false, 0)
    @vbox_hoken2_data3.pack_start(@kanja_out["kouhi_line4_2"], false, false, 0)

    @vbox_hoken2_data4.pack_start(@kanja_out["kouhi_uke_3_space"], false, false, 0)
    @vbox_hoken2_data4.pack_start(@kanja_out["kouhi_line4_3"], false, false, 0)

    @vbox_hoken2_data5.pack_start(@kanja_out["kouhi_uke_4_space"], false, false, 0)
    @vbox_hoken2_data5.pack_start(@kanja_out["kouhi_line4_4"], false, false, 0)

    @vbox_hoken_menu.pack_start(@vbox_hoken_menu1)
    @vbox_hoken_data.pack_start(@vbox_hoken_data1)
    @vbox_hoken2_menu.pack_start(@vbox_hoken2_menu1)
    @vbox_hoken2_data.pack_start(@vbox_hoken2_data1)

    @vbox_hoken_menu.pack_start(@vbox_hoken_menu2)
    @vbox_hoken_data.pack_start(@vbox_hoken_data2)
    @vbox_hoken2_menu.pack_start(@vbox_hoken2_menu2)
    @vbox_hoken2_data.pack_start(@vbox_hoken2_data2)

    @vbox_hoken_menu.pack_start(@vbox_hoken_menu3)
    @vbox_hoken_data.pack_start(@vbox_hoken_data3)
    @vbox_hoken2_menu.pack_start(@vbox_hoken2_menu3)
    @vbox_hoken2_data.pack_start(@vbox_hoken2_data3)

    @vbox_hoken_menu.pack_start(@vbox_hoken_menu4)
    @vbox_hoken_data.pack_start(@vbox_hoken_data4)
    @vbox_hoken2_menu.pack_start(@vbox_hoken2_menu4)
    @vbox_hoken2_data.pack_start(@vbox_hoken2_data4)

    @vbox_hoken_menu.pack_start(@vbox_hoken_menu5)
    @vbox_hoken_data.pack_start(@vbox_hoken_data5)
    @vbox_hoken2_menu.pack_start(@vbox_hoken2_menu5)
    @vbox_hoken2_data.pack_start(@vbox_hoken2_data5)

    @kanja_hbox[6].pack_start(@vbox_hoken_menu, false, true, 0)
    @kanja_hbox[6].pack_start(@kanja_out["kouhi_line5_0"], false, false, 0)
    @kanja_hbox[6].pack_start(@vbox_hoken_data, true, true, 0)
    @kanja_hbox[6].pack_start(@kanja_out["kouhi_line5_1"], false, false, 0)
    @kanja_hbox[6].pack_start(@vbox_hoken2_menu, false, true, 0)
    @kanja_hbox[6].pack_start(@kanja_out["kouhi_line5_2"], false, false, 0)
    @kanja_hbox[6].pack_start(@vbox_hoken2_data, true, true, 0)

    @kanja_out["rr_line0_0"] = Gtk::HSeparator.new
    @kanja_out["rr_line0_1"] = Gtk::HSeparator.new
    @kanja_out["rr_line1_0"] = Gtk::VSeparator.new
    @kanja_out["rr_line1_1"] = Gtk::VSeparator.new
    @kanja_out["rr_line1_2"] = Gtk::VSeparator.new
    @kanja_out["rr_line1_3"] = Gtk::VSeparator.new
    @kanja_out["rr_line1_4"] = Gtk::VSeparator.new
    @kanja_out["rr_line1_5"] = Gtk::HSeparator.new
    @kanja_out["rr_line2_0"] = Gtk::VSeparator.new
    @kanja_out["rr_line2_1"] = Gtk::VSeparator.new
    @kanja_out["rr_line2_2"] = Gtk::VSeparator.new
    @kanja_out["rr_line2_3"] = Gtk::VSeparator.new
    @kanja_out["rr_line2_4"] = Gtk::HSeparator.new
    @kanja_out["rr_line3_0"] = Gtk::VSeparator.new
    @kanja_out["rr_line3_1"] = Gtk::VSeparator.new
    @kanja_out["rr_line3_2"] = Gtk::VSeparator.new
    @kanja_out["rr_line3_3"] = Gtk::VSeparator.new
    @kanja_out["rr_line3_4"] = Gtk::VSeparator.new
    @kanja_out["rr_line3_5"] = Gtk::HSeparator.new
    @kanja_out["rr_line4_0"] = Gtk::VSeparator.new
    @kanja_out["rr_line4_1"] = Gtk::VSeparator.new
    @kanja_out["rr_line4_2"] = Gtk::VSeparator.new
    @kanja_out["rr_line4_3"] = Gtk::HSeparator.new
    @kanja_out["rr_line5_0"] = Gtk::VSeparator.new
    @kanja_out["rr_line5_1"] = Gtk::VSeparator.new
    @kanja_out["rr_line5_2"] = Gtk::HSeparator.new
    @kanja_out["rr_line6_0"] = Gtk::VSeparator.new
    @kanja_out["rr_line6_1"] = Gtk::VSeparator.new
    @kanja_out["rr_line6_2"] = Gtk::HSeparator.new
    @kanja_out["rr_line7_0"] = Gtk::VSeparator.new
    @kanja_out["rr_line7_1"] = Gtk::VSeparator.new
    @kanja_out["rr_line7_2"] = Gtk::HSeparator.new

    @kanja_hbox[7].pack_start(@kanja_out["rr_sick_ymd"], false, true, 0)
    @kanja_hbox[7].pack_start(@kanja_out["rr_line1_0"], false, false, 0)
    @kanja_hbox[7].pack_start(@kanja_out["rr_sick_ymd_space"], true, true, 0)
    @kanja_hbox[7].pack_start(@kanja_out["rr_line1_1"], false, false, 0)
    @kanja_hbox[7].pack_start(@kanja_out["rr_sinkei"], false, true, 0)
    @kanja_hbox[7].pack_start(@kanja_out["rr_line1_2"], false, false, 0)
    @kanja_hbox[7].pack_start(@kanja_out["rr_sinkei_space"], true, true, 0)
    @kanja_hbox[7].pack_start(@kanja_out["rr_line1_3"], false, false, 0)
    @kanja_hbox[7].pack_start(@kanja_out["rr_tenki"], false, true, 0)
    @kanja_hbox[7].pack_start(@kanja_out["rr_line1_4"], false, false, 0)
    @kanja_hbox[7].pack_start(@kanja_out["rr_tenki_space"], true, true, 0)

    @kanja_hbox[8].pack_start(@kanja_out["rr_ryoyo_ymd"], false, true, 0)
    @kanja_hbox[8].pack_start(@kanja_out["rr_line2_0"], false, false, 0)
    @kanja_hbox[8].pack_start(@kanja_out["rr_ryoyo_ymd_space"], true, true, 0)
    @kanja_hbox[8].pack_start(@kanja_out["rr_line2_1"], false, false, 0)
    @kanja_hbox[8].pack_start(@kanja_out["rr_sinryo_ymd"], false, true, 0)
    @kanja_hbox[8].pack_start(@kanja_out["rr_line2_2"], false, false, 0)
    @kanja_hbox[8].pack_start(@kanja_out["rr_sinryo_ymd_space"], true, true, 0)

    @kanja_hbox[9].pack_start(@kanja_out["rr_sum_money"], false, true, 0)
    @kanja_hbox[9].pack_start(@kanja_out["rr_line2_3"], false, false, 0)
    @kanja_hbox[9].pack_start(@kanja_out["rr_sum_money_space"], true, true, 0)

    @kanja_hbox[10].pack_start(@kanja_out["rr_subtotal_tensu"], false, true, 0)
    @kanja_hbox[10].pack_start(@kanja_out["rr_line3_0"], false, false, 0)
    @kanja_hbox[10].pack_start(@kanja_out["rr_subtotal_tensu_space"], true, true, 0)
    @kanja_hbox[10].pack_start(@kanja_out["rr_line3_1"], false, false, 0)
    @kanja_hbox[10].pack_start(@kanja_out["rr_subtotal_tensu2money"], false, true, 0)
    @kanja_hbox[10].pack_start(@kanja_out["rr_line3_2"], false, false, 0)
    @kanja_hbox[10].pack_start(@kanja_out["rr_subtotal_tensu2money_space"], true, true, 0)
    @kanja_hbox[10].pack_start(@kanja_out["rr_line3_3"], false, false, 0)
    @kanja_hbox[10].pack_start(@kanja_out["rr_subtotal_money"], false, true, 0)
    @kanja_hbox[10].pack_start(@kanja_out["rr_line3_4"], false, false, 0)
    @kanja_hbox[10].pack_start(@kanja_out["rr_subtotal_money_space"], true, true, 0)

    @kanja_hbox[11].pack_start(@kanja_out["rr_subtotal_lunchmoney"], false, true, 0)
    @kanja_hbox[11].pack_start(@kanja_out["rr_line4_0"], false, false, 0)
    @kanja_hbox[11].pack_start(@kanja_out["rr_subtotal_lunchmoney_space"], true, true, 0)
    @kanja_hbox[11].pack_start(@kanja_out["rr_line4_1"], false, false, 0)
    @kanja_hbox[11].pack_start(@kanja_out["rr_subtotal_lunchnumber"], false, true, 0)
    @kanja_hbox[11].pack_start(@kanja_out["rr_line4_2"], false, false, 0)
    @kanja_hbox[11].pack_start(@kanja_out["rr_subtotal_lunchnumber_space"], true, true, 0)

    @kanja_hbox[12].pack_start(@kanja_out["rr_line5_0"], false, false, 0)
    @kanja_hbox[12].pack_start(@kanja_out["rr_enterprise_name"], false, true, 0)
    @kanja_hbox[12].pack_start(@kanja_out["rr_line5_1"], false, false, 0)
    @kanja_hbox[12].pack_start(@kanja_out["rr_enterprise_name_space"], false, true, 0)

    @kanja_hbox[13].pack_start(@kanja_out["rr_line6_0"], false, false, 0)
    @kanja_hbox[13].pack_start(@kanja_out["rr_enterprise_addr"], false, true, 0)
    @kanja_hbox[13].pack_start(@kanja_out["rr_line6_1"], false, false, 0)
    @kanja_hbox[13].pack_start(@kanja_out["rr_enterprise_addr_space"], false, true, 0)

    @kanja_hbox[14].pack_start(@kanja_out["rr_line7_0"], false, false, 0)
    @kanja_hbox[14].pack_start(@kanja_out["rr_sickname_after"], false, true, 0)
    @kanja_hbox[14].pack_start(@kanja_out["rr_line7_1"], false, false, 0)
    @kanja_hbox[14].pack_start(@kanja_out["rr_sickname_after_space"], false, true, 0)

    @kanja_hbox[15].pack_start(@byomei_tree, true, true, 0)

    @vbox_ho_ro_ko_menu3 = Gtk::VBox.new(false, 0)
    @vbox_ho_ro_ko_data3 = Gtk::VBox.new(false, 0)
    @vbox_ho_ro_ko_data4 = Gtk::VBox.new(false, 0)
    @vbox_ho_ro_ko_data5 = Gtk::VBox.new(false, 0)
    
    # 保険 event box
    @hoken_b = {}
    @base.kanja_button.each do |key, name|
      @hoken_b[key] = Gtk::EventBox.new
      @hoken_b[key].add_events(Gdk::Event::BUTTON_PRESS_MASK)
      @hoken_b[key].add_events(Gdk::Event::ENTER_NOTIFY_MASK)
      @hoken_b[key].add_events(Gdk::Event::LEAVE_NOTIFY_MASK)
      @hoken_b[key].add(@kanja_out[key])
    end

    @kanja_out["kouhi_1_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_2_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_3_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_4_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_e_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_1_space_r_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_2_space_r_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_3_space_r_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_4_space_r_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_e_space_r_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_1_space_s_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_2_space_s_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_3_space_s_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_4_space_s_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_e_space_s_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_1_space_h_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_2_space_h_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_3_space_h_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_4_space_h_line"] = Gtk::HSeparator.new
    @kanja_out["kouhi_e_space_h_line"] = Gtk::HSeparator.new

    @vbox_ho_ro_ko_menu3.pack_start(@kanja_out["space_space_1"], false, false, 0)
    @vbox_ho_ro_ko_menu3.pack_start(Gtk::HSeparator.new, false, false, 0)

    @vbox_ho_ro_ko_menu3.pack_start(@hoken_b["hoken"], false, true, 0)
    @vbox_ho_ro_ko_menu3.pack_start(@kanja_out["kouhi_1_line"], false, false, 0)

    @vbox_ho_ro_ko_menu3.pack_start(@hoken_b["kouhi_1"], false, true, 0)
    @vbox_ho_ro_ko_menu3.pack_start(@kanja_out["kouhi_2_line"], false, false, 0)

    @vbox_ho_ro_ko_menu3.pack_start(@hoken_b["kouhi_2"], false, true, 0)
    @vbox_ho_ro_ko_menu3.pack_start(@kanja_out["kouhi_3_line"], false, false, 0)

    @vbox_ho_ro_ko_menu3.pack_start(@hoken_b["kouhi_3"], false, true, 0)
    @vbox_ho_ro_ko_menu3.pack_start(@kanja_out["kouhi_4_line"], false, false, 0)

    @vbox_ho_ro_ko_menu3.pack_start(@hoken_b["kouhi_4"], false, true, 0)
    @vbox_ho_ro_ko_menu3.pack_start(@kanja_out["kouhi_e_line"], false, false, 0)

    @vbox_ho_ro_ko_data3.pack_start(@kanja_out["real_days"], false, false, 0)
    @vbox_ho_ro_ko_data3.pack_start(Gtk::HSeparator.new, false, false, 0)
    @vbox_ho_ro_ko_data3.pack_start(@kanja_out["hoken_space_r"], false, false, 0)
    @vbox_ho_ro_ko_data3.pack_start(@kanja_out["kouhi_1_space_r_line"], false, false, 0)
    @vbox_ho_ro_ko_data3.pack_start(@kanja_out["kouhi_1_space_r"], false, false, 0)
    @vbox_ho_ro_ko_data3.pack_start(@kanja_out["kouhi_2_space_r_line"], false, false, 0)
    @vbox_ho_ro_ko_data3.pack_start(@kanja_out["kouhi_2_space_r"], false, false, 0)
    @vbox_ho_ro_ko_data3.pack_start(@kanja_out["kouhi_3_space_r_line"], false, false, 0)
    @vbox_ho_ro_ko_data3.pack_start(@kanja_out["kouhi_3_space_r"], false, false, 0)
    @vbox_ho_ro_ko_data3.pack_start(@kanja_out["kouhi_4_space_r_line"], false, false, 0)
    @vbox_ho_ro_ko_data3.pack_start(@kanja_out["kouhi_4_space_r"], false, false, 0)
    @vbox_ho_ro_ko_data3.pack_start(@kanja_out["kouhi_e_space_r_line"], false, false, 0)
    
    @vbox_ho_ro_ko_data4.pack_start(@kanja_out["seikyu_tensu"], false, false, 0)
    @vbox_ho_ro_ko_data4.pack_start(Gtk::HSeparator.new, false, false, 0)
    @vbox_ho_ro_ko_data4.pack_start(@kanja_out["hoken_space_s"], false, false, 0)
    @vbox_ho_ro_ko_data4.pack_start(@kanja_out["kouhi_1_space_s_line"], false, false, 0)
    @vbox_ho_ro_ko_data4.pack_start(@kanja_out["kouhi_1_space_s"], false, false, 0)
    @vbox_ho_ro_ko_data4.pack_start(@kanja_out["kouhi_2_space_s_line"], false, false, 0)
    @vbox_ho_ro_ko_data4.pack_start(@kanja_out["kouhi_2_space_s"], false, false, 0)
    @vbox_ho_ro_ko_data4.pack_start(@kanja_out["kouhi_3_space_s_line"], false, false, 0)
    @vbox_ho_ro_ko_data4.pack_start(@kanja_out["kouhi_3_space_s"], false, false, 0)
    @vbox_ho_ro_ko_data4.pack_start(@kanja_out["kouhi_4_space_s_line"], false, false, 0)
    @vbox_ho_ro_ko_data4.pack_start(@kanja_out["kouhi_4_space_s"], false, false, 0)
    @vbox_ho_ro_ko_data4.pack_start(@kanja_out["kouhi_e_space_s_line"], false, false, 0)

    @vbox_ho_ro_ko_data5.pack_start(@kanja_out["hutan_money"], false, false, 0)
    @vbox_ho_ro_ko_data5.pack_start(Gtk::HSeparator.new, false, false, 0)
    @vbox_ho_ro_ko_data5.pack_start(@kanja_out["hoken_space_h"], false, false, 0)
    @vbox_ho_ro_ko_data5.pack_start(@kanja_out["kouhi_1_space_h_line"], false, false, 0)
    @vbox_ho_ro_ko_data5.pack_start(@kanja_out["kouhi_1_space_h"], false, false, 0)
    @vbox_ho_ro_ko_data5.pack_start(@kanja_out["kouhi_2_space_h_line"], false, false, 0)
    @vbox_ho_ro_ko_data5.pack_start(@kanja_out["kouhi_2_space_h"], false, false, 0)
    @vbox_ho_ro_ko_data5.pack_start(@kanja_out["kouhi_3_space_h_line"], false, false, 0)
    @vbox_ho_ro_ko_data5.pack_start(@kanja_out["kouhi_3_space_h"], false, false, 0)
    @vbox_ho_ro_ko_data5.pack_start(@kanja_out["kouhi_4_space_h_line"], false, false, 0)
    @vbox_ho_ro_ko_data5.pack_start(@kanja_out["kouhi_4_space_h"], false, false, 0)
    @vbox_ho_ro_ko_data5.pack_start(@kanja_out["kouhi_e_space_h_line"], false, false, 0)

    @kanja_out["kouhi_uke_3"].hide
    @kanja_out["kouhi_hutan_3"].hide
    @kanja_out["kouhi_uke_3_space"].hide
    @kanja_out["kouhi_hutan_3_space"].hide
    @kanja_out["kouhi_uke_4"].hide
    @kanja_out["kouhi_hutan_4"].hide
    @kanja_out["kouhi_uke_4_space"].hide
    @kanja_out["kouhi_hutan_4_space"].hide

    @kanja_out["hosp_day"].hide
    @kanja_out["hosp_day_space"].hide

    @kanja_hbox[16].pack_start(@vbox_ho_ro_ko_menu3, false, false, 0)
    @kanja_hbox[16].pack_start(Gtk::VSeparator.new, false, false, 0)
    @kanja_hbox[16].pack_start(@vbox_ho_ro_ko_data3, true, true, 0)
    @kanja_hbox[16].pack_start(Gtk::VSeparator.new, false, false, 0)
    @kanja_hbox[16].pack_start(@vbox_ho_ro_ko_data4, true, true, 0)
    @kanja_hbox[16].pack_start(Gtk::VSeparator.new, false, false, 0)
    @kanja_hbox[16].pack_start(@vbox_ho_ro_ko_data5, true, true, 0)

    @kanja_hbox[17].pack_start(@kanja_out["raw_code_view"], true, true, 0)
    @kanja_hbox[17].pack_start(@kanja_out["user_progress"], false, true, 0)

    @kanja_box.pack_start(@henrei_hbox, false, false, 0)
    @kanja_box.pack_start(@henrei_sep, false, false, 0)

    # add Separator and Userboxs
    @kanja_box.pack_start(@kanja_hbox[0], false, false, 0)
    @kanja_box.pack_start(Gtk::HSeparator.new, false, false, 0)
    @kanja_box.pack_start(@kanja_hbox[1], false, false, 0)
    @kanja_box.pack_start(Gtk::HSeparator.new, false, false, 0)
    @kanja_box.pack_start(@kanja_hbox[2], false, false, 0)
    @kanja_box.pack_start(Gtk::HSeparator.new, false, false, 0)
    @kanja_box.pack_start(@kanja_hbox[3], false, false, 0)
    @kanja_box.pack_start(Gtk::HSeparator.new, false, false, 0)
    @kanja_box.pack_start(@kanja_hbox[4], false, false, 0)
    @kanja_box.pack_start(@kanja_out["kouhi_line5_3"], false, false, 0)
    @kanja_box.pack_start(@kanja_hbox[5], false, false, 0)
    @kanja_box.pack_start(@kanja_out["kouhi_line6_0"], false, false, 0)
    @kanja_box.pack_start(@kanja_hbox[6], false, false, 0)

    @kanja_box.pack_start(@kanja_hbox[7], false, false, 0)
    @kanja_box.pack_start(@kanja_out["rr_line1_5"], false, false, 0)
    @kanja_box.pack_start(@kanja_hbox[8], false, false, 0)
    @kanja_box.pack_start(@kanja_out["rr_line2_4"], false, false, 0)
    @kanja_box.pack_start(@kanja_hbox[9], false, false, 0)
    @kanja_box.pack_start(@kanja_out["rr_line3_5"], false, false, 0)
    @kanja_box.pack_start(@kanja_hbox[10], false, false, 0)
    @kanja_box.pack_start(@kanja_out["rr_line4_3"], false, false, 0)
    @kanja_box.pack_start(@kanja_hbox[11], false, false, 0)
    @kanja_box.pack_start(@kanja_out["rr_line5_2"], false, false, 0)
    @kanja_box.pack_start(@kanja_hbox[12], false, false, 0)
    @kanja_box.pack_start(@kanja_out["rr_line6_2"], false, false, 0)
    @kanja_box.pack_start(@kanja_hbox[13], false, false, 0)
    @kanja_box.pack_start(@kanja_out["rr_line7_2"], false, false, 0)

    @kanja_box.pack_start(@kanja_hbox[14], false, false, 0)
    @kanja_box.pack_start(@kanja_hbox[15], false, false, 0)
    @kanja_box.pack_start(@kanja_hbox[16], false, false, 0)

    # Last Separator
    @kanja_box.pack_start(Gtk::HSeparator.new, false, false, 0)
  end

  # ProgressBar Update
  def progress_add(real_int, prog_time, progress, upsize)
    if (real_int % prog_time) == 0
      if progress.fraction <= 0.74
        progress.fraction = (real_int / prog_time).to_f / 100
      end
      progress.set_text("#{(progress.fraction * 100).round}%")
      sleep 0.001
    end
  end

  # ScrollWindow 前回の位置
  def user_view_adjustment(sc_value)
    sc_v  = sc_value.to_i
    ajust = Gtk::Adjustment.new(sc_v,sc_v,sc_v,sc_v,0,0)
    @sw_ir.set_vadjustment(ajust)
  end

  # TreeView 広げる範囲
  def array_joins_size(arr)
    list = []
    if arr.class == Array
      arr.flatten.each do |a|
        list.push(a.split(/,/)[0])
      end
    end
    return list.uniq.sort.size
  end

  # TreeView から iter取得
  def get_tree_data(tree, id=nil)
    path_sc = self.tree_column_no(tree)
    if !path_sc.to_s.empty?
      path_o = Gtk::TreePath.new(path_sc)
      iter = tree.model.get_iter(path_o)
      if id == nil
        sc = iter
      else
        sc = iter[id.to_i].to_s
      end
    else
      sc = ""
    end
    return sc
  end

  # TreeView PathからIter作成
  def tree_path_one(tree, select_status)
    path_o = Gtk::TreePath.new(select_status)
    iter = tree.model.get_iter(path_o)
    return iter
  end

  # TreeView 展開
  def tree_expand_row(tree, arr1, arr2)
    arr1.size.times do |n|
      n2 = n.to_s + ":1"

      tree.expand_row(Gtk::TreePath.new(n), false)
      tree.expand_row(Gtk::TreePath.new(n2), false)

      arr2[n].size.times do |m|
        n3 = n2.to_s + ":#{m.to_s}"
        tree.expand_row(Gtk::TreePath.new(n3), false)
      end
    end
  end

  # TreeView 展開[指定]
  def tree_expand_row_recal(tree, arr)
    if arr.class == Array
      expand_size = arr.size
    else
      expand_size = arr.to_i
    end
    expand_size.times do |n|
      tree.expand_row(Gtk::TreePath.new(n), false)
    end
  end

  # TreeView Columnの有効なリスト取得
  def tree_path_list(tree, era)
    path_o = []
    pt_set = ""
    era.to_i
    tree.model.each do |model, path, iter|
      buf_flg = false
      pt_set = ""
      pt = path.to_s.split(/:/)
      era.times do |tree_int|
        if !pt[tree_int].to_s.empty?
          pt_set = pt_set + pt[tree_int].to_s + ":"
        else
          buf_flg = true
          break
        end
      end
      if !buf_flg
        path_o.push(pt_set.sub(/:$/, ""))
      end
    end
    return path_o
  end

  def paned_maximize_size(paned, window, wsize_x, paned_size)
    if window.class == Gtk::Window
      resize_size = paned_size.to_f / (window.screen.width.to_f / wsize_x.to_f)
      return resize_size.to_i + paned.handle_size
    else
      return paned_size
    end
  end

  # TreeView 選択中のColumn番号取得
  def tree_column_no_heading(tree, line=0)
    return self.tree_column_no(tree).split(/:/)[line].to_s
  end

  # IR TreeView 選択中のColumn番号取得
  def tree_column_no_ir_record
    return self.tree_column_no(@ir_tree)
  end

  # TreeView 選択中のColumn番号取得
  def tree_column_no(tree)
    if tree.selection.selected != nil
      column_data = tree.selection.selected.get_value(9).to_s
      column_no = ""
      column_ir = ""
      tree.selection.selected_each do |a, b, flg|
        flg_tmp = flg.to_s.split(/:/)
        if flg_tmp.size >= 3
          if flg_tmp[1].to_s == "1"
            column_no = flg.to_s
          end
        elsif flg_tmp.size == 2
          if flg_tmp[1].to_s == "0"
            column_ir = flg.to_s.split(/:/)[1]
          end
        elsif flg_tmp.size == 1
          column_ir = flg.to_s
        end
      end
      if /\d+/ =~ column_data and !column_no.empty?
        return column_no
      end
    end
  end

  # TreeView TreePathに渡すpath配列を作成
  def tree_path_make(record)
    n3 = 0
    n4 = 0
    no_up = ""
    a_record = []
    record.each_with_index do |n_check, nup|
      if no_up != n_check[0].to_s
        no_up = n_check[0].to_s
        n3 = 0
      end
      n2 = no_up + ":1"
      if n_check[3].to_i == 4
        path = n2.to_s + ":" + n3.to_s + ":" + n4.to_s
        n4+=1
        if record[nup+1] != nil
          if record[nup+1][3].to_i != 4
            n3+=1 
          end
        end
      else
        n4 = 0
        path = n2.to_s + ":" + n3.to_s
        if record[nup+1] != nil
          if record[nup+1][3].to_i != 4
            n3+=1 
          end
        else
          n3+=1
        end
      end
      a_record.push(path)
    end
    return a_record
  end

  # TreeView TreePathに渡すpath配列,record配列を作成
  def tree_path_make_marge_record(record)
    n3 = 0
    n4 = 0
    no_up = ""
    a_record = []
    record.each_with_index do |n_check, nup|
      if no_up != n_check[0].to_s
        no_up = n_check[0].to_s
        n3 = 0
      end
      n2 = no_up + ":1"
      if n_check[3].to_i == 4
        path = n2.to_s + ":" + n3.to_s + ":" + n4.to_s
        n4+=1
        if record[nup+1] != nil
          if record[nup+1][3].to_i != 4
            n3+=1 
          end
        end
      else
        n4 = 0
        path = n2.to_s + ":" + n3.to_s
        if record[nup+1] != nil
          if record[nup+1][3].to_i != 4
            n3+=1 
          end
        else
          n3+=1
        end
      end
      a_record.push([path, n_check])
    end
    return a_record
  end

  # TreeView 選択されたColumnから位置の判定
  def tree_selection(tree)
    column_ir = ""
    column_no = ""

    tree.selection.selected_each do |a, b, flg|
      flg_tmp  = flg.to_s.split(/:/)
      flg_size = flg_tmp.size
      case flg_size
      when 4
        if flg_tmp[1].to_s == "1"
          column_no = flg.to_s
        end
      when 3
        if flg_tmp[1].to_s == "1"
          column_no = flg.to_s
        end
      when 2
        if flg_tmp[1].to_s == "0"
          column_ir = flg.to_s.split(/:/)[1].to_s
        end
      when 1
        column_ir = flg.to_s
      end
    end
    return [column_ir, column_no]
  end

  # TreeView 選択されたColumnから位置の判定
  def tree_selection_plus(tree)
    column, no = tree_selection(tree)
    select_no = no.split(/:/)
    t = select_no[2].to_i+1
    if select_no.size != 0
      select_no[2] = t.to_s
      column = select_no.join(":")
    else
      column = nil
    end
    return column
  end

  def tree_selection_minas(tree)
    column, no = tree_selection(tree)
    select_no = no.split(/:/)
    t = select_no[2].to_i-1
    if select_no.size != 0 && t >= 0
      select_no[2] = t.to_s
      column = select_no.join(":")
    else
      column = nil
    end
    return column
  end

  # TreeView 選択されたColumnのチェックデータを書き換える
  def tree_image_draw(column_no, check_flg)
    time       = Time.new
    path_o     = Gtk::TreePath.new(column_no)
    iter       = @ir_tree.model.get_iter(path_o)
    image      = iter[0]
    image_stat = iter[12]

    case check_flg
    when "ok"
      if image_stat == "stop"
        image = @icon_image["stop"]
        image_stat = "stop"
      else
        image = @icon_image["ok"]
        image_stat = "ok"
      end
    when "stop"
      image = @icon_image["stop"]
      image_stat = "stop"
    when "no"
      image = nil
      image_stat = ""
    when "compulsion"
      image = @icon_image["ok"]
      image_stat = "ok"
    else
      image = nil
      image_stat = ""
    end

    iter[0]  = image
    iter[11] = time.strftime("%x  %X").to_s
    iter[12] = image_stat
  end

  # フォントを設定
  def set_font_style(font_name=nil)
    font = Pango::FontDescription.new(font_name)
    kanja_style = Gtk::Style.new.set_font_desc(font)
    kanja_style.set_fg(Gtk::STATE_NORMAL, 0, 0, 0)

    if kanja_style != nil and font_name != nil
      @kanja_out["name"].set_style(kanja_style)
      @kanja_out["name_space"].set_style(kanja_style)
      @kanja_out["hoken_no"].set_style(kanja_style)
      @kanja_out["hoken_no_space"].set_style(kanja_style)
      @kanja_out["sign"].set_style(kanja_style)
      @kanja_out["sign_space"].set_style(kanja_style)
      @kanja_out["bango"].set_style(kanja_style)
      @kanja_out["bango_space"].set_style(kanja_style)

      @kanja_out["sinryo_ymd"].set_style(kanja_style)
      @kanja_out["receipt_syubetu"].set_style(kanja_style)
      @kanja_out["kanja_status"].set_style(kanja_style)
      @kanja_out["receipt_no"].set_style(kanja_style)
      @kanja_out["receipt_no_space"].set_style(kanja_style)

      @kanja_out["kanja_no"].set_style(kanja_style)
      @kanja_out["kanja_no_space"].set_style(kanja_style)
      @kanja_out["hosp_day"].set_style(kanja_style)
      @kanja_out["hosp_day_space"].set_style(kanja_style)

      @kanja_out["sex"].set_style(kanja_style)
      @kanja_out["sex_space"].set_style(kanja_style)
      @kanja_out["age"].set_style(kanja_style)
      @kanja_out["age_space"].set_style(kanja_style)
      @kanja_out["birthday"].set_style(kanja_style)
      @kanja_out["birthday_space"].set_style(kanja_style)

      @kanja_out["roujin_iryou_no"].set_style(kanja_style)
      @kanja_out["roujin_iryou_no_space"].set_style(kanja_style)
      @kanja_out["towns_no"].set_style(kanja_style)
      @kanja_out["towns_no_space"].set_style(kanja_style)

      @kanja_out["kouhi_hutan_1"].set_style(kanja_style)
      @kanja_out["kouhi_hutan_1_space"].set_style(kanja_style)
      @kanja_out["kouhi_hutan_2"].set_style(kanja_style)
      @kanja_out["kouhi_hutan_2_space"].set_style(kanja_style)
      @kanja_out["kouhi_hutan_3"].set_style(kanja_style)
      @kanja_out["kouhi_hutan_3_space"].set_style(kanja_style)
      @kanja_out["kouhi_hutan_4"].set_style(kanja_style)
      @kanja_out["kouhi_hutan_4_space"].set_style(kanja_style)

      @kanja_out["kouhi_uke_1"].set_style(kanja_style)
      @kanja_out["kouhi_uke_1_space"].set_style(kanja_style)
      @kanja_out["kouhi_uke_2"].set_style(kanja_style)
      @kanja_out["kouhi_uke_2_space"].set_style(kanja_style)
      @kanja_out["kouhi_uke_3"].set_style(kanja_style)
      @kanja_out["kouhi_uke_3_space"].set_style(kanja_style)
      @kanja_out["kouhi_uke_4"].set_style(kanja_style)
      @kanja_out["kouhi_uke_4_space"].set_style(kanja_style)

      @kanja_out["space_space_1"].set_style(kanja_style)
      @kanja_out["real_days"].set_style(kanja_style)
      @kanja_out["seikyu_tensu"].set_style(kanja_style)
      @kanja_out["hutan_money"].set_style(kanja_style)

      @kanja_out["hoken"].set_style(kanja_style)
      @kanja_out["hoken_space_r"].set_style(kanja_style)
      @kanja_out["hoken_space_s"].set_style(kanja_style)
      @kanja_out["hoken_space_h"].set_style(kanja_style)

      @kanja_out["kouhi_1"].set_style(kanja_style)
      @kanja_out["kouhi_1_space_r"].set_style(kanja_style)
      @kanja_out["kouhi_1_space_s"].set_style(kanja_style)
      @kanja_out["kouhi_1_space_h"].set_style(kanja_style)

      @kanja_out["kouhi_2"].set_style(kanja_style)
      @kanja_out["kouhi_2_space_r"].set_style(kanja_style)
      @kanja_out["kouhi_2_space_s"].set_style(kanja_style)
      @kanja_out["kouhi_2_space_h"].set_style(kanja_style)

      @kanja_out["kouhi_3"].set_style(kanja_style)
      @kanja_out["kouhi_3_space_r"].set_style(kanja_style)
      @kanja_out["kouhi_3_space_s"].set_style(kanja_style)
      @kanja_out["kouhi_3_space_h"].set_style(kanja_style)

      @kanja_out["kouhi_4"].set_style(kanja_style)
      @kanja_out["kouhi_4_space_r"].set_style(kanja_style)
      @kanja_out["kouhi_4_space_s"].set_style(kanja_style)
      @kanja_out["kouhi_4_space_h"].set_style(kanja_style)

      @kanja_out["rr_sick_ymd"].set_style(kanja_style)
      @kanja_out["rr_sick_ymd_space"].set_style(kanja_style)
      @kanja_out["rr_sinkei"].set_style(kanja_style)
      @kanja_out["rr_sinkei_space"].set_style(kanja_style)
      @kanja_out["rr_tenki"].set_style(kanja_style)
      @kanja_out["rr_tenki_space"].set_style(kanja_style)
      @kanja_out["rr_ryoyo_ymd"].set_style(kanja_style)
      @kanja_out["rr_ryoyo_ymd_space"].set_style(kanja_style)
      @kanja_out["rr_sinryo_ymd"].set_style(kanja_style)
      @kanja_out["rr_sinryo_ymd_space"].set_style(kanja_style)
      @kanja_out["rr_sum_money"].set_style(kanja_style)
      @kanja_out["rr_sum_money_space"].set_style(kanja_style)

      @kanja_out["rr_subtotal_tensu"].set_style(kanja_style)
      @kanja_out["rr_subtotal_tensu_space"].set_style(kanja_style)
      @kanja_out["rr_subtotal_tensu2money"].set_style(kanja_style)
      @kanja_out["rr_subtotal_tensu2money_space"].set_style(kanja_style)
      @kanja_out["rr_subtotal_money"].set_style(kanja_style)
      @kanja_out["rr_subtotal_money_space"].set_style(kanja_style)
      @kanja_out["rr_subtotal_lunchmoney"].set_style(kanja_style)
      @kanja_out["rr_subtotal_lunchmoney_space"].set_style(kanja_style)
      @kanja_out["rr_subtotal_lunchnumber"].set_style(kanja_style)
      @kanja_out["rr_subtotal_lunchnumber_space"].set_style(kanja_style)

      @kanja_out["rr_enterprise_name"].set_style(kanja_style)
      @kanja_out["rr_enterprise_name_space"].set_style(kanja_style)
      @kanja_out["rr_enterprise_addr"].set_style(kanja_style)
      @kanja_out["rr_enterprise_addr_space"].set_style(kanja_style)
      @kanja_out["rr_sickname_after"].set_style(kanja_style)
      @kanja_out["rr_sickname_after_space"].set_style(kanja_style)

      @kanja_out["raw_code_view"].set_style(kanja_style)
    end
  end

  def tab_init
    @main_tab = Gtk::Notebook.new
    @user_tab = Gtk::Notebook.new
    @main_tab.homogeneous = true
    @user_tab.homogeneous = true
  end

  def window_init
    @main_window = Gtk::Window.new
    @icon_image = {
      "ok" => @main_window.render_icon(Gtk::Stock::OK, 
                                  Gtk::IconSize::MENU, "icon1"),
      "stop" => @main_window.render_icon(Gtk::Stock::STOP, 
                                  Gtk::IconSize::MENU, "icon2")
    }
    ReceViewGUI::SettingIcon(@main_window)
    @main_window.set_title(@base.title)
    @window_event_state = 'none'
    return @main_window
  end

  # 患者情報 IR Tree model
  # 0  Pixbuf image data
  # 1  RECEIPT No
  # 2  User No
  # 3  User Name
  # 4  Medical Code
  # 5  Status
  # 6  Japan YYMM
  # 7  
  # 8  Color  Tree BackColor
  # 9  Sort User No Date
  # 10 Sort User Name Date
  # 11 String tech time
  # 12 String image status
  # 13 String MD5
  # 14 Color Tree BackColor2
  def tree_model_ir_init
    @tree_model_ir_size = 15
    @tree_model_ir = Gtk::TreeStore.new(Gdk::Pixbuf, 
      String, 
      String, 
      String, 
      String, 
      String, 
      String, 
      String, 
      Gdk::Color, 
      Integer, 
      String, 
      String, 
      String, 
      String, 
      Gdk::Color)
  end

  # 統計データ RE Tree model
  def tree_model_re_init
    @tree_model_re_size = 9
    @tree_model_re = Gtk::TreeStore.new(String,
      String,
      String,
      String, 
      String,
      String,
      String, 
      String,
      Gdk::Color)
  end

  # 病名データ SICK Tree model
  def tree_model_sick_init
    @tree_model_sick_size = 4
    @tree_model_sick = Gtk::TreeStore.new(String,
      String,
      String,
      String)
  end

  # 病名データ労災用 SICK Tree model
  def tree_model_rsick_init
    @tree_model_rsick_size = 6
    @tree_model_rsick = Gtk::TreeStore.new(String,
      String,
      String,
      String,
      String,
      String)
  end

  # 摘要欄データ TEKYOU Tree model
  def tree_model_teki_init
    @tree_model_teki_size = 5
    @tree_model_teki = Gtk::TreeStore.new(String,
      String,
      String,
      String,
      String)
  end

  # 算定日欄 SANTEI Tree model
  def tree_model_santei_init
    @tree_model_santei_size = 38
    @tree_model_santei = Gtk::TreeStore.new(String, String, String, String, String, 
                            String, String, String, String, String,
                            String, String, String, String, String,
                            String, String, String, String, String,
                            String, String, String, String, String,
                            String, String, String, String, String,
                            String, String, String, String, String,
                            String, Gdk::Color, Gdk::Color)
  end

  # プリントスプール Tree model
  def tree_model_print_init
    @tree_model_print_size = 8
    @tree_model_print = Gtk::TreeStore.new(
      String,
      String,
      String,
      String,
      String,
      String,
      String,
      String
    )
  end

  # プリントスプールPDF Tree model
  def tree_model_print_pdf_init
    @tree_model_print_pdf_size = 8
    @tree_model_print_pdf = Gtk::TreeStore.new(
      String,
      String,
      String,
      String,
      String,
      String,
      String,
      String
    )
  end

  # プリントスプール履歴 Tree model
  def tree_model_print_history_init
    @tree_model_print_history_size = 8
    @tree_model_print_history = Gtk::TreeStore.new(
      String,
      String,
      String,
      String,
      String,
      String,
      String,
      String
    )
  end

  # 検索 Find Tree model
  def tree_model_search_init
    @tree_model_search_csvsize = 4
    @tree_model_search_size = 8
    @tree_model_search = Gtk::TreeStore.new(
      String,
      String,
      String,
      String,
      Gdk::Color,
      Integer,
      Integer,
      Integer
    )
  end

  # TreeView Column Format
  def model_clear
    @tree_model_ir.clear
    @tree_model_re.clear
    @tree_model_sick.clear
    @tree_model_rsick.clear
    @tree_model_teki.clear
    @tree_model_santei.clear
    @tree_model_print.clear
    @tree_model_print_pdf.clear
    @tree_model_print_history.clear
  end

  def scrolled_window_init
    @sw_ir = Gtk::ScrolledWindow.new
    @sw_re = Gtk::ScrolledWindow.new
    @sw_kanja = Gtk::ScrolledWindow.new
    @sw_tekiyo = Gtk::ScrolledWindow.new

    @sw_ir.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    @sw_re.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    @sw_kanja.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    @sw_tekiyo.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
  end

  def status_bar_init
    @status_bar = Gtk::Label.new(@base.total_label)
  end

  def set_status_bar_font(font_name)
    font = Pango::FontDescription.new(font_name)
    style = Gtk::Style.new.set_font_desc(font)
    style.set_fg(Gtk::STATE_NORMAL, 10000, 0, 50000)
    @status_bar.set_style(style)
  end

  def dialog_etc_setting(trans="")
    geometry = Gdk::Geometry.new
    geometry.set_min_width(320)
    geometry.set_min_height(220)
    geometry.set_max_width(320)
    geometry.set_max_height(220)
    mask = Gdk::Window::HINT_MIN_SIZE | 
           Gdk::Window::HINT_MAX_SIZE | Gdk::Window::HINT_RESIZE_INC
    dialog = Gtk::Dialog.new
    dialog.set_title("その他の設定")
    dialog.set_modal(true)
    dialog.set_has_separator(false)
    ReceViewGUI::SettingIcon(dialog)
    ReceViewGUI::TransWindow(dialog, trans)

    ok_button = Gtk::Button.new(Gtk::Stock::OK)
    cancel_button = Gtk::Button.new(Gtk::Stock::CLOSE)
    etc_vbox = Gtk::VBox.new

    accel = Gtk::AccelGroup.new
    accel.connect(Gdk::Keyval::GDK_Escape, nil, Gtk::ACCEL_VISIBLE) do
      cancel_button.signal_emit("clicked")
    end
    dialog.add_accel_group(accel)

    # 最終ディレクトリの保存
    dir_select_button = Gtk::Button.new("選択")
    dir_combox = Gtk::ComboBox.new
    dir_entry = Gtk::Entry.new

    dir_vbox = Gtk::VBox.new
    dir_vbox2 = Gtk::VBox.new
    dir_entry_box = Gtk::HBox.new

    @base.etc_directory_method.each_with_index do |val, index|
      dir_combox.append_text(val)
    end
    dir_combox.active = 0

    dir_entry_box.pack_start(dir_entry, true, true, 0)
    dir_entry_box.pack_start(dir_select_button, false, true, 0)

    dir_vbox.pack_start(dir_combox, true, true, 5)
    dir_vbox.pack_start(dir_entry_box, false, true, 5)

    dir_vbox2.pack_start(dir_vbox, false, true, 0)

    frame_directory = Gtk::Frame.new("最終ディレクトリの保存")
    frame_directory.add(dir_vbox2)

    dir_fs = dialog_fs(dialog, "固定ファイルの選択", nil)
    dir_fs_dialog = dir_fs["dialog"]
    dir_fs_ok = dir_fs["dialog"].ok_button
    dir_fs_cancel = dir_fs["dialog"].cancel_button

    etc_vbox.pack_start(frame_directory, false, true, 10)
    # end

    # ダイアログ設定
    fs_combox = Gtk::ComboBox.new
    fs_vbox = Gtk::VBox.new

    @base.etc_fileselect_method.each_with_index do |val, index|
      fs_combox.append_text(val)
    end
    fs_combox.active = 0

    fs_vbox.pack_start(fs_combox, true, true, 5)

    frame_fileselect = Gtk::Frame.new("ファイル選択ダイアログの表示")
    frame_fileselect.add(fs_vbox)

    etc_vbox.pack_start(frame_fileselect, false, true, 10)

    if /linux|mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      fs_combox.set_sensitive(false)
    end
    # end

    dialog.action_area.pack_start(ok_button)
    dialog.action_area.pack_start(cancel_button)
    dialog.vbox.pack_start(etc_vbox)
    dialog.set_geometry_hints(nil, geometry, mask)
    ok_button.grab_focus

    dir_fs_ok.signal_connect("clicked") do
      dir_entry.set_text(dir_fs_dialog.filename)
      dir_fs_dialog.hide
    end

    dir_fs_cancel.signal_connect("clicked") do
      dir_fs_dialog.hide
    end

    ok_button.signal_connect("clicked") do
      dialog.hide
    end

    cancel_button.signal_connect("clicked") do
      dialog.hide
    end

    dir_select_button.signal_connect("clicked") do
      dir_fs_dialog.show
    end

    dialog.signal_connect("delete_event") do
      dialog.hide
      true
    end

    return {
      "dialog" => dialog,
      "ok_button" => ok_button,
      "cancel_button" => cancel_button,
      "dir.combox" => dir_combox,
      "dir.entry" => dir_entry,
      "dir.entry_box" => dir_entry_box,
      "dir.select_button" => dir_select_button,
      "dir.select_dialog" => dir_fs_dialog,
      "fs.combox" => fs_combox,
    }
  end

  def dialog_fs(trans="", title="", mode="", reverse=true)
    title = @base.file_title_edit if title.to_s.empty?
    fs = ReceViewGUI::FS.new(title, reverse)

    fs.set_modal(true)
    ReceViewGUI::SettingIcon(fs)
    ReceViewGUI::TransWindow(fs, trans)

    # warning: GRClosure invoking callback: already destroyed
    file_list = fs.file_list
    dir_list  = fs.dir_list
    fs.hide_fileop_buttons

    begin
      if mode == "dir_only"
        file_list.set_sensitive(false)
        fs.set_default_size(640,480)
      else
        file_list.set_sensitive(true)
      end
    rescue
      fs.set_default_size(640,480)
    end

    fs.signal_connect("delete_event") do
      true
    end

    file_list.signal_connect("cursor-changed") do
      fs.ok_button.clicked
    end
    
    dir_list.signal_connect("cursor-changed") do
      dir_list.selection.selected_each do |list_store, tree_path, iter_path|
        dir_list.signal_emit("row-activated", tree_path, nil)
      end
    end

    return {
      "dialog" => fs, 
      "dir_list" => dir_list,
      "file_list" => file_list
    }
  end

  # old
  def dialog_recal(window)
    geometry = Gdk::Geometry.new
    geometry.set_min_width(480)
    geometry.set_min_height(420)
    geometry.set_max_width(1000)
    geometry.set_max_height(800)
    mask = Gdk::Window::HINT_MIN_SIZE | Gdk::Window::HINT_MAX_SIZE
    dialog = Gtk::Dialog.new
    dialog.set_title("[点数チェック]")
    dialog.set_modal(false)            
    ReceViewGUI::TransWindow(dialog, window)

    vbox = Gtk::VBox.new
    exit_button = Gtk::Button.new(Gtk::Stock::CLOSE)

    model= Gtk::TreeStore.new(String, String, String, String, String, String, Gdk::Color)
    ctree_recal = Gtk::TreeView.new(model)
    column_data = ["レセ番号", "患者番号", "保険", "再計算点数", "請求点数","状態"]
    column_data.each_with_index do |item, i|
      tree_render = Gtk::CellRendererText.new
      case i
      when 2
        tree_render.xalign = 0.0
      else
        tree_render.xalign = 1.0
      end
      column = Gtk::TreeViewColumn.new(item, tree_render, 
        { :text => i,
          :background_gdk => 6
        })
      ctree_recal.append_column(column)
    end

    # 寄せ 1.0=L 2.0=R 0.5=Cnter
    ctree_recal.get_column(0).set_alignment(0.5)
    ctree_recal.get_column(1).set_alignment(0.5)
    ctree_recal.get_column(2).set_alignment(0.5)
    ctree_recal.get_column(3).set_alignment(0.5)
    ctree_recal.get_column(4).set_alignment(0.5)
    ctree_recal.get_column(5).set_alignment(0.5)

    sw1 = Gtk::ScrolledWindow.new
    sw1.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    sw1.add(ctree_recal)
    vbox.pack_start(sw1, true, true, 5)

    dialog.action_area.pack_start(exit_button)
    dialog.vbox.pack_start(vbox)

    accel = Gtk::AccelGroup.new
    accel.connect(Gdk::Keyval::GDK_T, Gdk::Window::CONTROL_MASK,
      Gtk::ACCEL_VISIBLE) do
        exit_button.signal_emit("clicked")
    end
    dialog.add_accel_group(accel)

    dialog.set_geometry_hints(nil, geometry, mask)
    dialog.hide

    exit_button.signal_connect("clicked") do
      dialog.hide
    end

    dialog.signal_connect("delete_event") do
      dialog.hide
    end

    return {
      "dialog" => dialog,
      "treeview" => ctree_recal,
      "model" => model
    }
  end

  def preview_area(tmp_png="/tmp/out_rece.png")

    File.delete(tmp_png) if File.exist?(tmp_png.to_s)
    
    event_box = PreView_Widget.new
    layout = Gtk::Layout.new
    vbox = Gtk::VBox.new

    event_box.set_size_request(0, 0)
    layout.put(event_box, 0, 0)

    vbox.pack_start(layout, true, true, 5)

    @preview_object["preview.box"] = vbox
    @preview_object["preview.ebox"] = event_box
    @preview_object["preview.layout"] = layout

    return {
      "box" => vbox,
      "layout" => layout,
      "event_box" => event_box
    }
  end

  def preview_box_init
    @preview_object = {}
    scroll_mode = false
    pv_area = self.preview_area(nil)

    pv_base_expander = Gtk::Expander.new("プレビュー ツールボックス")
    pv_base_expander.expanded = true

    pv_hbox = Gtk::HBox.new(false, 0)
    pv_hbox_sc = Gtk::HBox.new(false, 0)
    pv_vbox = Gtk::VBox.new(false, 0)

    pv_page_combox = Gtk::ComboBox.new
    pv_page_combox.set_sensitive(false)
    pv_page_combox.active = 0

    pv_scale_label = Gtk::Label.new("スケール：")
    pv_scale_entry = Gtk::Entry.new
    pv_scale_entry.set_editable(false)
    pv_scale_entry.set_size_request(52,24)

    pv_up_button = Gtk::Button.new("拡大")
    pv_up_button.set_image(Gtk::Image.new(Gtk::Stock::ZOOM_IN,
                                     Gtk::IconSize::MENU))
    pv_down_button = Gtk::Button.new("縮小")
    pv_down_button.set_image(Gtk::Image.new(Gtk::Stock::ZOOM_OUT,
                                     Gtk::IconSize::MENU))
    pv_fit_button = Gtk::Button.new("フィット")
    pv_fit_button.set_image(Gtk::Image.new(Gtk::Stock::ZOOM_FIT,
                                     Gtk::IconSize::MENU))
    pv_100_button = Gtk::Button.new("標準")
    pv_100_button.set_image(Gtk::Image.new(Gtk::Stock::ZOOM_100,
                                     Gtk::IconSize::MENU))
    pv_out_button = Gtk::Button.new("出力")
    pv_out_button.set_image(Gtk::Image.new(Gtk::Stock::CONVERT,
                                     Gtk::IconSize::MENU))
    pv_print_button = Gtk::Button.new("印刷")
    pv_print_button.set_image(Gtk::Image.new(Gtk::Stock::PRINT,
                                     Gtk::IconSize::MENU))
    if !@print
      pv_print_button.set_sensitive(false)
    end

    pv_hbox_sc.pack_start(pv_page_combox, true, true, 0)
    pv_hbox_sc.pack_start(pv_scale_label, true, true, 0)
    pv_hbox_sc.pack_start(pv_scale_entry, true, true, 0)

    pv_hbox.pack_start(pv_hbox_sc, false, false, 0)
    pv_hbox.pack_start(pv_100_button, false, false, 0)
    pv_hbox.pack_start(pv_fit_button, false, false, 0)
    pv_hbox.pack_start(pv_down_button, false, false, 0)
    pv_hbox.pack_start(pv_up_button, false, false, 0)
    pv_hbox.pack_start(pv_out_button, false, false, 0)
    pv_hbox.pack_start(pv_print_button, false, false, 0)

    pv_base_expander.add(pv_hbox)
    pv_vbox.pack_start(pv_base_expander, false, true, 0)
    #pv_vbox.pack_start(pv_hbox, false, true, 0)
    pv_vbox.pack_start(Gtk::HSeparator.new, false, false, 0)
    pv_vbox.pack_start(pv_area["box"], true, true, 0)

    @preview_object["preview.scroll_mode"] = scroll_mode
    @preview_object["preview.button.up"] = pv_up_button
    @preview_object["preview.button.down"] = pv_down_button
    @preview_object["preview.button.fit"] = pv_fit_button
    @preview_object["preview.button.100"] = pv_100_button
    @preview_object["preview.button.out"] = pv_out_button
    @preview_object["preview.button.print"] = pv_print_button
    @preview_object["preview.entry.scale"] = pv_scale_entry
    @preview_object["preview.combox.page"] = pv_page_combox
    @preview_object["preview.pv_box"] = pv_vbox
    @preview_object["preview.pv_expander"] = pv_base_expander
    @preview_object["preview.signal"] = ""
  end

  def preview_button(status=true)
    case status
    when true
      @preview_object["preview.button.up"].set_sensitive(true)
      @preview_object["preview.button.down"].set_sensitive(true)
      @preview_object["preview.button.fit"].set_sensitive(true)
      @preview_object["preview.button.100"].set_sensitive(true)
      @preview_object["preview.button.out"].set_sensitive(true)
      @preview_object["preview.entry.scale"].set_sensitive(true)
      @preview_object["preview.combox.page"].set_sensitive(true)
      if @print
        @preview_object["preview.button.print"].set_sensitive(true)
      end
      true
    when false
      @preview_object["preview.button.up"].set_sensitive(false)
      @preview_object["preview.button.down"].set_sensitive(false)
      @preview_object["preview.button.fit"].set_sensitive(false)
      @preview_object["preview.button.100"].set_sensitive(false)
      @preview_object["preview.button.out"].set_sensitive(false)
      @preview_object["preview.button.print"].set_sensitive(false)
      @preview_object["preview.entry.scale"].set_sensitive(false)
      @preview_object["preview.combox.page"].set_sensitive(false)
      false
    else
      nil
    end
  end

  # レセ電コード 個別
  def view_box(trans=nil)
    @viewbox_object = {}

    sw = Gtk::ScrolledWindow.new
    view = Gtk::SourceView.new
    vbox = Gtk::VBox.new(false, 0)
    text_hbox = Gtk::HBox.new(false, 0)
    tool_hbox = Gtk::HBox.new(false, 0)

    text_print_button = Gtk::Button.new("レセ電データの印刷")
    text_print_button.set_image(Gtk::Image.new(Gtk::Stock::PRINT,
                                     Gtk::IconSize::MENU))
    if !@print
      text_print_button.set_sensitive(false)
    end

    sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    
    view.set_show_line_numbers(true)
    view.editable = false
    view.grab_focus

    view.set_border_window_size(Gtk::TextView::WINDOW_LEFT, 2)
    view.set_border_window_size(Gtk::TextView::WINDOW_RIGHT, 2)
    view.set_border_window_size(Gtk::TextView::WINDOW_TOP, 2)
    view.set_border_window_size(Gtk::TextView::WINDOW_BOTTOM, 2)
    view.set_left_margin(10)
    view.set_right_margin(10)

    sw.add(view)
    tool_hbox.pack_start(text_print_button, false, false, 0)
    text_hbox.pack_start(sw, true, true, 0)

    vbox.pack_start(tool_hbox, false, true, 0)
    vbox.pack_start(Gtk::HSeparator.new, false, false, 0)
    vbox.pack_start(text_hbox, true, true, 0)

    @viewbox_object["viewbox.usercode.button.print"] = text_print_button

    return {
      "view" => view,
      "box" => vbox,
      "button.print" => text_print_button,
    }
  end

  def view_box_button(status=true)
    case status
    when true
      if @print
        @viewbox_object["viewbox.usercode.button.print"].set_sensitive(true)
      end
      true
    when false
      @viewbox_object["viewbox.usercode.button.print"].set_sensitive(false)
      false
    else
      nil
    end
  end

  def view_user_tree(status=true)
    case status
    when true
      @ir_tree.set_sensitive(true)
      true
    when false
      @ir_tree.set_sensitive(false)
      false
    else
      nil
    end
  end

  def view_toolbox(status=true)
    view_toolbox_user(status)
    view_toolbox_preview(status)
  end

  def view_toolbox_user(status=true)
    case status
    when true
      @toolbox_object["toolbox.button.next"].set_sensitive(true)
      @toolbox_object["toolbox.button.pext"].set_sensitive(true)
      true
    when false
      @toolbox_object["toolbox.button.next"].set_sensitive(false)
      @toolbox_object["toolbox.button.pext"].set_sensitive(false)
      false
    else
      nil
    end
  end

  def view_toolbox_preview(status=true)
    case status
    when true
      @toolbox_object["toolbox.button.preview_next"].set_sensitive(true)
      @toolbox_object["toolbox.button.preview_pext"].set_sensitive(true)
      true
    when false
      @toolbox_object["toolbox.button.preview_next"].set_sensitive(false)
      @toolbox_object["toolbox.button.preview_pext"].set_sensitive(false)
      false
    else
      nil
    end
  end

  # 算定日表示ビュー
  def santei_box
    tips = Gtk::Tooltips.new
    santei_rawcode = Gtk::Entry.new
    santei_day = Gtk::Entry.new
    santei_no = Gtk::Entry.new
    santei_receno = Gtk::Entry.new
    santei_name = Gtk::Entry.new
    santei_sex = Gtk::Entry.new
    santei_birthday = Gtk::Entry.new
    santei_class = Gtk::Entry.new

    santei_no.set_size_request(76, 24)
    santei_receno.set_size_request(76, 24)
    santei_sex.set_size_request(24, 24)
    santei_day.set_size_request(60, 24)
    santei_name.set_size_request(256, 24)
    santei_birthday.set_size_request(128, 24)
    santei_class.set_size_request(206, 24)

    santei_rawcode.set_editable(false)
    santei_no.set_editable(false)
    santei_receno.set_editable(false)
    santei_sex.set_editable(false)
    santei_day.set_editable(false)
    santei_name.set_editable(false)
    santei_birthday.set_editable(false)
    santei_class.set_editable(false)

    santei_day_hbox = Gtk::HBox.new(false, 0)
    santei_no_hbox = Gtk::HBox.new(false, 0)
    santei_name_hbox = Gtk::HBox.new(false, 0)
    santei_receno_hbox = Gtk::HBox.new(false, 0)
    santei_sex_hbox = Gtk::HBox.new(false, 0)
    santei_birthday_hbox = Gtk::HBox.new(false, 0)
    santei_class_hbox = Gtk::HBox.new(false, 0)

    santei_day_hbox.pack_start(Gtk::Label.new("診療年月"), true, true, 0)
    santei_day_hbox.pack_start(santei_day, true, true, 0)
    santei_no_hbox.pack_start(Gtk::Label.new("患者番号"), true, true, 0)
    santei_no_hbox.pack_start(santei_no, true, true, 0)
    santei_receno_hbox.pack_start(Gtk::Label.new("レセプト番号"), true, true, 0)
    santei_receno_hbox.pack_start(santei_receno, true, true, 0)
    santei_name_hbox.pack_start(Gtk::Label.new("氏名"), true, true, 0)
    santei_name_hbox.pack_start(santei_name, true, true, 0)
    santei_sex_hbox.pack_start(Gtk::Label.new("性別"), true, true, 0)
    santei_sex_hbox.pack_start(santei_sex, true, true, 0)
    santei_birthday_hbox.pack_start(Gtk::Label.new("生年月日"), true, true, 0)
    santei_birthday_hbox.pack_start(santei_birthday, true, true, 0)
    santei_class_hbox.pack_start(Gtk::Label.new("種別"), true, true, 0)
    santei_class_hbox.pack_start(santei_class, true, true, 0)

    santei_hbox1 = Gtk::HBox.new(false, 0)
    santei_hbox1.pack_start(santei_no_hbox, false, true, 0)
    santei_hbox1.pack_start(santei_receno_hbox, false, true, 5)
    santei_hbox1.pack_start(santei_sex_hbox, false, true, 5)
    santei_hbox1.pack_start(santei_class_hbox, false, true, 5)

    santei_hbox2 = Gtk::HBox.new(false, 0)
    santei_hbox2.pack_start(santei_day_hbox, false, true, 0)
    santei_hbox2.pack_start(santei_name_hbox, false, true, 5)
    santei_hbox2.pack_start(santei_birthday_hbox, false, true, 5)

    santei_user_vbox = Gtk::VBox.new(false, 0)
    santei_user_vbox.pack_start(santei_hbox1, false, true, 0)
    santei_user_vbox.pack_start(santei_hbox2, false, true, 0)

    sw1 = Gtk::ScrolledWindow.new
    sw1.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    sw1.add(@santei_tree)

    vbox = Gtk::VBox.new(false, 0)
    vbox.pack_start(santei_user_vbox, false, true, 0)
    vbox.pack_start(sw1, true, true, 0)
    vbox.pack_start(santei_rawcode, false, true, 0)

    return {
      "box" => vbox,
      "raw_code_view" => santei_rawcode,
      "day" => santei_day,
      "no" => santei_no,
      "receno" => santei_receno,
      "name" => santei_name,
      "sex" => santei_sex,
      "birthday" => santei_birthday,
      "class" => santei_class,
      "tips" =>  tips,
    }
  end

  def all_code_widget
    @all_code = {}
    sw   = Gtk::ScrolledWindow.new
    view = Gtk::TextView.new
    search = Gtk::Entry.new
    vbox = Gtk::VBox.new(false, 0)
    sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    sw.add(view)
    vbox.add(sw)
    vbox.pack_start(search, false, false, 3)

    view.editable = false
    self.view_color_create(view.buffer)

    view.set_border_window_size(Gtk::TextView::WINDOW_LEFT, 2)
    view.set_border_window_size(Gtk::TextView::WINDOW_RIGHT, 2)
    view.set_border_window_size(Gtk::TextView::WINDOW_TOP, 2)
    view.set_border_window_size(Gtk::TextView::WINDOW_BOTTOM, 2)
    view.set_left_margin(10)
    view.set_right_margin(10)
    @all_code["view"] = view
    @all_code["box"] = vbox
    @all_code["search"] = search
    @all_code["tags"] = []
    @all_code["tags_pos"] = 0
  end

  def tab_renew(tab_label, tab_btext, text, color="#000000")
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      if RUBY_VERSION.to_s <= "1.8.7"
        ext = File.basename(text.tosjis)
      else
        ext = File.basename(text)
      end
    else
      ext = File.basename(text)
    end

    if /\.(HEN|hen)$/ =~ ext
      color = "#FF9999"
      t_style = %Q{#{tab_btext}<span background="#{color}">[#{ext}]</span>}
    elsif /\.(ISO|iso|IMG|img)$/ =~ ext
      color = "#FF9900"
      t_style = %Q{#{tab_btext}<span background="#{color}">[#{ext}]</span>}
    elsif /\.(UKE|uke)$/ =~ ext
      color = ""
      t_style = %Q{#{tab_btext}[#{ext}]}
    else
      color = "#9999FF"
      t_style = %Q{#{tab_btext}<span background="#{color}">[#{ext}]</span>}
    end
    tab_label.set_markup(t_style)
  end

  def view_color_create(buffer)
    fsearch_color = Gdk::Color.new(65535, 65535, 65535)
    bsearch_color = Gdk::Color.new(100, 3000, 50000)
    buffer_color = Gdk::Color.new(10000, 10000, 10000)
    henrei_df_color = Gdk::Color.new(10000, 40000, 10000)
    henrei_re_color = Gdk::Color.new(20000, 20000, 65000)
    ho_color = Gdk::Color.new(20400, 43605, 4080)
    sy_color = Gdk::Color.new(6120, 31875, 49980)
    buffer.create_tag("ETC_Color", "foreground_gdk" => buffer_color)
    buffer.create_tag("RE_Color", "foreground" => "blue")
    buffer.create_tag("IR_Color", "foreground" => "red")
    buffer.create_tag("GO_Color", "foreground" => "red")
    buffer.create_tag("HO_Color", "foreground_gdk" => ho_color)
    buffer.create_tag("SY_Color", "foreground_gdk" => sy_color)
    buffer.create_tag("HEN_DF_Color", "foreground_gdk" => henrei_df_color)
    buffer.create_tag("HEN_RE_Color", "foreground_gdk" => henrei_re_color)
    buffer.create_tag("SEARCH", {
      "foreground_gdk" => fsearch_color,
      "background_gdk" => bsearch_color,
      "weight" => Pango::FontDescription::WEIGHT_BOLD,
      }
    )
    buffer
  end

  def view_color(view, text)
    view.editable = false
    buffer = self.view_color_create(Gtk::SourceBuffer.new)

    tag_index = {}
    if text.size != 0
      iter = buffer.start_iter
      text_arr = text.split(/\n/)
      text_arr.each_with_index do |line, index|
        if /^RE/ =~ line
          color = "RE_Color"
        elsif /^IR|^GO|^HI|^HG|^HR|^RS/ =~ line
          color = "IR_Color"
        elsif /^(\d+,){3}RE,/ =~ line
          color = "HEN_RE_Color"
        elsif /^(\d+,){3}/ =~ line
          color = "HEN_DF_Color"
        elsif /^HO|^RO|^KO|^RR/ =~ line
          color = "HO_Color"
        elsif /^SY/ =~ line
          color = "SY_Color"
        else
          color = "ETC_Color"
        end
        line += "\n"
        tag_index[index] = color
        buffer.insert(iter, line, color)
      end
    end

    lcc = buffer.char_count
    buffer.delete(buffer.get_iter_at_offset(lcc), buffer.get_iter_at_offset(lcc-1))

    view.set_buffer(buffer)
    tag_index
  end

  # GTK2 TreeView Search status
  def treeview_search(tree, m=true)
    if tree != nil
      case tree
      when *@treeview_search_class
        tree.set_enable_search(m)
        true
      else
        false
      end
    end
  end

  # TreeView Auto ScrollWindow for zero top
  def tree_auto_scroll_top(tree)
    this_class = tree.class 
    true_class = [ReceViewGUI::TreeViewIR, ReceViewGUI::TreeViewSANTEI, ReceViewGUI::TreeViewTEKI]

    true_class.each do |check_class|
      if this_class == check_class
        path_o = Gtk::TreePath.new("0")
        iter = tree.model.get_iter(path_o)
        tree.selection.select_iter(iter)
        tree.selection.selected_each do |store, path, iter2|
          tree.scroll_to_cell(path, nil, true, 0.0, 0.0)
        end
      end
    end
  end

  # TreeView Auto ScrollWindow
  def tree_auto_scroll(tree)
    this_class = tree.class 
    true_class = [ReceViewGUI::TreeViewIR, ReceViewGUI::TreeViewSANTEI, ReceViewGUI::TreeViewTEKI]

    true_class.each do |check_class|
      if this_class == check_class
        tree.selection.selected_each do |store, path, iter|
          tree.scroll_to_cell(path, nil, true, 0.0, 0.0)
        end
      end
    end
  end

  def set_treeview_search_class(c)
    @treeview_search_class = c
  end

  # add Stock
  def init_gtk_stock
    ui_name = @base.find_ui
    Gtk::Stock.add(:"df-gtk-find", ui_name["search"]+"(_R)")
    Gtk::Stock.add(:"df-gtk-exfind", ui_name["search_ex"]+"(_E)")
    Gtk::Stock.add(:"df-gtk-stop", ui_name["stop"]+"(_W)")
    Gtk::Stock.add(:"df-gtk-clear", ui_name["clear"]+"(_C)")
    Gtk::Stock.add(:"df-gtk-close", ui_name["close"]+"(_F)")
    Gtk::Stock.add(:"df-gtk-csv", ui_name["csv"]+"(_O)")

    ui_name = @base.sick_ui
    Gtk::Stock.add(:"sick-gtk-yes", ui_name["yes"]+"(_O)")
    Gtk::Stock.add(:"sick-gtk-uniq-edit", ui_name["uniq-edit"]+"(_E)")
    Gtk::Stock.add(:"sick-gtk-quo-edit", ui_name["quo-edit"]+"(_C)")

    ui_name = @base.update_ui
    Gtk::Stock.add(:"update-gtk-refresh", ui_name["refresh"]+"(_U)")
    Gtk::Stock.add(:"update-gtk-upstart", ui_name["upstart"])

    ui_name = @base.print_spool_ui
    Gtk::Stock.add(:"ps-gtk-print", ui_name["print"]+"(_P)")
    Gtk::Stock.add(:"ps-gtk-pdf", ui_name["pdf"]+"(_P)")
    Gtk::Stock.add(:"ps-gtk-subscribe-select", ui_name["select_sub"]+"(_S)")
    Gtk::Stock.add(:"ps-gtk-all-select", ui_name["select_all"]+"(_A)")
    Gtk::Stock.add(:"ps-gtk-cancel", ui_name["cancel"]+"(_D)")
    Gtk::Stock.add(:"ps-gtk-close", ui_name["close"]+"(_N)")

    ui_name = @base.toolbox_ui
    Gtk::Stock.add(:"toolbox-gtk-next", ui_name["next"]+"(_F_1_2)")
    Gtk::Stock.add(:"toolbox-gtk-pext", ui_name["pext"]+"(_F_1_1)")
    Gtk::Stock.add(:"toolbox-gtk-preview-next", ui_name["preview_next"]+"(_F_1_0)")
    Gtk::Stock.add(:"toolbox-gtk-preview-pext", ui_name["preview_pext"]+" (_F_9)")
  end

  def dnd_lock?
    @dnd_lock
  end

  def get_dnd_lock
    @dnd_lock
  end

  def set_dnd_lock(flg)
    @dnd_lock = flg
  end

  def drag_setting(arr_obj)
    arr_obj.each do |wig|
      Gtk::Drag.dest_set(wig, Gtk::Drag::DEST_DEFAULT_ALL,
        [["text/uri-list", 4, 100]],
        Gdk::DragContext::ACTION_COPY|Gdk::DragContext::ACTION_MOVE)
    end
  end

  def clip_copy(widget) 
    if widget.class == Gtk::Entry
      widget.select_region(0, widget.text.size)
      widget.copy_clipboard
      widget.select_region(0, 0)
    end
  end

  def userview_column_autosize
    @byomei_tree.columns_autosize
    @tekiyo_tree.columns_autosize
    @santei_tree.columns_autosize
    @recal_tree.columns_autosize
  end

  # GTK2 Themes Application
  def gtk2_themes_rules(tree)
    tree.set_rules_hint(true)
  end

  def self.Platform_Thread
    pf_thread = false
    if /mingw/ =~ RUBY_PLATFORM.downcase
      version = (Gtk::MAJOR_VERSION * 1000000) + \
        (Gtk::MINOR_VERSION * 1000) + Gtk::MICRO_VERSION
      Gtk::GTK_SUPPORT_VERSION.each do |sversion|
        if sversion == version
          pf_thread = true
          break
        end
      end
    else
      pf_thread = true
    end
    return pf_thread
  end

  def ReceViewGUI::TransWindow(dialog, trans)
    if trans.class == Array
      trans.each do |trans_obj|
        ReceViewGUI::SettingTransWindow(dialog, trans_obj)
      end
    else
      ReceViewGUI::SettingTransWindow(dialog, trans)
    end
  end

  def ReceViewGUI::SettingTransWindow(dialog, trans)
    case trans
    when Gtk::Window, Gtk::Dialog, Gtk::FileSelection, ReceViewGUI::FS, ReceViewSearch
      #if trans.visible?
        dialog.set_transient_for(trans)
      #end
    end
  end

  def ReceViewGUI::SettingDialogHide(dialog)
    case dialog
    when Gtk::Window, Gtk::Dialog, Gtk::FileSelection, ReceViewGUI::FS
      if dialog.visible?
        dialog.hide
        true
      else
        false
      end
    end
  end

  def ReceViewGUI::SettingIcon(dialog)
    ReceView_Base.new.icon.each do |icon_file|
      if File.exist?(icon_file)
        dialog.set_icon(Gdk::Pixbuf.new(icon_file))
        break
      end
    end
  end

  # ツリーの列を右寄せにする(ojb, 列番, 右(1))
  def ReceViewGUI::SetColumnAjust(ojb, set1, set2)
    ojb.set_column_justification(set1, set2)
  end

  # 表示時にスクロールバーを初期値
  def ReceViewGUI::ScrollInit(sl)
    sl.set_hadjustment(Gtk::Adjustment.new(0,0,0,0,0,0))
    sl.set_vadjustment(Gtk::Adjustment.new(0,0,0,0,0,0))
  end

  # not settings Default size (Bugs)
  def ReceViewGUI::Scroll_H_Init(sl, sint=0)
    sl.set_hadjustment(Gtk::Adjustment.new(sint,sint,sint,sint,0,0))
  end

  # not settings Default size (Bugs)
  def ReceViewGUI::Scroll_V_Init(sl, sint=0)
    sl.set_vadjustment(Gtk::Adjustment.new(sint,sint,sint,sint,0,0))
  end
end

class ReceViewGUI::FS < Gtk::FileSelection
  VERSION_GTK = 1
  VERSION_NATIVE = 2
  VERSION_CALL_RUBY = 3

  WINDOW_DEFALUT_POSITION_X = 0
  WINDOW_DEFALUT_POSITION_Y = 0
  WINDOW_DEFALUT_SIZE_X = 1024
  WINDOW_DEFALUT_SIZE_Y = 768
  WINDOW_MAX_MINAS_POSITION_X = -2048
  WINDOW_MAX_MINAS_POSITION_Y = -2048
  WINDOW_MAX_MINAS_SIZE_X = -10000
  WINDOW_MAX_MINAS_SIXE_Y = -10000

  def initialize(title, reverse=true)
    super(title)
    require 'jma/receview/base'
    @dialog_version = 1
    @base = ReceView_Base.new

    # warning: GRClosure invoking callback: already destroyed for Debian Etch
    @dirlist  = self.dir_list
    @filelist = self.file_list

    # thread_DoC
    @thread_dirlist = ThreadDummy.new
    @thread_filelist = ThreadDummy.new

    # The FDD is not displayed at Windows.
    @model_dirlist = Gtk::ListStore.new(String)
    @dirlist.set_model(@model_dirlist)

    # The Re-drawing of file list
    @model_filelist = Gtk::ListStore.new(String)
    @filelist.set_model(@model_filelist)

    self.hide_fileop_buttons

    @gtk_home_button = self.default_home_button
    @gtk_desk_button = self.default_desk_button
    @gtk_doc_button  = self.default_doc_button
    @gtk_file_entry = self.default_fileentry

    @fd_button = add_fd_button
    @cd_button = add_cd_button

    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      box = Gtk::VBox.new(false, 0)
      @home_button = add_home_button
      @desk_button = add_desktop_button
      box.pack_start(@home_button, false, false, 3)
      box.pack_start(@desk_button, false, false, 3)
      self.vbox.children[3].pack_start(box, false, false, 3)

      # obj_fdlist = self.vbox.children[3].children[0]
      obj_holist = self.vbox.children[3].children[1]
      self.vbox.children[3].reorder_child(obj_holist, 0)
    else
      self.vbox.children[1].children[0].pack_start(@fd_button, false, false, 3)
      self.vbox.children[1].children[0].pack_start(@cd_button, false, false, 3)
    end

    self.event
    reverse ? set_reorder_style_gtk1 : set_reorder_style_gtk2
    self.ok_button.grab_focus
    self.complete("RECEIPTC.UKE")
    ReceViewGUI::SettingIcon(self)
    return self
  end

  def event
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      desktop = @base.desktop_native + @base.path_char
      @desk_button.signal_connect("clicked") do
        self.set_filename(desktop)
        self.dir_list.signal_emit("cursor-changed")
      end

      home = @base.home_native + @base.path_char
      @home_button.signal_connect("clicked") do
        self.set_filename(home)
        self.dir_list.signal_emit("cursor-changed")
      end
    else
      if Gtk::platform_support_os_linux(Gtk::GTK_SUPPORT_VERSION_AMD64)
        desktop = @base.desktop_native + @base.path_char
        @gtk_desk_button.signal_connect("clicked") do
          self.set_filename(desktop)
          self.dir_list.signal_emit("cursor-changed")
        end

        doc = @base.doc_native + @base.path_char
        @gtk_doc_button.signal_connect("clicked") do
          self.set_filename(doc)
          self.dir_list.signal_emit("cursor-changed")
        end
      end
    end
  end

  def thread_check
    if @thread_filelist.status != false || @thread_dirlist.status != false
      return false
    else
      return true
    end
  end

  # default Home Button
  def default_home_button
    return self.vbox.children[1].children[0].children[0]
  end

  # default Desktop Button
  def default_desk_button
    return self.vbox.children[1].children[0].children[1]
  end

  # default Document Button
  def default_doc_button
    return self.vbox.children[1].children[0].children[2]
  end

  # default Document Button
  def default_fileentry
    return self.vbox.children[3].children[1]
  end

  # Floppy Button
  def add_fd_button
    fd_button = Gtk::Button.new
    vx = Gtk::VBox.new(false, 0)
    vimage = Gtk::Image.new(Gtk::Stock::FLOPPY, Gtk::IconSize::DIALOG)
    vlabel = Gtk::Label.new("Floppy")
    vx.pack_start(vimage, false, false, 0)
    vx.pack_start(vlabel, false, false, 0)
    fd_button.add(vx)
    x,y = default_home_button.size_request
    fd_button.set_size_request(x, y)
    return fd_button
  end

  # CD-ROM Button
  def add_cd_button
    cd_button = Gtk::Button.new
    vx_cd = Gtk::VBox.new(false, 0)
    vimage_cd = Gtk::Image.new(Gtk::Stock::CDROM, Gtk::IconSize::DIALOG)
    vlabel_cd = Gtk::Label.new("CD-ROM")
    vx_cd.pack_start(vimage_cd, false, false, 0)
    vx_cd.pack_start(vlabel_cd, false, false, 0)
    cd_button.add(vx_cd)
    x,y = default_home_button.size_request
    cd_button.set_size_request(x, y)
    return cd_button
  end

  # HOME Button
  def add_home_button
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      vx = Gtk::VBox.new(false, 0)
      home_button = Gtk::Button.new
      image_path = @base.image_path("directory")
      if !image_path.empty?
        vimage = Gtk::Image.new(image_path)
      else
        vimage = Gtk::Image.new(Gtk::Stock::HOME, Gtk::IconSize::DIALOG)
      end
      vlabel = Gtk::Label.new("Home")
      vx.pack_start(vimage, false, false, 3)
      vx.pack_start(vlabel, false, false, 3)
      home_button.add(vx)
    end
    return home_button
  end

  # Desktop Button
  def add_desktop_button
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      desk_button = Gtk::Button.new
      vx = Gtk::VBox.new(false, 0)
      image_path = @base.image_path("desktop")
      if !image_path.empty?
        vimage2 = Gtk::Image.new(image_path)
      else
        vimage2 = Gtk::Image.new(Gtk::Stock::NEW, Gtk::IconSize::DIALOG)
      end
      vlabel2 = Gtk::Label.new("Desktop")
      vx.pack_start(vimage2, false, false, 3)
      vx.pack_start(vlabel2, false, false, 3)
      desk_button.add(vx)
    end
    return desk_button
  end

  def show_native(window)
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase && @dialog_version >= VERSION_NATIVE
      window.hide
      fs = ReceViewGUI::Win32FS.new
      title = "レセプト電算ファイル選択"
      file_type = "レセプト電算ファイル(*.UKE *.HEN)\0*.UKE;*.HEN\0"
      file_type += "レセプト電算ISOイメージ(*.ISO)\0*.ISO\0"
      file_type += "すべてのレセプト電算ファイル(*.UKE *.HEN *.ISO)\0*.UKE;*.HEN;*.ISO\0"
      file_type += "すべてのファイル(*.*)\0*.*\0"
      file_type += "\0"
      fname = self.filename
      filename = fs.open(title.tosjis, file_type.tosjis, fname.tosjis, nil)
      window.show

      if not filename.to_s.empty?
        self.set_filename(filename.toutf8)
        ok_button.signal_emit("clicked")
      else
        cancel_button.signal_emit("clicked")
      end
    else
      self.show
    end
  end

  def show_native_call_ruby(window)
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase && @dialog_version >= VERSION_CALL_RUBY
      window.set_sensitive(false)
      filename = nil
      fname = self.filename.tosjis
      whid = ReceViewWin32::Command.new.get_active_window

      Thread.new do
        ruby = @base.rb_path
        if File.exist?(@base.rb_config['sitelibdir'] +"/jma/receview/win32fs.rb")
          code = File.join(@base.rb_config['sitelibdir'] +"/jma/receview/win32fs.rb")
        else
          code = File.join("jma/receview/win32fs.rb")
        end
        rb_call = "#{ruby} -I. '#{code}' '#{fname}' '' '#{whid}'"

        filename = systemu(rb_call)[1].toutf8
      end

      glib_call_id = GLib::Timeout.add(100) do
        if not filename.nil?
          window.set_sensitive(true)
          if not filename.to_s.empty?
            self.set_filename(filename)
            ok_button.signal_emit("clicked")
          else
            cancel_button.signal_emit("clicked")
          end
          Gtk::timeout_remove(glib_call_id)
          false
        else
          true
        end
      end
    else
      self.show_all
      window_px, window_py = self.position
      if window_px < WINDOW_DEFALUT_POSITION_X || window_py < WINDOW_DEFALUT_POSITION_Y
        self.set_window_position(Gtk::Window::Position::CENTER)
      end
    end
  end

  # GTK1 old style OK,CancelButton
  def set_over_label_gtk1
    self.ok_button.set_label(Gtk::Stock::CANCEL)
    self.cancel_button.set_label(Gtk::Stock::OK)
  end

  # GTK2 default style Cancel,OKButton
  def set_over_label_gtk2
    self.ok_button.set_label(Gtk::Stock::OK)
    self.cancel_button.set_label(Gtk::Stock::CANCEL)
  end

  # GTK1 default style OK,CancelButton
  def set_reorder_style_gtk1
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      self.cancel_button.reparent(self.vbox.children[-1])
    else
      self.vbox.children[-1].reorder_child(self.cancel_button, Gtk::PACK_END)
    end
  end

  # GTK2 default style Cancel,OKButton
  def set_reorder_style_gtk2
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      self.ok_button.reparent(self.vbox.children[-1])
    else
      self.vbox.children[-1].reorder_child(self.ok_button, Gtk::PACK_END)
    end
  end

  def lib_require(library="jma/receview/receview")
    require library
  end

  def lib_require_systemu
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      if @dialog_version >= 3
        lib_require("systemu")
      end
    end
  end

  def set_dialog_version(version=2)
    if /^\d+$/ =~ version.to_s
      @dialog_version = version
      self.lib_require_systemu
    else
      @dialog_version = 1
    end
  end

  def get_dialog_version
    return @dialog_version
  end

  def dialog_version
    return @dialog_version
  end

  def gtk_home_button
    return @gtk_home_button
  end

  def gtk_desk_button
    return @gtk_desk_button
  end

  def gtk_doc_button
    return @gtk_doc_button
  end

  def file_entry
    return @gtk_file_entry
  end

  def fd_button
    return @fd_button
  end

  def cd_button
    return @cd_button
  end

  def filelist
    return @filelist
  end

  def dirlist
    return @dirlist
  end

  def model_dirlist
    return @model_dirlist
  end

  def model_filelist
    return @model_filelist
  end

  attr_accessor :thread_dirlist
  attr_accessor :thread_filelist
end

class ReceViewGUI::Win32FS
  def initialize
    @cmd = ReceViewWin32::Command.new
  end

  def open(title, file_type, bname, type, whid=nil)
    @cmd.get_openfile(title, file_type, bname, type, whid)
  end
end

class ReceViewGUI::PopUP
  attr_reader :popmenu
  attr_reader :popmenu_sick
  attr_reader :popmenu_search
  attr_reader :popmenu_preview

  def initialize
    require 'jma/receview/base'
    @base = ReceView_Base.new
  end

  def menu_kanja_get
    popup_list = {
      "ckb_na" => @popup_ckb_na,
      "ckb_ok" => @popup_ckb_ok,
      "ckb" => @popup_ckb,
      "ckb_all" => @popup_ckb_all,
      "find" => @popup_find,
      "recal" => @popup_recal,
      "sort_name" => @popup_sort_name,
      "sort_rece_no" => @popup_sort_rece_no,
      "sort_image_stat" => @popup_sort_image_stat,
      "edit" => @popup_edit,
      "edit_sp" => @popup_edit_sp,
    }
    return popup_list
  end

  def menu_sick_get
    popup_list = {
      "edit" => @popup_sick_edit,
      "edit_sp" => @popup_sick_edit_sp,
      "exit" => @popup_sick_exit,
    }
    return popup_list
  end

  def menu_search_get
    popup_list = {
      "printspool_print" => @popup_search_print,
      "printspool_print_all" => @popup_search_print_all,
      "printspool_pdf" => @popup_search_pdf,
      "printspool_pdf_all" => @popup_search_pdf_all,
      "search_sp" => @popup_search_sp,
      "exit" => @popup_search_exit,
    }
    return popup_list
  end

  def menu_preview_get
    popup_list = {
      "preview_next_page" => @popup_preview_next_page,
      "preview_prev_page" => @popup_preview_prev_page,
      "preview_fit_scale" => @popup_preview_fit_scale,
      "preview_nml_scale" => @popup_preview_nml_scale,
      "preview_050_scale" => @popup_preview_050_scale,
      "preview_075_scale" => @popup_preview_075_scale,
      "preview_100_scale" => @popup_preview_100_scale,
      "preview_120_scale" => @popup_preview_120_scale,
      "preview_150_scale" => @popup_preview_150_scale,
      "preview_170_scale" => @popup_preview_170_scale,
      "preview_230_scale" => @popup_preview_230_scale,
      "preview_300_scale" => @popup_preview_300_scale,
      "preview_print" => @popup_preview_print,
      "preview_output" => @popup_preview_output,
      "preview_sp1" => @popup_preview_sp1,
      "preview_sp2" => @popup_preview_sp2,
      "preview_sp3" => @popup_preview_sp3,
      "exit" => @popup_preview_exit,
    }
    return popup_list
  end

  def menu_kanja_make
    @popmenu = Gtk::Menu.new
    l_n = @base.popup_name
   
    @popup_ckb_na = Gtk::ImageMenuItem.new(l_n["ckb_na"])
    @popup_ckb_na.set_image(Gtk::Image.new(Gtk::Stock::STOP, Gtk::IconSize::MENU))
    
    @popup_ckb_ok = Gtk::ImageMenuItem.new(l_n["ckb_ok"])
    @popup_ckb_ok.set_image(Gtk::Image.new(Gtk::Stock::OK, Gtk::IconSize::MENU))

    @popup_ckb = Gtk::MenuItem.new(l_n["ckb"])
    @popup_ckb_all = Gtk::MenuItem.new(l_n["ckb_all"])

    @popup_find = Gtk::ImageMenuItem.new(l_n["find"])
    @popup_find.set_image(Gtk::Image.new(Gtk::Stock::FIND, Gtk::IconSize::MENU))

    @popup_recal = Gtk::ImageMenuItem.new(l_n["recal"])
    @popup_recal.set_image(Gtk::Image.new(
      Gtk::Stock::INDEX, Gtk::IconSize::MENU))

    @popup_sort_name = Gtk::ImageMenuItem.new(l_n["sort_name"])
    @popup_sort_name.set_image(Gtk::Image.new(Gtk::Stock::SORT_ASCENDING, Gtk::IconSize::MENU))

    @popup_sort_rece_no = Gtk::ImageMenuItem.new(l_n["sort_rece_no"])
    @popup_sort_rece_no.set_image(Gtk::Image.new(
      Gtk::Stock::SORT_DESCENDING, Gtk::IconSize::MENU))

    @popup_sort_image_stat = Gtk::ImageMenuItem.new(l_n["sort_image_stat"])
    @popup_sort_image_stat.set_image(Gtk::Image.new(
      Gtk::Stock::SORT_DESCENDING, Gtk::IconSize::MENU))

    @popup_edit = Gtk::ImageMenuItem.new(l_n["edit"])
    @popup_edit.set_image(Gtk::Image.new(Gtk::Stock::DND,Gtk::IconSize::MENU))

    @popup_edit_sp = Gtk::SeparatorMenuItem.new
    @popup_exit = Gtk::MenuItem.new(l_n["exit"])

    # dialog表示
    # popmenu.set_tearoff_title("メニュー")
    # popmenu.set_tearoff_state(true)

    @popmenu.append(@popup_ckb_na)
    @popmenu.append(@popup_ckb_ok)
    @popmenu.append(@popup_ckb)
    @popmenu.append(Gtk::SeparatorMenuItem.new)
    @popmenu.append(@popup_ckb_all)
    @popmenu.append(Gtk::SeparatorMenuItem.new)
    @popmenu.append(@popup_find)
    @popmenu.append(@popup_recal)
    @popmenu.append(Gtk::SeparatorMenuItem.new)
    @popmenu.append(@popup_sort_name)
    @popmenu.append(@popup_sort_rece_no)
    @popmenu.append(@popup_sort_image_stat)
    @popmenu.append(Gtk::SeparatorMenuItem.new)
    @popmenu.append(@popup_edit)
    @popmenu.append(@popup_edit_sp)
    @popmenu.append(@popup_exit)

    return @popmenu
  end

  def menu_sick_make
    @popmenu_sick = Gtk::Menu.new
    s_n = @base.popup_sick_name

    @popup_sick_edit = Gtk::ImageMenuItem.new(s_n["sick_edit"])
    @popup_sick_edit.set_image(Gtk::Image.new(
      Gtk::Stock::DND_MULTIPLE, Gtk::IconSize::MENU))

    @popup_sick_edit_sp = Gtk::SeparatorMenuItem.new
    @popup_sick_exit = Gtk::MenuItem.new(s_n["exit"])

    @popmenu_sick.append(@popup_sick_edit)
    @popmenu_sick.append(@popup_sick_edit_sp)
    @popmenu_sick.append(@popup_sick_exit)

    return @popmenu_sick
  end

  def menu_search_make
    @popmenu_search = Gtk::Menu.new
    s_n = @base.popup_search_name

    @popup_search_print = Gtk::ImageMenuItem.new(s_n["add_print_spool"])
    @popup_search_print.set_image(Gtk::Image.new(Gtk::Stock::PRINT, Gtk::IconSize::MENU))
    @popup_search_print_all = Gtk::ImageMenuItem.new(s_n["all_add_print_spool"])
    @popup_search_print_all.set_image(Gtk::Image.new(Gtk::Stock::PRINT, Gtk::IconSize::MENU))

    @popup_search_pdf = Gtk::ImageMenuItem.new(s_n["add_pdf_spool"])
    @popup_search_pdf.set_image(Gtk::Image.new(Gtk::Stock::PRINT, Gtk::IconSize::MENU))
    @popup_search_pdf_all = Gtk::ImageMenuItem.new(s_n["all_add_pdf_spool"])
    @popup_search_pdf_all.set_image(Gtk::Image.new(Gtk::Stock::PRINT, Gtk::IconSize::MENU))

    @popup_search_sp = Gtk::SeparatorMenuItem.new
    @popup_search_exit = Gtk::MenuItem.new(s_n["exit"])

    @popmenu_search.append(@popup_search_print)
    @popmenu_search.append(@popup_search_print_all)
    @popmenu_search.append(@popup_search_pdf)
    @popmenu_search.append(@popup_search_pdf_all)
    @popmenu_search.append(@popup_search_sp)
    @popmenu_search.append(@popup_search_exit)

    return @popmenu_search
  end

  def menu_preview_make
    @popmenu_preview = Gtk::Menu.new
    s_n = @base.popup_preview_name

    @popup_preview_next_page = Gtk::MenuItem.new(s_n["next_page"])
    @popup_preview_prev_page = Gtk::MenuItem.new(s_n["prev_page"])

    @popup_preview_fit_scale = Gtk::MenuItem.new(s_n["fit_scale"])
    @popup_preview_nml_scale = Gtk::MenuItem.new(s_n["nml_scale"])

    @popup_preview_050_scale = Gtk::MenuItem.new(s_n["050_scale"])
    @popup_preview_075_scale = Gtk::MenuItem.new(s_n["075_scale"])
    @popup_preview_100_scale = Gtk::MenuItem.new(s_n["100_scale"])
    @popup_preview_120_scale = Gtk::MenuItem.new(s_n["120_scale"])
    @popup_preview_150_scale = Gtk::MenuItem.new(s_n["150_scale"])
    @popup_preview_170_scale = Gtk::MenuItem.new(s_n["170_scale"])
    @popup_preview_230_scale = Gtk::MenuItem.new(s_n["230_scale"])
    @popup_preview_300_scale = Gtk::MenuItem.new(s_n["300_scale"])

    @popup_preview_print = Gtk::MenuItem.new(s_n["print"])
    @popup_preview_output = Gtk::MenuItem.new(s_n["output"])

    @popup_preview_sp1 = Gtk::SeparatorMenuItem.new
    @popup_preview_sp2 = Gtk::SeparatorMenuItem.new
    @popup_preview_sp3 = Gtk::SeparatorMenuItem.new
    @popup_preview_sp4 = Gtk::SeparatorMenuItem.new
    @popup_preview_exit = Gtk::MenuItem.new(s_n["exit"])

    @popmenu_preview.append(@popup_preview_next_page)
    @popmenu_preview.append(@popup_preview_prev_page)
    @popmenu_preview.append(@popup_preview_sp1)
    @popmenu_preview.append(@popup_preview_fit_scale)
    @popmenu_preview.append(@popup_preview_nml_scale)
    @popmenu_preview.append(@popup_preview_sp2)
    @popmenu_preview.append(@popup_preview_050_scale)
    @popmenu_preview.append(@popup_preview_075_scale)
    @popmenu_preview.append(@popup_preview_100_scale)
    @popmenu_preview.append(@popup_preview_120_scale)
    @popmenu_preview.append(@popup_preview_150_scale)
    @popmenu_preview.append(@popup_preview_170_scale)
    @popmenu_preview.append(@popup_preview_230_scale)
    @popmenu_preview.append(@popup_preview_300_scale)
    @popmenu_preview.append(@popup_preview_sp3)
    @popmenu_preview.append(@popup_preview_print)
    @popmenu_preview.append(@popup_preview_output)
    @popmenu_preview.append(@popup_preview_sp4)
    @popmenu_preview.append(@popup_preview_exit)

    return @popmenu_preview
  end
end

# TreeView 患者情報
class ReceViewGUI::TreeViewIR < Gtk::TreeView
  attr_accessor :tree
  attr_accessor :text_render
  attr_accessor :image_render
  attr_accessor :sort_column_image
  attr_accessor :sort_column_rece_no
  attr_accessor :sort_column_name
  def initialize(model)
    super
    @base = ReceView_Base.new
    @sort_column_image = nil
    @sort_column_rece_no = nil
    @sort_column_name = nil
    @text_render = Gtk::CellRendererText.new
    @image_render = Gtk::CellRendererPixbuf.new
    @model = model
    #p tree.text_render.fixed_size
  end

  def create_view_column(list)
    list.each_with_index do |item, int|
      if int == 0
        column = Gtk::TreeViewColumn.new(item, @image_render,
          { :pixbuf => 0,
          }
        )
      elsif int == 4
        column = Gtk::TreeViewColumn.new(item, @text_render,
          { :text => int,
            :background_gdk => 14,
          }
        )
      else
        column = Gtk::TreeViewColumn.new(item, @text_render,
          { :text => int,
            :background_gdk => 8,
          }
        )
      end

      case int.to_i
      when 0
        column.set_sort_column_id(12)
        @sort_column_image = column
      when 1
        column.set_sort_column_id(9)
        @sort_column_rece_no = column
      when 3
        column.set_sort_column_id(10) 
        @sort_column_name = column
      end
      self.append_column(column)
      if int == (@base.menu_ir.size - 1)
        self.set_cursor(Gtk::TreePath.new(0), column, false)
      end
    end
  end

  # Tree Beginning Position Change
  def expander_column(column)
    self.set_expander_column(column)
  end

  def set_font_style(font_name="Sans 11")
    font = Pango::FontDescription.new(font_name)
    style = Gtk::Style.new.set_font_desc(font)
    self.set_style(style)
  end
end

# TreeView 統計情報
class ReceViewGUI::TreeViewRE < Gtk::TreeView
  def initialize(model)
    super
    @base = ReceView_Base.new
    @model = model
  end

  def create_view_column(list)
    re_render_R = Gtk::CellRendererText.new
    re_render_L = Gtk::CellRendererText.new
    re_render_R.xalign = 1.0
    re_render_L.xalign = 0.0

    list.each_with_index do |item, int|
      if int == 4 or int == 5 or int == 6 or int == 7
        column = Gtk::TreeViewColumn.new(item, re_render_R, 
          { :text => int,
            :background_gdk => 8,
          }
        )
        self.append_column(column)
      else
        column = Gtk::TreeViewColumn.new(item, re_render_L, 
          { :text => int,
            :background_gdk => 8,
          }
        )
        self.append_column(column)
      end
    end
  end

  def add_view_column_rr2re(names)
    re_render_L = Gtk::CellRendererText.new
    re_render_L.xalign = 0.0
    column_no = 2

    column = Gtk::TreeViewColumn.new(names[column_no], re_render_L, 
      { :text => column_no,
        :background_gdk => 8,
      }
    )
    self.insert_column(column, column_no)
  end

  def rename_view_column_titles(columns, new_titles)
    columns.each_with_index do |name, tindex|
      name.set_title(new_titles[tindex].to_s)
    end
  end

  # Tree Beginning Position Change
  def expander_column(column)
    self.set_expander_column(column)
  end

  def set_font_style(font_name="Sans 11")
    font = Pango::FontDescription.new(font_name)
    style = Gtk::Style.new.set_font_desc(font)
    self.set_style(style)
  end
end

# TreeView 病名
class ReceViewGUI::TreeViewSICK < Gtk::TreeView
  def initialize(model)
    super
    @base = ReceView_Base.new
    @model = model
    @selection_flg = true
  end

  def create_view_column(list)
    list.each_with_index do |item, i|
      column = Gtk::TreeViewColumn.new(item, Gtk::CellRendererText.new,
        {:text => i})
      self.append_column(column)
    end
  end

  def reset_view_column(names)
    self.columns.each do |del_column|
      self.remove_column(del_column)
    end
    self.create_view_column(names)
  end

  def rename_view_column_titles(columns, new_titles)
    columns.each_with_index do |name, tindex|
      name.set_title(new_titles[tindex].to_s)
    end
  end

  def default_column_alignment
    self.get_column(3).set_alignment(1.0)
  end

  def rosai_column_alignment
    #self.get_column(5).set_alignment(1.0)
  end

  # Tree Beginning Position Change
  def expander_column(column)
    self.set_expander_column(column)
  end

  def set_font_style(font_name="Sans 11")
    font = Pango::FontDescription.new(font_name)
    style = Gtk::Style.new.set_font_desc(font)
    self.set_style(style)
  end

  def no_selection
    @selection_flg
  end

  def set_no_selection(flg=true)
    @selection_flg = flg
  end
end

# TreeView 摘要欄
class ReceViewGUI::TreeViewTEKI < Gtk::TreeView
  def initialize(model)
    super
    @base = ReceView_Base.new
    @model = model
  end

  def create_view_column(list)
    tekiou_render_R = Gtk::CellRendererText.new
    tekiou_render_L = Gtk::CellRendererText.new
    tekiou_render_R.xalign = 1.0
    tekiou_render_L.xalign = 0.0

    list.each_with_index do |item, i|
      if i == 3 or i == 4
        column = Gtk::TreeViewColumn.new(item, tekiou_render_R,
          {:text => i})
      else
        column = Gtk::TreeViewColumn.new(item, tekiou_render_L,
          {:text => i})
      end
      self.append_column(column)
    end
  end

  def reset_view_column(names)
    self.columns.each do |del_column|
      self.remove_column(del_column)
    end
    self.create_view_column(names)
  end

  def default_column_alignment
    self.get_column(3).set_alignment(1.0)
    self.get_column(4).set_alignment(1.0)
  end

  # Tree Beginning Position Change
  def expander_column(column)
    self.set_expander_column(column)
  end

  def set_font_style(font_name="Sans 11")
    font = Pango::FontDescription.new(font_name)
    style = Gtk::Style.new.set_font_desc(font)
    self.set_style(style)
  end
end

# TreeView 算定日
class ReceViewGUI::TreeViewSANTEI < Gtk::TreeView
  def initialize(model)
    super
    @base = ReceView_Base.new
    @model = model
  end

  def create_view_column(list)
    santei_render_R = Gtk::CellRendererText.new
    santei_render_L = Gtk::CellRendererText.new
    santei_render_C = Gtk::CellRendererText.new
    santei_render_R.xalign = 1.0
    santei_render_L.xalign = 0.0
    santei_render_C.xalign = 0.5

    list.each_with_index do |item, i|
      if i >= 0 && i < 3
        column = Gtk::TreeViewColumn.new(item, santei_render_L,
          { :text => i,
          })
      elsif i == 4
        column = Gtk::TreeViewColumn.new(item, santei_render_R,
          { :text => i,
          })
      elsif i >= 5 && i < 10
        column = Gtk::TreeViewColumn.new(item, santei_render_C,
          { :text => i,
            :background_gdk => 36,
          })
      elsif i >= 10 && i < 15
        column = Gtk::TreeViewColumn.new(item, santei_render_C,
          { :text => i,
            :background_gdk => 37,
          })
      elsif i >= 15 && i < 20
        column = Gtk::TreeViewColumn.new(item, santei_render_C,
          { :text => i,
            :background_gdk => 36,
          })
      elsif i >= 20 && i < 25
        column = Gtk::TreeViewColumn.new(item, santei_render_C,
          { :text => i,
            :background_gdk => 37,
          })
      elsif i >= 25 && i < 30
        column = Gtk::TreeViewColumn.new(item, santei_render_C,
          { :text => i,
            :background_gdk => 36,
          })
      elsif i >= 30 && i < 35
        column = Gtk::TreeViewColumn.new(item, santei_render_C,
          { :text => i,
            :background_gdk => 37,
          })
      elsif i >= 35 && i < 36
        column = Gtk::TreeViewColumn.new(item, santei_render_C,
          { :text => i,
            :background_gdk => 36,
          })
      else
        column = Gtk::TreeViewColumn.new(item, santei_render_L,
          { :text => i })
      end
      self.append_column(column)
    end
  end

  def reset_view_column(names)
    self.columns.each do |del_column|
      self.remove_column(del_column)
    end
    self.create_view_column(names)
  end

  def default_column_alignment
    self.get_column(3).set_alignment(1.0)
    self.get_column(4).set_alignment(1.0)
  end

  # Tree Beginning Position Change
  def expander_column(column)
    self.set_expander_column(column)
  end

  def set_font_style(font_name="Sans 11")
    font = Pango::FontDescription.new(font_name)
    style = Gtk::Style.new.set_font_desc(font)
    self.set_style(style)
  end
end

# 印刷スプールダイアログ　
class ReceViewPrintSpoolDialog < Gtk::Dialog
  STOCK_LABEL = 1
  def initialize(model_print, model_pdf, model_old)
    require 'jma/receview/base'
    @base = ReceView_Base.new
    @stop_delete_event = false

    super()
    @model_print   = model_print
    @model_pdf     = model_pdf
    @model_history = model_old

    geometry = Gdk::Geometry.new
    geometry.set_min_width(480)
    geometry.set_min_height(420)
    geometry.set_max_width(1000)
    geometry.set_max_height(800)
    mask = Gdk::Window::HINT_MIN_SIZE | Gdk::Window::HINT_MAX_SIZE

    self.set_title(@base.printspool_message["title"])
    self.set_modal(false)            
    self.set_geometry_hints(nil, geometry, mask)
    self.set_type_hint(Gdk::Window::TYPE_HINT_NORMAL)
    self.set_window_position(Gtk::Window::Position::CENTER)
    ReceViewGUI::SettingIcon(self)

    @vbox1 = Gtk::VBox.new
    @vbox2 = Gtk::VBox.new
    @vbox3 = Gtk::VBox.new
    @treeview_print = Gtk::TreeView.new(@model_print)
    @treeview_pdf = Gtk::TreeView.new(@model_pdf)
    @treeview_history = Gtk::TreeView.new(@model_history)

    @treeview_print.selection.set_mode(Gtk::SELECTION_MULTIPLE)
    @treeview_pdf.selection.set_mode(Gtk::SELECTION_MULTIPLE)

    @tab = Gtk::Notebook.new
    @tab.homogeneous = true
    @tab.append_page(@vbox1, Gtk::Label.new(@base.printspool_tabs["print"]))
    @tab.append_page(@vbox2, Gtk::Label.new(@base.printspool_tabs["pdf"]))
    @tab.append_page(@vbox3, Gtk::Label.new(@base.printspool_tabs["history"]))

    @print_button = Gtk::Button.new(Gtk::Stock::PRINT)

    @subscribe_select_button = Gtk::Button.new(:"ps-gtk-subscribe-select")
    @subscribe_select_button.set_image(Gtk::Image.new(Gtk::Stock::SELECT_ALL, Gtk::IconSize::MENU))

    @all_select_button = Gtk::Button.new(:"ps-gtk-all-select")
    @all_select_button.set_image(Gtk::Image.new(Gtk::Stock::SELECT_ALL, Gtk::IconSize::MENU))

    @cancel_button = Gtk::Button.new(:"ps-gtk-cancel")
    @cancel_button.set_image(Gtk::Image.new(Gtk::Stock::CANCEL, Gtk::IconSize::MENU))

    @exit_button = Gtk::Button.new(:"ps-gtk-close")
    @exit_button.set_image(Gtk::Image.new(Gtk::Stock::CLOSE, Gtk::IconSize::MENU))

    @base.printspool_column.each_with_index do |item, i|
      tree_render = Gtk::CellRendererText.new
      tree_render.xalign = 1.0
      column = Gtk::TreeViewColumn.new(item, tree_render, 
        { :text => i,
        })
      @treeview_print.append_column(column)
    end

    @base.printspool_column.each_with_index do |item, i|
      tree_render = Gtk::CellRendererText.new
      tree_render.xalign = 1.0
      column = Gtk::TreeViewColumn.new(item, tree_render, 
        { :text => i,
        })
      @treeview_pdf.append_column(column)
    end
    
    @base.printspool_column.each_with_index do |item, i|
      tree_render = Gtk::CellRendererText.new
      tree_render.xalign = 1.0
      column = Gtk::TreeViewColumn.new(item, tree_render, 
        { :text => i,
        })
      @treeview_history.append_column(column)
    end

    # 寄せ 1.0=L 2.0=R 0.5=Cnter
    @treeview_print.get_column(0).set_alignment(0.5)
    @treeview_print.get_column(1).set_alignment(0.5)
    @treeview_print.get_column(2).set_alignment(0.5)
    @treeview_print.get_column(3).set_alignment(0.5)
    @treeview_print.get_column(4).set_alignment(0.5)
    @treeview_print.get_column(5).set_alignment(0.5)
    @treeview_pdf.get_column(0).set_alignment(0.5)
    @treeview_pdf.get_column(1).set_alignment(0.5)
    @treeview_pdf.get_column(2).set_alignment(0.5)
    @treeview_pdf.get_column(3).set_alignment(0.5)
    @treeview_pdf.get_column(4).set_alignment(0.5)
    @treeview_pdf.get_column(5).set_alignment(0.5)
    @treeview_history.get_column(0).set_alignment(0.5)
    @treeview_history.get_column(1).set_alignment(0.5)
    @treeview_history.get_column(2).set_alignment(0.5)
    @treeview_history.get_column(3).set_alignment(0.5)
    @treeview_history.get_column(4).set_alignment(0.5)
    @treeview_history.get_column(5).set_alignment(0.5)

    @sw1 = Gtk::ScrolledWindow.new
    @sw1.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    @sw1.add(@treeview_print)

    @sw2 = Gtk::ScrolledWindow.new
    @sw2.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    @sw2.add(@treeview_pdf)

    @sw3 = Gtk::ScrolledWindow.new
    @sw3.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    @sw3.add(@treeview_history)

    @vbox1.pack_start(@sw1, true, true, 0)
    @vbox2.pack_start(@sw2, true, true, 0)
    @vbox3.pack_start(@sw3, true, true, 0)
    @accel = Gtk::AccelGroup.new

    self.action_area.pack_start(@print_button)
    self.action_area.pack_start(@subscribe_select_button)
    self.action_area.pack_start(@all_select_button)
    self.action_area.pack_start(@cancel_button)
    self.action_area.pack_start(@exit_button)
    self.vbox.pack_start(@tab)

    self.accel_setting(@accel)
    self.event
  end

  def accel_setting(accel=nil)
    accel = Gtk::AccelGroup.new if accel.nil?

    accel.connect(Gdk::Keyval::GDK_1, Gdk::Window::MOD1_MASK, Gtk::ACCEL_VISIBLE) do
      @tab.set_page(0)
    end

    accel.connect(Gdk::Keyval::GDK_2, Gdk::Window::MOD1_MASK, Gtk::ACCEL_VISIBLE) do
      @tab.set_page(1)
    end

    accel.connect(Gdk::Keyval::GDK_3, Gdk::Window::MOD1_MASK, Gtk::ACCEL_VISIBLE) do
      @tab.set_page(2)
    end

    accel.connect(Gdk::Keyval::GDK_P, Gdk::Window::CONTROL_MASK, Gtk::ACCEL_VISIBLE) do
      @print_button.signal_emit("clicked")
    end

    accel.connect(Gdk::Keyval::GDK_S, Gdk::Window::CONTROL_MASK, Gtk::ACCEL_VISIBLE) do
      @subscribe_select_button.signal_emit("clicked")
    end

    accel.connect(Gdk::Keyval::GDK_A, Gdk::Window::CONTROL_MASK, Gtk::ACCEL_VISIBLE) do
      @all_select_button.signal_emit("clicked")
    end

    accel.connect(Gdk::Keyval::GDK_D, Gdk::Window::CONTROL_MASK, Gtk::ACCEL_VISIBLE) do
      @cancel_button.signal_emit("clicked")
    end

    accel.connect(Gdk::Keyval::GDK_N, Gdk::Window::CONTROL_MASK, Gtk::ACCEL_VISIBLE) do
      @exit_button.signal_emit("clicked")
    end
    self.add_accel_group(accel)
  end

  def event
    self.signal_connect("delete_event") do
      if @stop_delete_event
        true
      else
        self.hide
      end
    end

    # PrintSpool select all
    @all_select_button.signal_connect("clicked") do
      case @tab.page.to_s
      when "0"
        print_spool_select_all
      when "1"
        print_spool_select_all(@treeview_pdf)
      end
    end

    # PrintSpool select subscribe
    @subscribe_select_button.signal_connect("clicked") do
      case @tab.page.to_s
      when "0"
        print_spool_select_subscribe
      when "1"
        print_spool_select_subscribe(@treeview_pdf)
      end
    end

    # PrintSpool select subscribe delete
    @cancel_button.signal_connect("clicked") do
      case @tab.page.to_s
      when "0"
        print_spool_apmove
      when "1"
        print_spool_apmove(@treeview_pdf)
      end
    end

    @treeview_print.signal_connect("cursor-changed") do
      if self.print_spool_print?
        @print_button.set_sensitive(true)
      else
        @print_button.set_sensitive(false)
      end
    end

    @treeview_pdf.signal_connect("cursor-changed") do
      if self.print_spool_print?(@treeview_pdf)
        @print_button.set_sensitive(true)
      else
        @print_button.set_sensitive(false)
      end
    end

    @treeview_print.signal_connect("select-all") do
      if self.print_spool_print?
        @print_button.set_sensitive(true)
      else
        @print_button.set_sensitive(false)
      end
    end

    @treeview_pdf.signal_connect("select-all") do
      if self.print_spool_print?(@treeview_pdf)
        @print_button.set_sensitive(true)
      else
        @print_button.set_sensitive(false)
      end
    end

    @tab.signal_connect("switch-page") do |nb, nbp, page|
      case page
      when 0, 1
        case page
        when 0
          if self.print_spool_print?
            @print_button.set_sensitive(true)
          else
            @print_button.set_sensitive(false)
          end
        when 1
          if self.print_spool_print?(@treeview_pdf)
            @print_button.set_sensitive(true)
          else
            @print_button.set_sensitive(false)
          end
        end
        @all_select_button.set_sensitive(true)
        @subscribe_select_button.set_sensitive(true)
        @cancel_button.set_sensitive(true)
        button_print_rename(page)
      when 2
        @print_button.set_sensitive(false)
        @all_select_button.set_sensitive(false)
        @subscribe_select_button.set_sensitive(false)
        @cancel_button.set_sensitive(false)
      end
    end

    @exit_button.signal_connect("clicked") do
      self.hide
    end
  end

  def trans_window(trans)
    ReceViewGUI::TransWindow(self, trans)
  end

  def button_print_rename(page)
    case page
    when 0
      @print_button.set_label(Gtk::Stock.lookup(Gtk::Stock::PRINT)[STOCK_LABEL])
    when 1
      @print_button.set_label(Gtk::Stock.lookup(:"ps-gtk-pdf")[STOCK_LABEL])
    else
      @print_button.set_label(Gtk::Stock.lookup(Gtk::Stock::PRINT)[STOCK_LABEL])
    end
    @print_button.set_use_underline(true) unless @print_button.use_underline?
  end

  # プリントスプール追加@検索
  def print_spool_searchview(ir_tree, search_tree, tree_id)
    if search_tree.selection.selected != nil
      print_m = @model_print.append(nil)
      print_m[0] = search_tree.selection.selected.get_value(1).to_s
      print_m[1] = search_tree.selection.selected.get_value(0).to_s
      print_m[2] = ""
      print_m[3] = @base.printspool_message["preview"]
      print_m[4] = @base.printspool_message["print_ap"]
      print_m[5] = now_Times
      print_m[6] = search_tree.selection.selected.get_value(5).to_s

      if tree_id[print_m[6].to_i] != nil
        ir_tree.selection.select_iter(tree_id[print_m[6].to_i])
        print_m[7] = ir_tree.selection.selected.get_value(13).to_s
      else
        print_m[7] = ""
      end
    end
  end

  # プリントスプールすべて追加@検索
  def print_spool_searchview_all(ir_tree, search_tree, tree_id)
    search_tree.model.each do |store, path, iter|
      search_tree.selection.select_iter(iter)
      print_m = @model_print.append(nil)
      print_m[0] = search_tree.selection.selected.get_value(1).to_s
      print_m[1] = search_tree.selection.selected.get_value(0).to_s
      print_m[2] = ""
      print_m[3] = @base.printspool_message["preview"]
      print_m[4] = @base.printspool_message["print_ap"]
      print_m[5] = now_Times
      print_m[6] = search_tree.selection.selected.get_value(5).to_s

      if tree_id[print_m[6].to_i] != nil
        ir_tree.selection.select_iter(tree_id[print_m[6].to_i])
        print_m[7] = ir_tree.selection.selected.get_value(13).to_s
      else
        print_m[7] = ""
      end
    end
  end

  # プリントスプール追加PDF@検索
  def print_spool_searchview_pdf(ir_tree, search_tree, tree_id)
    if search_tree.selection.selected != nil
      print_m = @model_pdf.append(nil)
      print_m[0] = search_tree.selection.selected.get_value(1).to_s
      print_m[1] = search_tree.selection.selected.get_value(0).to_s
      print_m[2] = ""
      print_m[3] = @base.printspool_message["preview"]
      print_m[4] = @base.printspool_message["print_ap"]
      print_m[5] = now_Times
      print_m[6] = search_tree.selection.selected.get_value(5).to_s

      if tree_id[print_m[6].to_i] != nil
        ir_tree.selection.select_iter(tree_id[print_m[6].to_i])
        print_m[7] = ir_tree.selection.selected.get_value(13).to_s
      else
        print_m[7] = ""
      end
    end
  end

  # プリントスプールすべて追加PDF@検索
  def print_spool_searchview_pdf_all(ir_tree, search_tree, tree_id)
    search_tree.model.each do |store, path, iter|
      search_tree.selection.select_iter(iter)
      print_m = @model_pdf.append(nil)
      print_m[0] = search_tree.selection.selected.get_value(1).to_s
      print_m[1] = search_tree.selection.selected.get_value(0).to_s
      print_m[2] = ""
      print_m[3] = @base.printspool_message["preview"]
      print_m[4] = @base.printspool_message["print_ap"]
      print_m[5] = now_Times
      print_m[6] = search_tree.selection.selected.get_value(5).to_s

      if tree_id[print_m[6].to_i] != nil
        ir_tree.selection.select_iter(tree_id[print_m[6].to_i])
        print_m[7] = ir_tree.selection.selected.get_value(13).to_s
      else
        print_m[7] = ""
      end
    end
  end

  # プリントスプール追加@プレビュー
  def print_spool_preview(input_tree)
    if input_tree.selection.selected != nil
      print_m = @model_print.append(nil)
      print_m[0] = input_tree.selection.selected.get_value(1).to_s
      print_m[1] = input_tree.selection.selected.get_value(2).to_s
      print_m[2] = date_make(input_tree.selection.selected.get_value(6).to_s)
      print_m[3] = @base.printspool_message["preview"]
      print_m[4] = @base.printspool_message["print_ok"]
      print_m[5] = now_Times
      print_m[6] = ""
      print_m[7] = input_tree.selection.selected.get_value(13).to_s
    end
  end

  # プリントスプール追加@PDFoutput
  def print_spool_outpdf(input_tree)
    if input_tree.selection.selected != nil
      print_m = @model_pdf.append(nil)
      print_m[0] = input_tree.selection.selected.get_value(1).to_s
      print_m[1] = input_tree.selection.selected.get_value(2).to_s
      print_m[2] = date_make(input_tree.selection.selected.get_value(6).to_s)
      print_m[3] = @base.printspool_message["preview"]
      print_m[4] = @base.printspool_message["pdf"]
      print_m[5] = now_Times
      print_m[6] = ""
      print_m[7] = input_tree.selection.selected.get_value(13).to_s
    end
  end

  # プリントスプール追加@レセ電コード
  def print_spool_csv(input_tree)
    if input_tree.selection.selected != nil
      print_m = @model_print.append(nil)
      print_m[0] = input_tree.selection.selected.get_value(1).to_s
      print_m[1] = input_tree.selection.selected.get_value(2).to_s
      print_m[2] = date_make(input_tree.selection.selected.get_value(6).to_s)
      print_m[3] = @base.printspool_message["csv"]
      print_m[4] = @base.printspool_message["print_ok"]
      print_m[5] = now_Times
      print_m[6] = ""
      print_m[7] = input_tree.selection.selected.get_value(13).to_s
    end
  end

  # プリントスプール追加@すべてのレセ電コード
  def print_spool_csv_all(input_tree)
    if input_tree.selection.selected != nil
      print_m = @model_print.append(nil)
      print_m[0] = input_tree.selection.selected.get_value(1).to_s
      print_m[1] = input_tree.selection.selected.get_value(2).to_s
      print_m[2] = date_make(input_tree.selection.selected.get_value(6).to_s)
      print_m[3] = @base.printspool_message["csv_all"]
      print_m[4] = @base.printspool_message["output"]
      print_m[5] = now_Times
      print_m[6] = ""
      print_m[7] = input_tree.selection.selected.get_value(13).to_s
    end
  end

  # プリントスプール 印刷,PDF出力可能のチェック
  def print_spool_print?(pspool_tree=@treeview_print)
    if pspool_tree.class == Gtk::TreeView
      status = false
      pspool_tree.selection.selected_rows.each do |path|
        iter = pspool_tree.model.get_iter(path)
        if not pspool_tree.model.get_value(iter, 6).to_s.empty?
          status = true
          break
        else
          status = false
        end
      end
      return status
    else
      return false
    end
  end

  # プリントスプール@ 現在|履歴取得
  def get_print_spool(pspool_model=nil, print_size=0)
    output_arr = []
    if pspool_model.class == Gtk::TreeStore
      if not pspool_model.iter_first.nil?
        pspool_model.each do |model, path, iter|
          arr = []
          print_size.times do |i|
            arr.push(model.get_value(iter, i))
          end
          output_arr.push(arr.join(","))
        end
      end
    end
    return output_arr
  end

  # プリントスプール@現在印刷取得
  def get_print_spool_print(psize)
    self.get_print_spool(@model_print, psize)
  end

  # プリントスプール@現在PDF取得
  def get_print_spool_pdf(psize)
    self.get_print_spool(@model_pdf, psize)
  end

  # プリントスプール@履歴取得
  def get_print_spool_history(psize)
    self.get_print_spool(@model_history, psize)
  end

  # プリントスプール@全て取得
  def get_print_spool_marge(print_psize=1, pdf_psize=1, history_psize=1)
    return [
      self.get_print_spool_print(print_psize),
      self.get_print_spool_pdf(pdf_psize),
      self.get_print_spool_history(history_psize)
    ].flatten
  end


  # プリントスプールから印刷
  def print_spool_to_printer_point(pspool_tree=@treeview_print)
    columns = []
    pspool_tree.selection.selected_rows.each do |path|
      iter = pspool_tree.model.get_iter(path)
      column_data = pspool_tree.model.get_value(iter, 6).to_s
      if not column_data.empty?
        columns.push(column_data.to_i)
      end
    end
    return columns
  end

  # プリントスプールからPDF出力
  def print_spool_to_pdf_point(pspool_tree=@treeview_print)
    columns = []
    pspool_tree.selection.selected_rows.each do |path|
      iter = pspool_tree.model.get_iter(path)
      column_data = pspool_tree.model.get_value(iter, 6).to_s
      if not column_data.empty?
        columns.push(column_data.to_i)
      end
    end
    return columns
  end

  # 選択中予約の削除
  def print_spool_apmove(pspool_tree=@treeview_print)
    if pspool_tree.class == Gtk::TreeView
      pspool_tree.selection.count_selected_rows.times do |a|
        pspool_tree.selection.selected_rows.each do |path|
          iter = pspool_tree.model.get_iter(path)
          column_data = pspool_tree.model.get_value(iter, 6).to_s
          if not column_data.empty?
            pspool_tree.model.remove(iter)
            break
          end
        end
      end
    end
  end

  # 選択中予約の削除@print
  def print_spool_apmove_print
    print_spool_apmove(@treeview_print)
  end

  # 選択中予約の削除@PDF
  def print_spool_apmove_pdf
    print_spool_apmove(@treeview_pdf)
  end

  # プリントスプール 各widgetの非活性化
  def print_spool_to_printer_freeze_widget(pspool_tree=@treeview_print)
    @stop_delete_event = true
    @treeview_print.set_sensitive(false)
    @exit_button.set_sensitive(false)
    @print_button.set_sensitive(false)
    @all_select_button.set_sensitive(false)
    @cancel_button.set_sensitive(false)
    @subscribe_select_button.set_sensitive(false)

    yield

    @treeview_print.set_sensitive(true)
    @exit_button.set_sensitive(true)
    @print_button.set_sensitive(true)
    @all_select_button.set_sensitive(true)
    @subscribe_select_button.set_sensitive(true)
    @cancel_button.set_sensitive(true)
    @stop_delete_event = false
  end

  # プリントスプール すべて選択
  def print_spool_select_all(pspool_tree=@treeview_print)
    if pspool_tree.class == Gtk::TreeView
      pspool_tree.selection.select_all
      pspool_tree.signal_emit("select-all")
    end
  end

  # プリントスプール 印刷予約のみ選択
  def print_spool_select_subscribe(pspool_tree=@treeview_print)
    if pspool_tree.class == Gtk::TreeView
      pspool_tree.selection.select_all
      pspool_tree.selection.selected_rows.each do |path|
        iter = pspool_tree.model.get_iter(path)
        if pspool_tree.model.get_value(iter, 6).to_s.empty?
          pspool_tree.selection.unselect_iter(iter)
        end
      end
      pspool_tree.signal_emit("select-all")
    end
  end

  def treeview
    @treeview_print
  end

  def treeview_print
    @treeview_print
  end

  def treeview_pdf
    @treeview_pdf
  end

  def treeview_history
    @treeview_history
  end

  def model
    @model_print
  end

  def model_print
    @model_print
  end

  def model_pdf
    @model_pdf
  end

  def model_history
    @model_history
  end

  attr_accessor :tab
  attr_accessor :exit_button
  attr_accessor :print_button
  attr_accessor :subscribe_select_button
  attr_accessor :all_select_button
  attr_accessor :cancel_button
  attr_accessor :stop_delete_event
end

# 検索ダイアログ
class ReceViewSearch < Gtk::Dialog
  def initialize
    require 'jma/receview/base'
    @gui = ReceViewGUI.new
    @rd = ReceView_Dialog.new
    @base = ReceView_Base.new
    @path_char = @base.path_char
    keyword_colm = @base.find_keyword_colm
    keyword_radio_name = @base.find_keyword_radio_name
    keyword_radio_val = @base.find_keyword_radio_val

    @gui.init_gtk_stock
    super

    default_title
    self.set_modal(false)
    ReceViewGUI::SettingIcon(self)

    @csv_filename = "search.csv"
    @entry_find = Gtk::Entry.new

    # 検索候補
    @completion = Gtk::EntryCompletion.new
    @complete_model = Gtk::ListStore.new(String)
    @completion.model = @complete_model
    @completion.text_column = 0
    @entry_find.completion = @completion

    @option_model = Gtk::ListStore.new(String)
    @option_box = Gtk::ComboBox.new(@option_model)
    @renderer = Gtk::CellRendererText.new
    @option_box.pack_start(@renderer, true)
    @option_box.set_attributes(@renderer, :text => 0)

    @frame_radio = Gtk::Frame.new("検索項目")
    @radio_box = Gtk::VBox::new
    @radio_button = {}

    keyword_radio_name.each_with_index do |name, index|
      val = keyword_radio_val[index]
      if @radio_button['name'].nil?
        @radio_button[val] = Gtk::RadioButton::new(name)
      else
        @radio_button[val] = Gtk::RadioButton::new(@radio_button['name'], name)
      end
      @radio_box.pack_start(@radio_button[val], false, false, 0)
    end

    @option_box.active = 0
    @option_box.hide

    @hbox1 = Gtk::HBox.new
    @hbox2 = Gtk::HBox.new
    @vbox1 = Gtk::VBox.new
    @vbox  = Gtk::VBox.new

    @hbox1.pack_start(@entry_find, true, true, 5)

    @model = @gui.tree_model_search_init
    @treeview = Gtk::TreeView.new(@model)
    @search_render_R = Gtk::CellRendererText.new
    @search_render_L = Gtk::CellRendererText.new
    @search_render_R.xalign = 1.0
    @search_render_L.xalign = 0.0

    keyword_colm.each_with_index do |item, i|
      column = ""
      if i == 2 or i == 3
        column = Gtk::TreeViewColumn.new(item, @search_render_R,
          { :text => i,
            :background_gdk => 4
          })
      else
        column = Gtk::TreeViewColumn.new(item, @search_render_L,
          { :text => i,
            :background_gdk => 4
          })
      end
      case i
      when 0
        column.set_sort_column_id(6)
      when 1
        column.set_sort_column_id(7)
      when 2
        column.set_sort_column_id(2)
      end
      @treeview.append_column(column)
    end

    # 寄せ 1.0=L 2.0=R 0.5=Cnter
    @treeview.get_column(0).set_alignment(0.5)
    @treeview.get_column(1).set_alignment(0.5)
    @treeview.get_column(2).set_alignment(0.5)
    @treeview.get_column(3).set_alignment(0.5)

    @sw1 = Gtk::ScrolledWindow.new
    @sw1.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    @sw1.add(@treeview)

    @frame_radio.add(@radio_box)
    @vbox1.pack_start(@frame_radio, true, true, 0)
    @vbox1.pack_start(@option_box, false, true, 0)

    @hbox2.pack_start(@vbox1, false, false, 0)
    @hbox2.pack_start(@sw1, true, true, 5)

    @ok_button     = Gtk::Button.new(:"df-gtk-find")
    @ex_button     = Gtk::Button.new(:"df-gtk-exfind")
    @clear_button  = Gtk::Button.new(:"df-gtk-clear")
    @stop_button   = Gtk::Button.new(:"df-gtk-stop")
    @csv_button    = Gtk::Button.new(:"df-gtk-csv")
    @cancel_button = Gtk::Button.new(:"df-gtk-close")

    @ok_button.set_image(Gtk::Image.new(Gtk::Stock::FIND,
                                     Gtk::IconSize::MENU))
    @ex_button.set_image(Gtk::Image.new(Gtk::Stock::FIND,
                                     Gtk::IconSize::MENU))
    @clear_button.set_image(Gtk::Image.new(Gtk::Stock::CLEAR,
                                     Gtk::IconSize::MENU))
    @stop_button.set_image(Gtk::Image.new(Gtk::Stock::STOP,
                                     Gtk::IconSize::MENU))
    @csv_button.set_image(Gtk::Image.new(Gtk::Stock::SAVE,
                                     Gtk::IconSize::MENU))
    @cancel_button.set_image(Gtk::Image.new(Gtk::Stock::CLOSE,
                                     Gtk::IconSize::MENU))

    @accel = Gtk::AccelGroup.new
    key_event(@accel)
    self.add_accel_group(@accel)

    @stop_button.set_sensitive(false)

    @bo = Gtk::HBox.new(false, 5)
    @bo.pack_start(@ok_button)
    @bo.pack_start(@ex_button)
    @bo.pack_start(@stop_button)
    @bo.pack_start(@clear_button)
    @bo.pack_start(@csv_button)
    @bo.pack_start(@cancel_button)

    @vbox.pack_start(@hbox1, false, false, 5)
    @vbox.pack_start(@hbox2, true, true, 5)
    self.action_area.pack_start(@bo)
    self.vbox.pack_start(@vbox)

    # focus -> entry
    @entry_find.grab_focus

    ui_name = @base.find_ui
    @tips = Gtk::Tooltips.new
    @tips.set_tip(@entry_find, ui_name['tips_entry'], "")
    @tips.set_tip(@treeview, ui_name['tips_do_search'], "")
    @tips.set_tip(@option_box, ui_name['tips_option_search'], "")
    @radio_button.each do |val, radio_obj|
      @tips.set_tip(radio_obj, ui_name['tips_radio'], "")
    end

    self.event
  end

  def trans_window(trans)
    ReceViewGUI::TransWindow(self, trans)
  end

  def default_title
    self.set_title("検索")
  end

  def searching_title
    self.set_title("検索中...")
  end

  def search_start(search_text="", radio_val="", option="0")
    start_f = false
    start_f = true if search_text.to_s != ''
    case radio_val
    when 'si', 'check', 'recheck', 'nocheck', 'kouhi', 'sy_ka', 'tokki', 'hokenja', 'nyugai_kbn', 'comment'
      start_f = true
    when 'sick'
      case option.to_s
      when '1', '2', '3', '4'
        start_f = true 
      end
    end
    start_f
  end

  def search_active_radio(radio_button=@radio_button)
    val = ""
    radio_button.each do |r_val, r_w|
      if r_w.active?
        val = r_val
        break
      end
    end
    return val
  end

  def search_entry_mode(entry=nil, radio_val=nil, o_combo=nil)
    if entry != nil and radio_val != nil and o_combo != nil
      case radio_val.to_s
      when 'sick'
        case o_combo.active.to_s
        when "0", "4"
          entry.set_sensitive(true)
        when "1", "2", "3"
          entry.set_sensitive(false)
        end
      when 'sy_ka'
        case o_combo.active.to_s
        when "0"
          entry.set_sensitive(true)
        when "1"
          entry.set_sensitive(false)
        end
      when 'nyugai_kbn'
        entry.set_sensitive(false)
      else
        entry.set_sensitive(true)
      end
    end
  end

  def search_radio_sensitive(status, mode=0)
    one_flg = true
    @radio_button.each do |val, w|
      if mode == 0
        w.set_sensitive(status)
      else
        case val
        when "ten", "kouhi", "sy_ka", "tokki", "hokenja"
          if w.active? and one_flg
            @radio_button['name'].set_active(1)
             one_flg = false
          end
          w.set_sensitive(false)
        else
          w.set_sensitive(status)
        end
      end
    end
  end

  def key_event(accel)
    accel.connect(Gdk::Keyval::GDK_R, Gdk::Window::CONTROL_MASK,
      Gtk::ACCEL_VISIBLE) do
        @ok_button.signal_emit("clicked")
    end
    accel.connect(Gdk::Keyval::GDK_E, Gdk::Window::CONTROL_MASK,
      Gtk::ACCEL_VISIBLE) do
        @ex_button.signal_emit("clicked")
    end
    accel.connect(Gdk::Keyval::GDK_W, Gdk::Window::CONTROL_MASK,
      Gtk::ACCEL_VISIBLE) do
        @stop_button.signal_emit("clicked")
    end
    accel.connect(Gdk::Keyval::GDK_C, Gdk::Window::CONTROL_MASK,
      Gtk::ACCEL_VISIBLE) do
        @clear_button.signal_emit("clicked")
    end
    accel.connect(Gdk::Keyval::GDK_O, Gdk::Window::CONTROL_MASK,
      Gtk::ACCEL_VISIBLE) do
        @csv_button.signal_emit("clicked")
    end
    accel.connect(Gdk::Keyval::GDK_F, Gdk::Window::CONTROL_MASK,
      Gtk::ACCEL_VISIBLE) do
        @cancel_button.signal_emit("clicked")
    end
    accel.connect(Gdk::Keyval::GDK_Escape, nil, Gtk::ACCEL_VISIBLE) do
      @entry_find.grab_focus
    end
  end

  def event
    ui_name = @base.find_ui

    # key event
    @entry_find.signal_connect("activate") do
      @ok_button.grab_focus
    end

    @option_box.signal_connect("changed") do
      active_radio_val = search_active_radio(@radio_button)
      search_entry_mode(@entry_find, active_radio_val, @option_box)
    end

    @radio_button.each do |val, radio_obj|
      radio_obj.signal_connect("toggled") do |w|
        if w.active?
          option_text = @base.find_option
          @option_box.model.clear
          @option_box.hide
          @entry_find.set_sensitive(true)

          case radio_obj
          when @radio_button['sick']
            option_text["sickname"].each do |sick_val|
              o_text = @option_model.append
              o_text[0] = sick_val
            end
            @option_box.active = 0
            @option_box.show
          when @radio_button['si']
            option_text["si"].each do |si_val|
              o_text = @option_model.append
              o_text[0] = si_val
            end
            @option_box.active = 0
            @option_box.show
          when @radio_button['ten']
            option_text["comparison"].each do |ten_val|
              o_text = @option_model.append
              o_text[0] = ten_val
            end
            @option_box.active = 0
            @option_box.show
          when @radio_button['ymd']
            if @entry_find.text == ""
              nowt = Time.new
              nowmon = wa2sei(nowt.strftime("%Y%m").to_s + "10")
              @entry_find.set_text(nowmon)
            end
          when @radio_button['sy_ka']
            option_text["dtd"].each do |sy_ka_val|
              o_text = @option_model.append
              o_text[0] = sy_ka_val
            end
            @option_box.active = 0
            @option_box.show
          when @radio_button['nyugai_kbn']
            option_text["nyugai_kbn"].each do |nyugai_kbn_val|
              o_text = @option_model.append
              o_text[0] = nyugai_kbn_val
            end
            @option_box.active = 0
            @option_box.show
          when @radio_button['comment']
            option_text["comment"].each do |comment_val|
              o_text = @option_model.append
              o_text[0] = comment_val
            end
            @option_box.active = 0
            @option_box.show
          end
          @entry_find.grab_focus
        end
      end
    end

    @ok_button.signal_connect("activate") do
      @entry_find.grab_focus
    end

    @clear_button.signal_connect("clicked") do
      @model.clear
      @entry_find.set_text("")
      @entry_find.grab_focus
    end

    @csv_button.signal_connect("clicked") do
      if not @model.iter_first.nil?
        self.output_csv
      end
    end

    @stop_button.signal_connect("clicked") do
      @gui.search_thread.kill
      @gui.search_thread.join
      @entry_find.set_sensitive(true)
      @ok_button.set_sensitive(true)
      @ex_button.set_sensitive(true)
      @clear_button.set_sensitive(true)
      @csv_button.set_sensitive(true)
      @stop_button.set_sensitive(false)
      self.set_title(ui_name["stop_search_t"])
      @entry_find.grab_focus
    end

    @ex_button.signal_connect("clicked") do
      # /(名前|傷病名|医療品|診療行為)+/
      # /(name|sick|iy|si)+/
      # /(0|3|4|5)/
      
      case search_active_radio(@radio_button) 
      when 'name', 'sick', 'iy', 'si'
        search_text = "*" + @entry_find.text.gsub(/＊+|\*+/, "") + "*"
        search_text = "" if /^\*+$/ =~ search_text
        @entry_find.set_text(search_text)
      end

      @ok_button.clicked
    end
  end

  def output_csv
    pfs_hash = @gui.dialog_fs(self, "", "", false)
    pfs = pfs_hash["dialog"]
    pfs.set_title(@base.find_message["csv"])
    pfs.complete([@base.desktop_native, @csv_filename].join(@path_char))
    pfs.show_all

    msg_b = @base.file_message["exist_b"]
    msg_t = @base.file_message["exist_t"]
    pdlog = @rd.dialog_message([self, pfs], msg_t, msg_b, nil)

    msg_eb = @base.file_message["access_b"]
    msg_et = @base.file_message["access_t"]
    pdlog_e = @rd.dialog_message([self, pfs], msg_et, msg_eb, "ok")

    out_path = ""
    msg_ot = @base.find_message["csv"]
    msg_ob = @base.find_message["csv_ex"]
    wdlog = @rd.dialog_message([self], msg_ot, msg_ob, "ok", "hash")
    wdlog["dialog"].set_default_response(Gtk::Dialog::RESPONSE_OK)

    pfs.ok_button.signal_connect("clicked") do
      if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
        out_path = pfs.filename.tosjis
      else
        out_path = pfs.filename
      end

      if File.exist?(out_path)
        if File::ftype(out_path) != "directory"
          pdlog.show_all
        end
      else
        begin
          pfs.hide
          wdlog["dialog"].show_all
          self.output_csv_run(out_path)
        rescue
          pfs.hide
        end
      end
    end

    pfs.cancel_button.signal_connect("clicked") do
      pfs.hide
    end

    wdlog["dialog"].signal_connect("response") do |widget, response|
      case response
      when Gtk::Dialog::RESPONSE_OK
        wdlog["dialog"].hide
      when Gtk::Dialog::RESPONSE_CANCEL
        File.delete(out_path) if File.exist?(out_path)
      end
    end

    pdlog_e.signal_connect("response") do |widget, response|
      case response
      when Gtk::Dialog::RESPONSE_OK
        pdlog_e.hide
      end
    end

    pdlog.signal_connect("response") do |widget, response|
      case response
      when Gtk::Dialog::RESPONSE_OK
        begin
          pdlog.hide
          pfs.hide
          wdlog["dialog"].show_all
          self.output_csv_run(out_path)
        rescue
          pdlog.hide
          pdlog_e.show_all
        end
      when Gtk::Dialog::RESPONSE_CANCEL
        pdlog.hide
      end
    end
  end

  def output_csv_run(name_out)
    output_arr = []
    @model.each do |model, path, iter|
      arr = []
      @gui.tree_model_search_csvsize.times do |i|
        # Customize
        #if i == 0
        #  arr.push(sprintf("%05d", @model.get_value(iter, i).sub(/^\d{4}-\s+/, "")))
        #else
        #  arr.push(@model.get_value(iter, i))
        #end
        arr.push(@model.get_value(iter, i))
      end
      output_arr.push(arr.join(","))
    end
    file_out = output_utf8(name_out, ReceView::USER_ONLY_RW)
    file_out << output_arr.join("\n")
    file_out.close

    File.chmod(ReceView::USER_ONLY_RW, name_out)
  end

  def output_utf8(filename, mode=USER_ONLY_RW)
    if RUBY_VERSION.to_s >= "1.9.0"
      file = open(filename, "w+:utf-8:Windows-31J", mode)
    else
      file = open(filename, "w+", mode)
    end
    return file
  end

  def set_csv_filename(filename)
    if filename.class == Array
      if not filename.first.to_s.empty?
        arr = filename.first.split(/,/)
      else
        arr = []
      end
    else
      arr = filename.split(/,/)
    end
    if arr[0].to_s == "IR"
      kikan  = s2send_hoken_roman(arr[1].to_s)
      yyyymm = wa2sei(arr[7].to_s)
      @csv_filename = "search_#{kikan}_#{yyyymm}.csv"
    else
      @csv_filename = "search_#{now_Days}.csv"
    end
  end

  attr_accessor :ok_button
  attr_accessor :cancel_button
  attr_accessor :ex_button
  attr_accessor :clear_button
  attr_accessor :csv_button
  attr_accessor :stop_button
  attr_accessor :option_box
  attr_accessor :model
  attr_accessor :treeview
  attr_accessor :entry_find
  attr_accessor :radio_button
  attr_accessor :csv_filename
  attr_accessor :completion
  attr_accessor :complete_model
end

# 点数金額再計算ダイアログ
class ReceViewRecalDialog < Gtk::Dialog
  def initialize
    require 'jma/receview/base'
    super

    geometry = Gdk::Geometry.new
    geometry.set_min_width(480)
    geometry.set_min_height(420)
    geometry.set_max_width(1000)
    geometry.set_max_height(800)
    mask = Gdk::Window::HINT_MIN_SIZE | Gdk::Window::HINT_MAX_SIZE

    self.set_title("[点数チェック]")
    self.set_modal(false)            
    ReceViewGUI::SettingIcon(self)

    vbox = Gtk::VBox.new
    @exit_button = Gtk::Button.new(Gtk::Stock::CLOSE)

    @model = Gtk::TreeStore.new(String, String, String, String, String, String, Gdk::Color)
    @treeview = Gtk::TreeView.new(@model)
    column_data = ["レセ番号", "患者番号", "保険", "再計算点数", "請求点数","状態"]
    column_data.each_with_index do |item, i|
      tree_render = Gtk::CellRendererText.new
      case i
      when 2
        tree_render.xalign = 0.0
      else
        tree_render.xalign = 1.0
      end
      column = Gtk::TreeViewColumn.new(item, tree_render, 
        { :text => i,
          :background_gdk => 6
        })
      @treeview.append_column(column)
    end

    # 寄せ 1.0=L 2.0=R 0.5=Cnter
    @treeview.get_column(0).set_alignment(0.5)
    @treeview.get_column(1).set_alignment(0.5)
    @treeview.get_column(2).set_alignment(0.5)
    @treeview.get_column(3).set_alignment(0.5)
    @treeview.get_column(4).set_alignment(0.5)
    @treeview.get_column(5).set_alignment(0.5)

    sw1 = Gtk::ScrolledWindow.new
    sw1.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    sw1.add(@treeview)
    vbox.pack_start(sw1, true, true, 5)

    self.action_area.pack_start(@exit_button)
    self.vbox.pack_start(vbox)

    @accel = Gtk::AccelGroup.new
    @accel.connect(Gdk::Keyval::GDK_T, Gdk::Window::CONTROL_MASK,
      Gtk::ACCEL_VISIBLE) do
        @exit_button.signal_emit("clicked")
    end
    self.add_accel_group(@accel)

    self.set_geometry_hints(nil, geometry, mask)
    self.hide

    @exit_button.signal_connect("clicked") do
      self.hide
    end

    self.signal_connect("delete_event") do
      self.hide
    end
  end

  def trans_window(trans)
    ReceViewGUI::TransWindow(self, trans)
  end

  attr_accessor :treeview
  attr_accessor :model
end

# 病名編集ダイアログ
class ReceViewByomeiEdit < Gtk::Dialog
  def initialize
    require 'jma/receview/base'
    super

    geometry = Gdk::Geometry.new
    geometry.set_min_width(380)
    geometry.set_min_height(320)
    geometry.set_max_width(380)
    geometry.set_max_height(320)
    mask = Gdk::Window::HINT_MIN_SIZE | 
           Gdk::Window::HINT_MAX_SIZE | Gdk::Window::HINT_RESIZE_INC
    self.init_title
    self.set_modal(true)            
    ReceViewGUI::SettingIcon(self)

    vbox = Gtk::VBox.new
    vbox1 = Gtk::VBox.new
    vbox2 = Gtk::VBox.new
    hbox = Gtk::HBox.new
    hbox1 = Gtk::HBox.new
    hbox2 = Gtk::HBox.new

    b_label = Gtk::Label.new("出力コード:")
    @label_code = Gtk::Entry.new
    @label_code.set_editable(false)

    label = Gtk::Label.new("検索:     ")
    @entry = Gtk::Entry.new

    dummy_label = Gtk::Label.new("")
    hosoku_label = Gtk::Label.new("補足コメント:")
    @hosoku_code = Gtk::Entry.new

    @ok_button   = Gtk::Button.new(Gtk::Stock::OK)
    @exit_button = Gtk::Button.new(Gtk::Stock::CLOSE)

    hbox1.pack_start(b_label, false, true, 2)
    hbox1.pack_start(@label_code, true, true, 2)

    hbox2.pack_start(dummy_label, false, true, 2)
    hbox2.pack_start(hosoku_label, false, true, 2)
    hbox2.pack_start(@hosoku_code, true, true, 2)
    vbox2.pack_start(hbox2, true, true, 2)

    hbox.pack_start(label, false, true, 2)
    hbox.pack_start(@entry, true, true, 2)

    vbox1.pack_start(hbox, false, true, 2)
    vbox1.pack_start(hbox1, false, true, 2)

    @model= Gtk::TreeStore.new(String, String, String, String, Gdk::Color)
    tree_render = Gtk::CellRendererText.new
    @treeview = Gtk::TreeView.new(@model)

    column_size = [180, 100, 120, 130]
    column_data = ["候補一覧", "解決コード", "期間", "ステータス"]
    column_data.each_with_index do |item, i|
      column = Gtk::TreeViewColumn.new(item, tree_render, 
        { :text => i,
          :background_gdk => 4
        })
      column.set_min_width(column_size[i])
      @treeview.append_column(column)
    end

    sw1 = Gtk::ScrolledWindow.new
    sw1.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    sw1.add_with_viewport(@treeview)

    self.action_area.pack_start(@ok_button)
    self.action_area.pack_start(@exit_button)
    vbox.pack_start(vbox1, false, true, 5)
    vbox.pack_start(sw1, true, true, 5)
    vbox.pack_start(vbox2, false, true, 2)
    self.vbox.pack_start(vbox)

    self.set_geometry_hints(@ok_button, geometry, mask)
    self.user_event
    return self
  end

  def trans_window(trans)
    ReceViewGUI::TransWindow(self, trans)
  end

  def init_title
    self.set_title("病名変更")
  end

  def user_event
    @exit_button.signal_connect("clicked") do
      self.hide
    end

    self.signal_connect("delete_event") do
      self.hide
    end
  end

  attr_accessor :treeview
  attr_accessor :entry
  attr_accessor :model
  attr_accessor :label_code
  attr_accessor :hosoku_code
  attr_accessor :ok_button
  attr_accessor :exit_button
end

# 病名コード置換ダイアログ
class ReceViewByomeiRe < Gtk::Dialog
  def initialize
    require 'jma/receview/base'
    @base = ReceView_Base.new
    super

    geometry = Gdk::Geometry.new
    geometry.set_min_width(200)
    geometry.set_min_height(50)
    geometry.set_max_width(200)
    geometry.set_max_height(50)
    mask = Gdk::Window::HINT_MIN_SIZE | 
           Gdk::Window::HINT_MAX_SIZE | Gdk::Window::HINT_RESIZE_INC
    self.init_title
    self.set_modal(true)            
    ReceViewGUI::SettingIcon(self)

    vbox  = Gtk::VBox.new
    hbox1 = Gtk::HBox.new
    hbox2 = Gtk::HBox.new
    hbox3 = Gtk::HBox.new
    hbox4 = Gtk::HBox.new
    hbox5 = Gtk::HBox.new

    mes = @base.sickname_edit_message

    @stitle_label = Gtk::Label.new("\n"+mes["move_title"])
    @time_limit = Gtk::Label.new(mes["move_timelimit"]+"\n")
    in_sick_label = Gtk::Label.new(mes["move_in_name"])
    out_sick_label = Gtk::Label.new(mes["move_out_name"])
    message_label = Gtk::Label.new("\n"+mes["move_message"]+"\n")

    @old_code = Gtk::Entry.new
    @old_name = Gtk::Entry.new
    @new_code = Gtk::Entry.new
    @new_name = Gtk::Entry.new

    @old_code.set_editable(false)
    @old_name.set_editable(false)
    @new_code.set_editable(false)
    @new_name.set_editable(false)

    @ok_button   = Gtk::Button.new(Gtk::Stock::OK)
    @quo_button  = Gtk::Button.new(:"sick-gtk-quo-edit")
    @uniq_button = Gtk::Button.new(:"sick-gtk-uniq-edit")

    @quo_button.set_image(Gtk::Image.new(Gtk::Stock::OK,
                          Gtk::IconSize::MENU))
    @uniq_button.set_image(Gtk::Image.new(Gtk::Stock::EDIT,
                          Gtk::IconSize::MENU))

    hbox1.pack_start(@old_code, false, true, 5)
    hbox1.pack_start(@old_name, true, true, 5)
    hbox2.pack_start(@new_code, false, true, 5)
    hbox2.pack_start(@new_name, true, true, 5)
    hbox3.pack_start(in_sick_label, false, true, 5)
    hbox4.pack_start(out_sick_label, false, true, 5)
    hbox5.pack_start(message_label, false, true, 5)

    vbox.pack_start(@stitle_label, false, true, 2)
    vbox.pack_start(@time_limit, false, true, 2)
    vbox.pack_start(hbox3, true, false, 2)
    vbox.pack_start(hbox1, false, true, 2)
    vbox.pack_start(hbox4, false, true, 2)
    vbox.pack_start(hbox2, false, true, 2)
    vbox.pack_start(hbox5, true, true, 2)

    self.action_area.pack_start(@ok_button)
    self.action_area.pack_start(@uniq_button)
    self.action_area.pack_start(@quo_button)
    self.vbox.pack_start(vbox)

    self.set_geometry_hints(@ok_button, geometry, mask)
    self.user_event

    return self
  end

  def trans_window(trans)
    ReceViewGUI::TransWindow(self, trans)
  end

  def init_title
    self.set_title("病名コード置き換え確認")
  end

  def user_event
    self.signal_connect("delete_event") do
      self.hide
    end
  end

  attr_accessor :time_limit
  attr_accessor :old_code
  attr_accessor :old_name
  attr_accessor :new_code
  attr_accessor :new_name
  attr_accessor :ok_button
  attr_accessor :uniq_button
  attr_accessor :quo_button
end

# 頭書き編集ダイアログ
class ReceViewHeadLine < Gtk::Dialog
  def initialize
    require 'jma/receview/base'
    @base = ReceView_Base.new
    super

    geometry = Gdk::Geometry.new
    geometry.set_min_width(180)
    geometry.set_min_height(50)
    geometry.set_max_width(180)
    geometry.set_max_height(50)
    mask = Gdk::Window::HINT_MIN_SIZE | 
           Gdk::Window::HINT_MAX_SIZE | Gdk::Window::HINT_RESIZE_INC
    self.init_title
    self.set_modal(true)            
    ReceViewGUI::SettingIcon(self)

    he = @base.headline_edit

    @tab_kouhi = Gtk::Notebook.new
    @tab_kouhi.homogeneous = true
    
    label_name = Gtk::Label.new(he["name"])
    label_sex = Gtk::Label.new(he["sex"])
    label_hkno = Gtk::Label.new(he["hkno"])
    label_hkno_k = Gtk::Label.new(he["hkno_k"])
    label_hkno_b = Gtk::Label.new(he["hkno_b"])

    label_kouhi1_htno = Gtk::Label.new(he["htno"])
    label_kouhi1_juno = Gtk::Label.new(he["juno"])
    label_kouhi2_htno = Gtk::Label.new(he["htno"])
    label_kouhi2_juno = Gtk::Label.new(he["juno"])
    label_kouhi3_htno = Gtk::Label.new(he["htno"])
    label_kouhi3_juno = Gtk::Label.new(he["juno"])
    label_kouhi4_htno = Gtk::Label.new(he["htno"])
    label_kouhi4_juno = Gtk::Label.new(he["juno"])

    @entry_name = Gtk::Entry.new
    @entry_hkno = Gtk::Entry.new
    @entry_hkno_k = Gtk::Entry.new
    @entry_hkno_b = Gtk::Entry.new

    @entry_ko1_htno = Gtk::Entry.new
    @entry_ko1_juno = Gtk::Entry.new
    @entry_ko2_htno = Gtk::Entry.new
    @entry_ko2_juno = Gtk::Entry.new
    @entry_ko3_htno = Gtk::Entry.new
    @entry_ko3_juno = Gtk::Entry.new
    @entry_ko4_htno = Gtk::Entry.new
    @entry_ko4_juno = Gtk::Entry.new

    @combox_sex = Gtk::ComboBox.new
    @base.sex.sort.each do |key, val| @combox_sex.append_text(val) end
    @combox_sex.active = 0

    @ok_button = Gtk::Button.new(Gtk::Stock::OK)
    @redo_button = Gtk::Button.new(Gtk::Stock::REDO)
    @cancel_button = Gtk::Button.new(Gtk::Stock::CANCEL)

    self.set_geometry_hints(@ok_button, geometry, mask)

    frame_kihon = Gtk::Frame.new(label = "基本情報")
    frame_hkno  = Gtk::Frame.new(label = "保険者情報")

    vbox_kihon = Gtk::VBox.new
    vbox_hkno  = Gtk::VBox.new

    vbox  = Gtk::VBox.new
    hbox1 = Gtk::HBox.new
    hbox3 = Gtk::HBox.new
    hbox4 = Gtk::HBox.new
    hbox5 = Gtk::HBox.new
    hbox_kouhi1 = Gtk::HBox.new
    hbox_kouhi2 = Gtk::HBox.new
    hbox_kouhi3 = Gtk::HBox.new
    hbox_kouhi4 = Gtk::HBox.new

    label_name.set_justify(Gtk::JUSTIFY_LEFT)
    label_sex.set_justify(Gtk::JUSTIFY_LEFT)
    label_hkno.set_justify(Gtk::JUSTIFY_LEFT)

    label_kouhi1_htno.set_justify(Gtk::JUSTIFY_LEFT)
    label_kouhi1_juno.set_justify(Gtk::JUSTIFY_LEFT)
    label_kouhi2_htno.set_justify(Gtk::JUSTIFY_LEFT)
    label_kouhi2_juno.set_justify(Gtk::JUSTIFY_LEFT)
    label_kouhi3_htno.set_justify(Gtk::JUSTIFY_LEFT)
    label_kouhi3_juno.set_justify(Gtk::JUSTIFY_LEFT)
    label_kouhi4_htno.set_justify(Gtk::JUSTIFY_LEFT)
    label_kouhi4_juno.set_justify(Gtk::JUSTIFY_LEFT)

    hbox1.pack_start(label_name, false, true, 5)
    hbox1.pack_start(@entry_name, true, true, 5)

    hbox1.pack_start(label_sex,  false, true, 5)
    hbox1.pack_start(@combox_sex, false, true, 5)

    vbox_kihon.pack_start(hbox1, false, false, 7)
    frame_kihon.add(vbox_kihon)

    hbox3.pack_start(label_hkno, false, false, 5)
    hbox3.pack_start(@entry_hkno, false, false, 5)

    hbox4.pack_start(label_hkno_k, false, false, 5)
    hbox4.pack_start(@entry_hkno_k, true, true, 5)

    hbox5.pack_start(label_hkno_b, false, false, 5)
    hbox5.pack_start(@entry_hkno_b, true, true, 5)

    vbox_hkno.pack_start(hbox3, false, false, 7)
    vbox_hkno.pack_start(hbox4, false, false, 7)
    vbox_hkno.pack_start(hbox5, false, false, 7)

    frame_hkno.add(vbox_hkno)

    hbox_kouhi1.pack_start(label_kouhi1_htno, false, false, 5)
    hbox_kouhi1.pack_start(@entry_ko1_htno, true, true, 5)
    hbox_kouhi1.pack_start(label_kouhi1_juno, false, false, 5)
    hbox_kouhi1.pack_start(@entry_ko1_juno, true, true, 5)

    hbox_kouhi2.pack_start(label_kouhi2_htno, false, false, 5)
    hbox_kouhi2.pack_start(@entry_ko2_htno, true, true, 5)
    hbox_kouhi2.pack_start(label_kouhi2_juno, false, false, 5)
    hbox_kouhi2.pack_start(@entry_ko2_juno, true, true, 5)

    hbox_kouhi3.pack_start(label_kouhi3_htno, false, false, 5)
    hbox_kouhi3.pack_start(@entry_ko3_htno, true, true, 5)
    hbox_kouhi3.pack_start(label_kouhi3_juno, false, false, 5)
    hbox_kouhi3.pack_start(@entry_ko3_juno, true, true, 5)

    hbox_kouhi4.pack_start(label_kouhi4_htno, false, false, 5)
    hbox_kouhi4.pack_start(@entry_ko4_htno, true, true, 5)
    hbox_kouhi4.pack_start(label_kouhi4_juno, false, false, 5)
    hbox_kouhi4.pack_start(@entry_ko4_juno, true, true, 5)

    @tab_kouhi.append_page(hbox_kouhi1, Gtk::Label.new("公費１"))
    @tab_kouhi.append_page(hbox_kouhi2, Gtk::Label.new("公費２"))
    @tab_kouhi.append_page(hbox_kouhi3, Gtk::Label.new("公費３"))
    @tab_kouhi.append_page(hbox_kouhi4, Gtk::Label.new("公費４"))

    vbox.pack_start(frame_kihon, false, true, 10)
    vbox.pack_start(frame_hkno, false, true, 10)
    vbox.pack_start(@tab_kouhi, true, true, 10)

    self.action_area.pack_start(@redo_button)
    self.action_area.pack_start(@ok_button)
    self.action_area.pack_start(@cancel_button)
    self.vbox.pack_start(vbox)
    return self
  end

  def trans_window(trans)
    ReceViewGUI::TransWindow(self, trans)
  end

  def init_title
    self.set_title(@base.headline_edit["title"])
  end

  def user_event
    self.signal_connect("delete_event") do
      self.hide
    end
  end

  attr_accessor :tab_kouhi
  attr_accessor :entry_name
  attr_accessor :entry_hkno
  attr_accessor :entry_hkno_k
  attr_accessor :entry_hkno_b
  attr_accessor :entry_ko1_juno
  attr_accessor :entry_ko1_htno
  attr_accessor :entry_ko2_juno
  attr_accessor :entry_ko2_htno
  attr_accessor :entry_ko3_juno
  attr_accessor :entry_ko3_htno
  attr_accessor :entry_ko4_juno
  attr_accessor :entry_ko4_htno
  attr_accessor :combox_sex
  attr_accessor :ok_button
  attr_accessor :redo_button
  attr_accessor :cancel_button
end

# フォント設定ダイアログ
class ReceViewFontDialog < Gtk::Dialog
  def initialize
    require 'jma/receview/base'
    require 'jma/receview/strconv'
    @gui = ReceViewGUI.new
    @base = ReceView_Base.new
    @path_char = @base.path_char

    super

    default_title
    self.set_modal(true)
    ReceViewGUI::SettingIcon(self)

    @geometry = Gdk::Geometry.new
    @geometry.set_min_width(120)
    @geometry.set_min_height(60)
    @geometry.set_max_width(120)
    @geometry.set_max_height(60)
    @mask = Gdk::Window::HINT_MIN_SIZE | 
           Gdk::Window::HINT_MAX_SIZE | Gdk::Window::HINT_RESIZE_INC

    @label_font_main = Gtk::Label.new("全般")
    @label_font_info = Gtk::Label.new("基本情報ビュー")
    @label_font_sick = Gtk::Label.new("傷病名ビュー")
    @label_font_teki = Gtk::Label.new("摘要欄ビュー")
    @label_font_santei = Gtk::Label.new("算定日ビュー")
    @label_font_other = Gtk::Label.new("ステータスバー")
    @label_font_preview = Gtk::Label.new("プレビュー")
    @label_font_all1 = Gtk::Label.new("")
    @label_font_all2 = Gtk::Label.new("")

    @label_font_main.set_size_request(140, 24)
    @label_font_info.set_size_request(140, 24)
    @label_font_sick.set_size_request(140, 24)
    @label_font_teki.set_size_request(140, 24)
    @label_font_santei.set_size_request(140, 24)
    @label_font_other.set_size_request(140, 24)
    @label_font_preview.set_size_request(140, 24)
    @label_font_all1.set_size_request(0, 0)
    @label_font_all2.set_size_request(0, 0)

    @entry_font_main = Gtk::Entry.new
    @entry_font_info = Gtk::Entry.new
    @entry_font_sick = Gtk::Entry.new
    @entry_font_teki = Gtk::Entry.new
    @entry_font_santei = Gtk::Entry.new
    @entry_font_other = Gtk::Entry.new
    @entry_font_preview = Gtk::Entry.new
    @entry_font_main.set_editable(false)
    @entry_font_info.set_editable(false)
    @entry_font_sick.set_editable(false)
    @entry_font_teki.set_editable(false)
    @entry_font_santei.set_editable(false)
    @entry_font_other.set_editable(false)
    @entry_font_preview.set_editable(false)

    @hbox1 = Gtk::HBox.new
    @hbox2 = Gtk::HBox.new
    @hbox3 = Gtk::HBox.new
    @hbox4 = Gtk::HBox.new
    @hbox5 = Gtk::HBox.new
    @hbox6 = Gtk::HBox.new
    @hbox7 = Gtk::HBox.new
    @hbox8 = Gtk::HBox.new
    @vbox = Gtk::VBox.new

    @label_font_main.set_justify(Gtk::JUSTIFY_LEFT)
    @label_font_info.set_justify(Gtk::JUSTIFY_LEFT)
    @label_font_sick.set_justify(Gtk::JUSTIFY_LEFT)
    @label_font_teki.set_justify(Gtk::JUSTIFY_LEFT)
    @label_font_santei.set_justify(Gtk::JUSTIFY_LEFT)
    @label_font_other.set_justify(Gtk::JUSTIFY_LEFT)
    @label_font_preview.set_justify(Gtk::JUSTIFY_LEFT)

    @button_font_main = Gtk::Button.new("選択")
    @button_font_info = Gtk::Button.new("選択")
    @button_font_sick = Gtk::Button.new("選択")
    @button_font_teki = Gtk::Button.new("選択")
    @button_font_santei = Gtk::Button.new("選択")
    @button_font_other = Gtk::Button.new("選択")
    @button_font_preview = Gtk::Button.new("選択")
    @button_font_all = Gtk::Button.new("すべてのフォント選択")

    @hbox1.pack_start(@label_font_main, false, false, 0)
    @hbox1.pack_start(@entry_font_main, true, true, 5)
    @hbox1.pack_start(@button_font_main, false, false, 5)

    @hbox2.pack_start(@label_font_info, false, true, 0)
    @hbox2.pack_start(@entry_font_info, true, true, 5)
    @hbox2.pack_start(@button_font_info, false, false, 5)

    @hbox3.pack_start(@label_font_sick, false, true, 0)
    @hbox3.pack_start(@entry_font_sick, true, true, 5)
    @hbox3.pack_start(@button_font_sick, false, false, 5)

    @hbox4.pack_start(@label_font_teki, false, true, 0)
    @hbox4.pack_start(@entry_font_teki, true, true, 5)
    @hbox4.pack_start(@button_font_teki, false, false, 5)

    @hbox5.pack_start(@label_font_santei, false, true, 0)
    @hbox5.pack_start(@entry_font_santei, true, true, 5)
    @hbox5.pack_start(@button_font_santei, false, false, 5)

    @hbox6.pack_start(@label_font_other, false, true, 0)
    @hbox6.pack_start(@entry_font_other, true, true, 5)
    @hbox6.pack_start(@button_font_other, false, false, 5)

    @hbox7.pack_start(@label_font_preview, false, true, 0)
    @hbox7.pack_start(@entry_font_preview, true, true, 5)
    @hbox7.pack_start(@button_font_preview, false, false, 5)

    @hbox8.pack_start(@label_font_all1, false, true, 0)
    @hbox8.pack_start(@label_font_all2, true, true, 5)
    @hbox8.pack_start(@button_font_all, false, false, 5)

    @ok_button = Gtk::Button.new(Gtk::Stock::OK)
    @cancel_button = Gtk::Button.new(Gtk::Stock::CANCEL)

    @vbox.pack_start(@hbox1, false, true, 3)
    @vbox.pack_start(@hbox2, false, true, 3)
    @vbox.pack_start(@hbox3, false, true, 3)
    @vbox.pack_start(@hbox4, false, true, 3)
    @vbox.pack_start(@hbox5, false, true, 3)
    @vbox.pack_start(@hbox6, false, true, 3)
    @vbox.pack_start(@hbox7, false, true, 3)
    @vbox.pack_start(@hbox8, false, true, 3)

    @frame_fonts = Gtk::Frame.new("フォントの設定")
    @frame_fonts.add(@vbox)

    self.accel_setting
    self.action_area.pack_start(@ok_button)
    self.action_area.pack_start(@cancel_button)
    self.vbox.pack_start(@frame_fonts)
    self.set_geometry_hints(@ok_button, @geometry, @mask)
    self.event

    return self
  end

  def accel_setting(accel=nil)
    accel = Gtk::AccelGroup.new if accel.nil?

    accel.connect(Gdk::Keyval::GDK_O, Gdk::Window::CONTROL_MASK, Gtk::ACCEL_VISIBLE) do
      @ok_button.signal_emit("clicked")
    end

    accel.connect(Gdk::Keyval::GDK_C, Gdk::Window::CONTROL_MASK, Gtk::ACCEL_VISIBLE) do
      @cancel_button.signal_emit("clicked")
    end
    self.add_accel_group(accel)
  end

  def event
    @cancel_button.signal_connect("clicked") do
      self.hide
    end

    self.signal_connect("delete_event") do
      self.hide
      true
    end
  end

  def trans_window(trans)
    ReceViewGUI::TransWindow(self, trans)
  end

  def default_title
    self.set_title("フォント設定")
  end

  attr_accessor :entry_font_main
  attr_accessor :entry_font_info
  attr_accessor :entry_font_sick
  attr_accessor :entry_font_teki
  attr_accessor :entry_font_santei
  attr_accessor :entry_font_other
  attr_accessor :entry_font_preview
  attr_accessor :entry_font_all
  attr_accessor :button_font_main
  attr_accessor :button_font_info
  attr_accessor :button_font_sick
  attr_accessor :button_font_teki
  attr_accessor :button_font_santei
  attr_accessor :button_font_other
  attr_accessor :button_font_preview
  attr_accessor :button_font_all
  attr_accessor :ok_button
  attr_accessor :cancel_button
end

# フォント選択セレクトダイアログ
class ReceViewFontSelectDialog < Gtk::FontSelectionDialog
  def initialize(gui, entry, style)
    require 'jma/receview/base'
    require 'jma/receview/strconv'
    @base = ReceView_Base.new
    @path_char = @base.path_char
    super()

    self.default_title
    self.set_preview_text("あいうえお レセ電 AAA BBB CCC 123")
    self.set_modal(true)
    self.set_font_name(entry.text) if entry.class == Gtk::Entry
    ReceViewGUI::SettingIcon(self)

    event(gui, entry, style)
    self.show_all
    return self
  end

  def event(gui, entry, style)
    self.ok_button.signal_connect("clicked") do
      event_done(gui, entry, style)
      self.hide
    end

    self.apply_button.signal_connect("clicked") do
      event_done(gui, entry, style)
    end

    self.cancel_button.signal_connect("clicked") do
      self.hide
    end

    self.signal_connect("delete_event") do
      self.hide
    end
  end

  def event_done(gui, entry, style)
    case style
    when 'main'
      self.event_done_main(gui, entry, style)
    when 'info'
      self.event_done_info(gui, entry, style)
    when 'sick'
      self.event_done_sick(gui, entry, style)
    when 'teki'
      self.event_done_teki(gui, entry, style)
    when 'santei'
      self.event_done_santei(gui, entry, style)
    when 'other'
      self.event_done_other(gui, entry, style)
    when 'preview'
      self.event_done_preview(gui, entry, style)
    when 'all'
      self.event_done_all(gui, entry, style)
    end
  end

  def event_done_main(gui, entry, style)
    font = Pango::FontDescription.new(self.font_name)
    kanja_style = Gtk::Style.new.set_font_desc(font)
    kanja_style.set_fg(Gtk::STATE_NORMAL, 0, 0, 0)

    gui.ir_tree.set_font_style(self.font_name)
    gui.re_tree.set_font_style(self.font_name)
    entry.set_text(self.font_name)
  end

  def event_done_info(gui, entry, style)
    font = Pango::FontDescription.new(self.font_name)
    kanja_style = Gtk::Style.new.set_font_desc(font)
    kanja_style.set_fg(Gtk::STATE_NORMAL, 0, 0, 0)

    gui.set_font_style(self.font_name)
    entry.set_text(self.font_name)
  end

  def event_done_sick(gui, entry, style)
    font = Pango::FontDescription.new(self.font_name)
    kanja_style = Gtk::Style.new.set_font_desc(font)
    kanja_style.set_fg(Gtk::STATE_NORMAL, 0, 0, 0)

    gui.byomei_tree.set_font_style(self.font_name)
    entry.set_text(self.font_name)
  end

  def event_done_teki(gui, entry, style)
    font = Pango::FontDescription.new(self.font_name)
    kanja_style = Gtk::Style.new.set_font_desc(font)
    kanja_style.set_fg(Gtk::STATE_NORMAL, 0, 0, 0)

    gui.tekiyo_tree.set_font_style(self.font_name)
    entry.set_text(self.font_name)
  end

  def event_done_santei(gui, entry, style)
    font = Pango::FontDescription.new(self.font_name)
    kanja_style = Gtk::Style.new.set_font_desc(font)
    kanja_style.set_fg(Gtk::STATE_NORMAL, 0, 0, 0)

    gui.santei_tree.set_font_style(self.font_name)
    entry.set_text(self.font_name)
  end

  def event_done_other(gui, entry, style)
    font = Pango::FontDescription.new(self.font_name)
    kanja_style = Gtk::Style.new.set_font_desc(font)
    kanja_style.set_fg(Gtk::STATE_NORMAL, 10000, 0, 50000)
   
    entry.set_text(self.font_name)
    gui.status_bar.set_style(kanja_style)
  end

  def event_done_preview(gui, entry, style)
    entry.set_text(self.font_name)
  end

  def event_done_all(gui, dfont, style)
    if dfont.class == ReceViewFontDialog
      self.event_done_main(gui, dfont.entry_font_main, style)
      self.event_done_info(gui, dfont.entry_font_info, style)
      self.event_done_sick(gui, dfont.entry_font_sick, style)
      self.event_done_teki(gui, dfont.entry_font_teki, style)
      self.event_done_santei(gui, dfont.entry_font_santei, style)
      self.event_done_other(gui, dfont.entry_font_other, style)
      self.event_done_preview(gui, dfont.entry_font_preview, style)
    end
  end

  def trans_window(trans)
    ReceViewGUI::TransWindow(self, trans)
  end

  def default_title
    self.set_title("フォント選択")
  end
end

# 状態表示プログレス
class ReceViewProgress < Gtk::Window
  def initialize
    require 'jma/receview/base'
    @base = ReceView_Base.new
    super

    vbox = Gtk::VBox.new

    text = Gtk::Label.new(@base.msg_prog["situation"])
    prog = Gtk::ProgressBar.new

    font = Pango::FontDescription.new("Sans 10")
    text_style = Gtk::Style.new.set_font_desc(font)
    text.set_style(text_style)

    prog.fraction = 0 
    prog.set_text("0%")
    vbox.pack_start(text, false, true, 0)
    vbox.pack_start(prog, false, true, 0)

    set_window_position(Gtk::Window::Position::CENTER)
    set_decorated(false)
    set_modal(true)
    set_keep_above(true)
    set_accept_focus(false)
    set_default_size(320,40)

    add(vbox)

    @text = text
    @progress = prog
    @dialog = self
  end

  def dialog
    @dialog
  end

  def progress
    @progress
  end

  def text
    @text
  end
end

class ReceViewGUI::HPaned < Gtk::HPaned
  def initialize
    super
    @user_position_int = -1
    @user_position_status = true
  end

  def handle_size
    return self.style_get_property("handle-size")
  end

  def user_position_active?
    @user_position_status
  end

  def user_position
    @user_position_int
  end

  def set_user_position(pos)
    if pos.class == TrueClass || pos.class == FalseClass
      @user_position_status = pos
    elsif pos.class == Fixnum
      @user_position_status = true
      @user_position_int = pos
    else
      @user_position_status = false
      @user_position_int = -1
    end
  end
end

class ReceViewGUI::VPaned < Gtk::VPaned
  def initialize
    super
  end
end

class ReceViewGUI::ToolBox < Gtk::Window
  STOCK_LABEL = 1
  def initialize
    require 'jma/receview/base'
    @base = ReceView_Base.new
    @next_event = nil
    @pext_event = nil
    @preview_next_event = nil
    @preview_pext_event = nil
    @hide_position = nil
    super()

    geometry = Gdk::Geometry.new
    geometry.set_min_width(150)
    geometry.set_min_height(160)
    geometry.set_max_width(150)
    geometry.set_max_height(160)
    mask = Gdk::Window::HINT_MIN_SIZE | Gdk::Window::HINT_MAX_SIZE

    self.set_title(@base.toolbox_ui["title"])
    self.set_modal(false)            
    self.set_geometry_hints(nil, geometry, mask)
    self.set_type_hint(Gdk::Window::TYPE_HINT_UTILITY)
    ReceViewGUI::SettingIcon(self)

    @box = Gtk::VBox.new(false, 0)
    @box1 = Gtk::HBox.new(false, 0)
    @box2 = Gtk::HBox.new(false, 0)

    @next_button = new_button_add(Gtk::Stock.lookup(:"toolbox-gtk-next")[STOCK_LABEL],
                                  Gtk::Stock::GO_FORWARD, Gtk::IconSize::BUTTON)
    @pext_button = new_button_add(Gtk::Stock.lookup(:"toolbox-gtk-pext")[STOCK_LABEL],
                                  Gtk::Stock::GO_BACK, Gtk::IconSize::BUTTON)
    @preview_next_button = new_button_add(Gtk::Stock.lookup(:"toolbox-gtk-preview-next")[STOCK_LABEL],
                                  Gtk::Stock::GO_FORWARD, Gtk::IconSize::BUTTON)
    @preview_pext_button = new_button_add(Gtk::Stock.lookup(:"toolbox-gtk-preview-pext")[STOCK_LABEL],
                                  Gtk::Stock::GO_BACK, Gtk::IconSize::BUTTON)
    @close_button = Gtk::Button.new("")

    @box1.pack_start(@pext_button, true, true, 0)
    @box1.pack_start(@next_button, true, true, 0)
    @box2.pack_start(@preview_pext_button, true, true, 0)
    @box2.pack_start(@preview_next_button, true, true, 0)
    @box.pack_start(@box1, true, true, 0)
    @box.pack_start(@box2, true, true, 0)
    self.add(@box)
    self.accel_setting
    self.event
  end

  def new_button_add(name, stock, size)
    new_button = Gtk::Button.new
    vx = Gtk::VBox.new(false, 0)
    vimage = Gtk::Image.new(stock, size)
    vlabel = Gtk::Label.new(name)
    vlabel.set_use_underline(true)
    vx.pack_start(vimage, false, false, 3)
    vx.pack_start(vlabel, false, false, 3)
    new_button.add(vx)
    return new_button
  end

  def trans_window(trans)
    ReceViewGUI::TransWindow(self, trans)
  end

  def accel_setting
    @accel = Gtk::AccelGroup.new
    @accel.connect(Gdk::Keyval::GDK_F12, nil, Gtk::ACCEL_VISIBLE) do
      @next_button.signal_emit("clicked")
    end

    @accel.connect(Gdk::Keyval::GDK_F11, nil, Gtk::ACCEL_VISIBLE) do
      @pext_button.signal_emit("clicked")
    end

    @accel.connect(Gdk::Keyval::GDK_F10, nil, Gtk::ACCEL_VISIBLE) do
      @preview_next_button.signal_emit("clicked")
    end

    @accel.connect(Gdk::Keyval::GDK_F9, nil, Gtk::ACCEL_VISIBLE) do
      @preview_pext_button.signal_emit("clicked")
    end

    @accel.connect(Gdk::Keyval::GDK_B, Gdk::Window::CONTROL_MASK, Gtk::ACCEL_VISIBLE) do
      @hide_position = self.position
      self.hide
    end
    self.add_accel_group(@accel)
  end

  def event
    @next_button.signal_connect("clicked") do
      @hide_position = self.position
      if @next_event.class == Proc
        @next_event.call
      end
    end

    @pext_button.signal_connect("clicked") do
      @hide_position = self.position
      if @pext_event.class == Proc
        @pext_event.call
      end
    end

    @preview_next_button.signal_connect("clicked") do
      @hide_position = self.position
      if @preview_next_event.class == Proc
        @preview_next_event.call
      end
    end

    @preview_pext_button.signal_connect("clicked") do
      @hide_position = self.position
      if @preview_pext_event.class == Proc
        @preview_pext_event.call
      end
    end

    @close_button.signal_connect("clicked") do
      @hide_position = self.position
      self.hide
    end

    self.signal_connect("delete_event") do
      @hide_position = self.position
      self.hide
      true
    end
  end

  def hide_position
    @hide_position
  end

  def set_hide_position(pos)
    @hide_position = pos
  end

  def add_event_next(proc_data)
    @next_event = proc_data
  end

  def add_event_pext(proc_data)
    @pext_event = proc_data
  end

  def add_event_preview_next(proc_data)
    @preview_next_event = proc_data
  end

  def add_event_preview_pext(proc_data)
    @preview_pext_event = proc_data
  end

  attr_accessor :close_button
  attr_accessor :next_button
  attr_accessor :pext_button
  attr_accessor :preview_next_button
  attr_accessor :preview_pext_button
end

class ReceViewGUI::UpdateDialog < Gtk::Dialog
  def initialize
    require 'jma/receview/base'
    @base = ReceView_Base.new
    super

    geometry = Gdk::Geometry.new
    geometry.set_min_width(400)
    geometry.set_min_height(280)
    geometry.set_max_width(400)
    geometry.set_max_height(280)
    mask = Gdk::Window::HINT_MIN_SIZE | 
           Gdk::Window::HINT_MAX_SIZE | Gdk::Window::HINT_RESIZE_INC
    self.set_title("JMA ReceView Updater")
    self.set_modal(true)
    self.set_keep_above(true)
    self.set_geometry_hints(nil, geometry, mask)

    omsg = @base.msg_update["start"]
    @label_msg = Gtk::Label.new(omsg)

    box = Gtk::HBox.new
    image = ""
    image_list = ["jma-receview-icon.png", "/usr/share/pixmaps/jma-receview-icon.png"]
    image_list.each do |img_path|
      if File.exist?(img_path)
        image = Gtk::Image.new(img_path)
        break
      end
    end
    box.pack_start(image, false, false, 5)
    box.pack_start(@label_msg, true, false, 5)
    self.vbox.add(box)

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

    return self
  end

  def label_msg
    @label_msg
  end

  def check_button
    @check_button
  end

  def update_button
    @update_button
  end

  def upstart_button
    @upstart_button
  end

  def close_button
    @close_button
  end
end

#class ReceView_Dialog_DataBase
class ReceViewGUI::DataBaseDialog < Gtk::Dialog
  attr_accessor :database

  attr_accessor :ok_button
  attr_accessor :cancel_button
  attr_accessor :combox_db
  attr_accessor :tab_db
  attr_accessor :entry_host_dbs
  attr_accessor :entry_user_dbs
  attr_accessor :entry_pass_dbs
  attr_accessor :entry_panda_dbs
  attr_accessor :text_log_dbs
  attr_accessor :check_get_dbfile
  attr_accessor :entry_url_dbfile
  attr_accessor :entry_ca_dbfile
  attr_accessor :text_log_dbfile
  attr_accessor :entry_path_dbfile
  attr_accessor :button_fs_dbfile
  attr_accessor :combox_mode_dbfile
  attr_accessor :test_con_dbfile
  attr_accessor :entry_host_api
  attr_accessor :entry_user_api
  attr_accessor :entry_pass_api
  attr_accessor :check_mode_api
  attr_accessor :entry_ca_api
  attr_accessor :entry_crt_api
  attr_accessor :entry_pem_api
  attr_accessor :entry_phrase_api
  attr_accessor :text_log_api

  def initialize(trans=nil, title="")
    require 'jma/receview/gtk2_fix'
    require 'jma/receview/base'
    require 'jma/receview/dbslib'
    require 'jma/receview/dbfile_lib'
    require 'jma/receview/api'
    @base = ReceView_Base.new
    @path_char = @base.path_char
    @database = false
    @trans = trans

    super()

    gui = ReceViewGUI.new
    @geometry = Gdk::Geometry.new
    @geometry.set_min_width(240)
    @geometry.set_min_height(60)
    @geometry.set_max_width(240)
    @geometry.set_max_height(60)
    @mask = Gdk::Window::HINT_MIN_SIZE | 
           Gdk::Window::HINT_MAX_SIZE | Gdk::Window::HINT_RESIZE_INC
    self.set_title(title)
    self.set_modal(true)            
    self.set_has_separator(false)

    ReceViewGUI::SettingIcon(self)
    ReceViewGUI::TransWindow(self, @trans)

    @ok_button = Gtk::Button.new(Gtk::Stock::OK)
    @cancel_button = Gtk::Button.new(Gtk::Stock::CANCEL)

    @tab_db = Gtk::Notebook.new
    @tab_db.homogeneous = true

    @label_db = Gtk::Label.new("接続方法:")

    # DBS
    @label_host_dbs = Gtk::Label.new("Host:")
    @label_user_dbs = Gtk::Label.new("User:")
    @label_pass_dbs = Gtk::Label.new("Pass:")
    @label_panda_dbs = Gtk::Label.new("panda:")

    @entry_host_dbs = Gtk::Entry.new
    @entry_user_dbs = Gtk::Entry.new
    @entry_pass_dbs = Gtk::Entry.new
    @entry_panda_dbs = Gtk::Entry.new

    @sw_log_dbs = Gtk::ScrolledWindow.new
    @sw_log_dbs.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)

    @text_log_dbs = Gtk::TextView.new
    @box_log_dbs = Gtk::VBox.new(true, 5)

    @sw_log_dbs.add(@text_log_dbs)
    @box_log_dbs.add(@sw_log_dbs)
    @text_log_dbs.editable = false

    @test_con_dbs = Gtk::Button.new("接続テスト")

    @entry_pass_dbs.set_visibility(false)
    @text_log_dbs.buffer.set_text("")
    @text_log_dbs.set_editable(false)

    # DBFile
    @sw_log_dbfile = Gtk::ScrolledWindow.new
    @sw_log_dbfile.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)

    @text_log_dbfile = Gtk::TextView.new
    @box_log_dbfile = Gtk::VBox.new(true, 5)

    @sw_log_dbfile.add(@text_log_dbfile)
    @box_log_dbfile.add(@sw_log_dbfile)
    @text_log_dbfile.editable = false

    @check_get_dbfile = Gtk::CheckButton.new("起動時にサーバからDBFileを取得する")
    @check_get_dbfile.active = false

    @label_url_dbfile = Gtk::Label.new("サーバ:")
    @entry_url_dbfile = Gtk::Entry.new
    @label_ca_dbfile = Gtk::Label.new("CA証明書:")
    @entry_ca_dbfile = Gtk::Entry.new


    @entry_path_dbfile = Gtk::Entry.new
    @button_fs_dbfile = Gtk::Button.new("選択")
    @test_con_dbfile = Gtk::Button.new("接続テスト")

    @label_mode_dbfile = Gtk::Label.new("読み込み方法:")
    @combox_mode_dbfile = Gtk::ComboBox.new
    @base.database["dbfile_mode"].each do |val|
      @combox_mode_dbfile.append_text(val)
    end
    @combox_mode_dbfile.active = 0

    # API
    @label_host_api = Gtk::Label.new("サーバ:")
    @label_user_api = Gtk::Label.new("ユーザ名:")
    @label_pass_api = Gtk::Label.new("パスワード:")

    @check_mode_api = Gtk::CheckButton.new("SSLクライアント認証を使用")
    @check_mode_api.active = false
    @label_ca_api = Gtk::Label.new("CA証明書ファイル:")
    @button_fs_ca = Gtk::Button.new("選択")
    @label_crt_api = Gtk::Label.new("証明書ファイル名(*.crt):")
    @button_fs_crt = Gtk::Button.new("選択")
    @label_pem_api = Gtk::Label.new("秘密鍵ファイル名(*.pem):")
    @button_fs_pem = Gtk::Button.new("選択")
    @label_phrase_api = Gtk::Label.new("秘密鍵パスフレーズ:")

    @entry_host_api = Gtk::Entry.new
    @entry_user_api = Gtk::Entry.new
    @entry_pass_api = Gtk::Entry.new
    @entry_ca_api = Gtk::Entry.new
    @entry_crt_api = Gtk::Entry.new
    @entry_pem_api = Gtk::Entry.new
    @entry_phrase_api = Gtk::Entry.new

    @sw_log_api = Gtk::ScrolledWindow.new
    @sw_log_api.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)

    @text_log_api = Gtk::TextView.new
    @box_log_api = Gtk::VBox.new(true, 5)

    @sw_log_api.add(@text_log_api)
    @box_log_api.add(@sw_log_api)
    @text_log_api.editable = false

    @test_con_api = Gtk::Button.new("接続テスト")

    @entry_pass_api.set_visibility(false)
    @entry_phrase_api.set_visibility(false)
    @text_log_api.buffer.set_text("")
    @text_log_api.set_editable(false)

    @hbox1_dbs = Gtk::HBox.new
    @hbox2_dbs = Gtk::HBox.new
    @hbox3_dbs = Gtk::HBox.new
    @hbox4_dbs = Gtk::HBox.new
    @hbox5_dbs = Gtk::HBox.new
    @hbox6_dbs = Gtk::HBox.new
    @vbox_dbs = Gtk::VBox.new
    @vbox_dummy1 = Gtk::VBox.new

    @hbox1_dbfile = Gtk::HBox.new
    @hbox2_dbfile = Gtk::HBox.new
    @hbox3_dbfile = Gtk::HBox.new
    @hbox4_dbfile = Gtk::HBox.new
    @hbox5_dbfile = Gtk::HBox.new
    @hbox6_dbfile = Gtk::HBox.new
    @hbox7_dbfile = Gtk::HBox.new
    @vbox_dbfile = Gtk::VBox.new
    @vbox_dummy2 = Gtk::VBox.new

    @hbox1_api = Gtk::HBox.new
    @hbox2_api = Gtk::HBox.new
    @hbox3_api = Gtk::HBox.new
    @hbox4_api = Gtk::HBox.new
    @hbox5_api = Gtk::HBox.new
    @hbox6_api = Gtk::HBox.new
    @hbox7_api = Gtk::HBox.new
    @hbox8_api = Gtk::HBox.new
    @hbox9_api = Gtk::HBox.new
    @hbox10_api = Gtk::HBox.new
    @vbox_api = Gtk::VBox.new
    @vbox_dummy3 = Gtk::VBox.new

    @hbox1_dbfile.pack_start(@check_get_dbfile, false, true, 5)
    @hbox2_dbfile.pack_start(@label_url_dbfile, false, true, 5)
    @hbox2_dbfile.pack_start(@entry_url_dbfile, true, true, 5)
    @hbox3_dbfile.pack_start(@label_ca_dbfile, false, true, 5)
    @hbox3_dbfile.pack_start(@entry_ca_dbfile, true, true, 5)
    @hbox4_dbfile.pack_start(@button_fs_dbfile, false, true, 5)
    @hbox4_dbfile.pack_start(@entry_path_dbfile, true, true, 5)
    @hbox5_dbfile.pack_start(@label_mode_dbfile, false, true, 5)
    @hbox5_dbfile.pack_start(@combox_mode_dbfile, false, true, 5)
    @vbox_dummy2.pack_start(@test_con_dbfile, false, true, 5)
    @vbox_dummy2.pack_start(@hbox6_dbfile, true, true, 5)
    @hbox7_dbfile.pack_start(@vbox_dummy2, false, false, 5)
    @hbox7_dbfile.pack_start(@box_log_dbfile, true, true, 5)

    @vbox_dbfile.pack_start(@hbox1_dbfile, false, true, 5)
    @vbox_dbfile.pack_start(@hbox2_dbfile, false, true, 5)
    @vbox_dbfile.pack_start(@hbox3_dbfile, false, true, 5)
    @vbox_dbfile.pack_start(@hbox4_dbfile, false, true, 5)
    @vbox_dbfile.pack_start(@hbox5_dbfile, false, true, 5)
    @vbox_dbfile.pack_start(Gtk::HSeparator.new, false, true, 10)
    @vbox_dbfile.pack_start(@hbox7_dbfile, true, true, 5)

    @hbox1_dbs.pack_start(@label_host_dbs, false, true, 5)
    @hbox1_dbs.pack_start(@entry_host_dbs, true, true, 5)
    @hbox2_dbs.pack_start(@label_user_dbs, false, true, 5)
    @hbox2_dbs.pack_start(@entry_user_dbs, false, true, 5)
    @hbox3_dbs.pack_start(@label_pass_dbs, false, true, 5)
    @hbox3_dbs.pack_start(@entry_pass_dbs, false, true, 5)
    @hbox4_dbs.pack_start(@label_panda_dbs, false, true, 5)
    @hbox4_dbs.pack_start(@entry_panda_dbs, false, true, 5)
    @vbox_dummy1.pack_start(@test_con_dbs, false, true, 5)
    @vbox_dummy1.pack_start(@hbox5_dbs, true, true, 5)
    @hbox6_dbs.pack_start(@vbox_dummy1, false, false, 5)
    @hbox6_dbs.pack_start(@box_log_dbs, true, true, 5)

    @vbox_dbs.pack_start(@hbox1_dbs, false, true, 5)
    @vbox_dbs.pack_start(@hbox2_dbs, false, true, 5)
    @vbox_dbs.pack_start(@hbox3_dbs, false, true, 5)
    @vbox_dbs.pack_start(@hbox4_dbs, false, true, 5)
    @vbox_dbs.pack_start(Gtk::HSeparator.new, false, true, 10)
    @vbox_dbs.pack_start(@hbox6_dbs, true, true, 5)

    @hbox1_api.pack_start(@label_host_api, false, true, 5)
    @hbox1_api.pack_start(@entry_host_api, true, true, 5)
    @hbox2_api.pack_start(@label_user_api, false, true, 5)
    @hbox2_api.pack_start(@entry_user_api, false, true, 5)
    @hbox3_api.pack_start(@label_pass_api, false, true, 5)
    @hbox3_api.pack_start(@entry_pass_api, false, true, 5)
    @hbox4_api.pack_start(@check_mode_api, false, true, 5)
    @hbox5_api.pack_start(@label_ca_api, false, true, 5)
    @hbox5_api.pack_start(@button_fs_ca, false, true, 5)
    @hbox5_api.pack_start(@entry_ca_api, true, true, 5)
    @hbox6_api.pack_start(@label_crt_api, false, true, 5)
    @hbox6_api.pack_start(@button_fs_crt, false, true, 5)
    @hbox6_api.pack_start(@entry_crt_api, true, true, 5)
    @hbox7_api.pack_start(@label_pem_api, false, true, 5)
    @hbox7_api.pack_start(@button_fs_pem, false, true, 5)
    @hbox7_api.pack_start(@entry_pem_api, true, true, 5)
    @hbox8_api.pack_start(@label_phrase_api, false, true, 5)
    @hbox8_api.pack_start(@entry_phrase_api, true, true, 5)
    @vbox_dummy3.pack_start(@test_con_api, false, true, 5)
    @vbox_dummy3.pack_start(@hbox9_api, false, true, 5)
    @hbox10_api.pack_start(@vbox_dummy3, false, false, 5)
    @hbox10_api.pack_start(@box_log_api, true, true, 5)

    @vbox_api.pack_start(@hbox1_api, false, true, 5)
    @vbox_api.pack_start(@hbox2_api, false, true, 5)
    @vbox_api.pack_start(@hbox3_api, false, true, 5)
    @vbox_api.pack_start(@hbox4_api, false, true, 5)
    @vbox_api.pack_start(@hbox5_api, false, true, 5)
    @vbox_api.pack_start(@hbox6_api, false, true, 5)
    @vbox_api.pack_start(@hbox7_api, false, true, 5)
    @vbox_api.pack_start(@hbox8_api, false, true, 5)
    @vbox_api.pack_start(Gtk::HSeparator.new, false, true, 10)
    @vbox_api.pack_start(@hbox10_api, true, true, 5)


    @frame_dbs = Gtk::Frame.new("DBSの接続設定")
    @frame_dbfile = Gtk::Frame.new("DBFileの接続設定")
    @frame_api = Gtk::Frame.new("APIの接続設定")

    @combox_db = Gtk::ComboBox.new
    ["DBS", "DBFile", "API + DBFile"].each do |val| @combox_db.append_text(val) end
    @combox_db.active = 2

    @hbox_db = Gtk::HBox.new
    @hbox_db.pack_start(@label_db, false, false, 5)
    @hbox_db.pack_start(@combox_db, true, true, 5)

    @frame_dbs.add(@vbox_dbs)
    @frame_dbfile.add(@vbox_dbfile)
    @frame_api.add(@vbox_api)

    @hbox_dbs_set = Gtk::HBox.new
    @vbox_dbs_set = Gtk::VBox.new
    @hbox_dbs_set.pack_start(@frame_dbs, true, true, 10)
    @vbox_dbs_set.pack_start(@hbox_dbs_set, true, true, 10)

    @hbox_dbfile_set = Gtk::HBox.new
    @vbox_dbfile_set = Gtk::VBox.new
    @hbox_dbfile_set.pack_start(@frame_dbfile, true, true, 10)
    @vbox_dbfile_set.pack_start(@hbox_dbfile_set, true, true, 10)

    @hbox_api_set = Gtk::HBox.new
    @vbox_api_set = Gtk::VBox.new
    @hbox_api_set.pack_start(@frame_api, true, true, 10)
    @vbox_api_set.pack_start(@hbox_api_set, true, true, 10)

    @tab_db.append_page(@vbox_dbs_set, Gtk::Label.new("DBS"))
    @tab_db.append_page(@vbox_dbfile_set, Gtk::Label.new("DBFile"))
    @tab_db.append_page(@vbox_api_set, Gtk::Label.new("API"))

    self.vbox.pack_start(@hbox_db, false, false, 10)
    self.vbox.pack_start(@tab_db, true, true, 10)

    self.action_area.pack_start(@ok_button)
    self.action_area.pack_start(@cancel_button)

    @accel = Gtk::AccelGroup.new

    self.add_accel_group(@accel)
    self.set_geometry_hints(@ok_button, @geometry, @mask)

    @fs = gui.dialog_fs(self, "DBFileディレクトリ選択", "dir_only")
    @fs_dialog = @fs["dialog"]
    @fs_dialog_ok = @fs["dialog"].ok_button
    @fs_dialog_cancel = @fs["dialog"].cancel_button

    @fs_ca = gui.dialog_fs(self, "CA証明書ファイル選択", "")
    @fs_ca_dialog = @fs_ca["dialog"]
    @fs_ca_dialog_ok = @fs_ca["dialog"].ok_button
    @fs_ca_dialog_cancel = @fs_ca["dialog"].cancel_button

    @fs_crt = gui.dialog_fs(self, "証明書ファイル名(*.crt)選択", "")
    @fs_crt_dialog = @fs_crt["dialog"]
    @fs_crt_dialog_ok = @fs_crt["dialog"].ok_button
    @fs_crt_dialog_cancel = @fs_crt["dialog"].cancel_button

    @fs_pem = gui.dialog_fs(self, "秘密鍵ファイル名(*.pem)選択", "")
    @fs_pem_dialog = @fs_pem["dialog"]
    @fs_pem_dialog_ok = @fs_pem["dialog"].ok_button
    @fs_pem_dialog_cancel = @fs_pem["dialog"].cancel_button

    self.event
  end

  def api_proc
    api_view_proc = Proc.new do ||
      @entry_host_api.set_sensitive(false)
      @entry_user_api.set_sensitive(false)
      @entry_pass_api.set_sensitive(false)
      @check_mode_api.set_sensitive(false)
      @entry_ca_api.set_sensitive(false)
      @button_fs_ca.set_sensitive(false)
      @entry_crt_api.set_sensitive(false)
      @button_fs_crt.set_sensitive(false)
      @entry_pem_api.set_sensitive(false)
      @button_fs_pem.set_sensitive(false)
      @entry_phrase_api.set_sensitive(false)
      @test_con_api.set_sensitive(false)

      text_log = ""
      req = ""
      res = ""

      begin
        h_dbs = @entry_host_api.text
        u_dbs = @entry_user_api.text
        p_dbs = @entry_pass_api.text
        @api = ReceView_API.new(h_dbs, u_dbs, p_dbs)

        if @check_mode_api.active?
          ca_api = @entry_ca_api.text
          c_api = @entry_crt_api.text
          p_api = @entry_pem_api.text
          ph_api = @entry_phrase_api.text
          @api.setting_client_auth(ca_api, c_api, p_api, ph_api)
        end
        req = @api.create_request_insprogetv2()
        res = @api.exec_api(req, "/api01rv2/insprogetv2")
        if REXML::Document === res
          hknjainf = @api.parse_response_insprogetv2(res)
        else
          raise
        end
        if hknjainf["result"][:value].to_i == 10
          text_log += "接続成功"
        else
          text_log += "接続出来ましたが、エラーが発生しました\n"
          text_log += "コード:" + hknjainf["result"][:value] + "\n"
          text_log += "メッセージ:" + hknjainf["message"][:value].toutf8
        end
      rescue Errno::ECONNREFUSED
        text_log += "接続失敗\nホストへの経路を確認してください"
      rescue Timeout::Error
        text_log += "接続がタイムアウトしました。ホストへの経路を確認してください"
      rescue => err
        err_msg = ""
        if Net::HTTPResponse === res
          case res.code
          when "401"
            err_msg += "接続失敗\nサーバへアクセスするには認証が必要です"
          when "403"
            err_msg += "接続失敗\nサーバへアクセスする権限がありません"
          else
            err_msg += "接続失敗\nホストへの経路を確認してください（#{res.message}）\n"
          end
        end
        text_log += (err_msg.empty?)? err.to_s : err_msg
      end

      @text_log_api.buffer.set_text(text_log)

      @entry_host_api.set_sensitive(true)
      @entry_user_api.set_sensitive(true)
      @entry_pass_api.set_sensitive(true)
      @check_mode_api.set_sensitive(true)
      @entry_ca_api.set_sensitive(true)
      @button_fs_ca.set_sensitive(true)
      @entry_crt_api.set_sensitive(true)
      @button_fs_crt.set_sensitive(true)
      @entry_pem_api.set_sensitive(true)
      @button_fs_pem.set_sensitive(true)
      @entry_phrase_api.set_sensitive(true)
      @test_con_api.set_sensitive(true)
    end
  end

  def dbs_proc
    dbs_view_proc = Proc.new do ||
      @entry_host_dbs.set_sensitive(false)
      @entry_user_dbs.set_sensitive(false)
      @entry_pass_dbs.set_sensitive(false)
      @entry_panda_dbs.set_sensitive(false)
      @test_con_dbs.set_sensitive(false)
      @combox_db.set_sensitive(false)

      text_log = ""
      check_num = 0
      hospnum = nil
      ret = ""

      if @entry_panda_dbs.text.to_s.empty?
        @@panda_version = @base.panda_version
        @entry_panda_dbs.set_text(@@panda_version)
      end

      begin 
        db = DBSclient.new(@entry_panda_dbs.text, true)
        h_dbs = @entry_host_dbs.text
        u_dbs = @entry_user_dbs.text
        p_dbs = @entry_pass_dbs.text
        ret = db.con(h_dbs, u_dbs, p_dbs)
      rescue
        ret = db.ex_error
      end

      if ret.empty?
        text_log += @base.db_check_table["test_syskanri"]
        @text_log_dbs.buffer.set_text(text_log)

        # DB Version Get
        db_kanri = {
          :record => "tbl_dbkanri",
          :key    => "all",
          :count  => "10",
          :query  => {
          },
        }
        
        d = []
        begin
          db.transaction do ||
            db.select(db_kanri)
            d = db.fetch(db_kanri)
          end
        rescue
          d = nil
        end

        if d == nil or d.to_s.empty?
          db_version = "DB version get failure"
        else
          db_version = d[0]["VERSION"][:value]
          db_version = @base.db_version.to_s if db_version.to_s.empty?
        end

        db_syskanri = {
          :record => "tbl_syskanri_35",
          :key    => "key_hnum",
          :count  => "20",
          :query  => {
            "hospid" => "%JPN%",
          },
        }

        begin
          db.transaction do ||
            db.select(db_syskanri)
            d = db.fetch(db_syskanri)
          end
        rescue
          d = nil
        end

        if d == nil or d.to_s.empty?
          hospnum = "1"
          check_num+=1
        else
          hospnum = d[0]["hospnum"][:value]
          hospnum.gsub!(/^0/, "").to_s
        end

        text_log += "[hospnum = " + hospnum + "]\n"
        @text_log_dbs.buffer.set_text(text_log)

        date_now = Time.now.strftime("%Y%m") + '01'
        test_srycds = ["111000110","111000370"]
        db_tensu = {
          :record => "tbl_tensu_35",
          :key    => "jrvpkey1",
          :count  => "10",
          :query  => {
            "hospnum" => "1",
            "srycds" => test_srycds,
            "yukostymd" => date_now,
            "yukoedymd" => date_now,
          },
        }

        begin
          db.transaction do ||
            db.select(db_tensu)
            d = db.fetch(db_tensu)
          end
        rescue
          d = nil
        end

        tensu_error = false
        if d != nil or !d.to_s.empty?
          if d.size == test_srycds.size
            d.each_with_index do |sql_data, tensu_index|
              if sql_data["name"][:value].toutf8 == ""
                tensu_error = true
                break
              else
                if tensu_index == 0
                  text_log += @base.db_check_table["test_tensu"]
                  text_log += "\n"
                  # text_log += "[" + sql_data["srycd"][:value]
                  # text_log += " = " + sql_data["name"][:value].toutf8
                  # text_log += "]\n"
                  @text_log_dbs.buffer.set_text(text_log)
                end
              end
            end
          else
            tensu_error = true
          end
        else
          tensu_error = true
        end

        if tensu_error 
          text_log += @base.db_check_table["test_tensu"]
          text_log += "[error]"
          text_log += "\n"
          @text_log_dbs.buffer.set_text(text_log)
          check_num+=2
        end

        test_byomeicds= ["7840024", "4278034"]
        db_byomei = {
          :record => "tbl_byomei",
          :key    => "jrvpkey1",
          :count  => "10",
          :query  => {
            "byomeicds" => test_byomeicds,
          },
        }

        begin
          db.transaction do ||
            db.select(db_byomei)
            d = db.fetch(db_byomei)
          end
        rescue
          d = nil
        end

        byomei_error = false
        if d != nil or !d.to_s.empty?
          if d.size == test_byomeicds.size
            d.each_with_index do |sql_data, byomei_index|
              if sql_data["byomei"][:value].toutf8 == ""
                byomei_error = true
                break
              else
                if byomei_index == 0
                  text_log += @base.db_check_table["test_byomei"]
                  # text_log += "[" + sql_data["byomeicd"][:value]
                  # text_log += " = " + sql_data["byomei"][:value].toutf8
                  # text_log += "]\n"
                  text_log += "\n"
                  @text_log_dbs.buffer.set_text(text_log)
                end
              end
            end
          else
            byomei_error = true
          end
        else
          byomei_error = true
        end

        if byomei_error 
          text_log += @base.db_check_table["test_byomei"]
          text_log += "[error]"
          text_log += "\n"
          @text_log_dbs.buffer.set_text(text_log)
          check_num+=4
        end

        test_labors = ["01101"]
        db_labor = {
          :record => "tbl_labor_sio",
          :key    => "key",
          :count  => "10",
          :query  => {
            "syocd" => test_labors[0],
            "yukostymd" => "20130401",
            "yukoedymd" => "99999999",
          },
        }

        begin
          db.transaction do ||
            db.select(db_labor)
            d = db.fetch(db_labor)
          end
        rescue
          d = nil
        end

        labor_error = false
        if d != nil or !d.to_s.empty?
          if d.size == test_labors.size
            d.each_with_index do |sql_data, labor_index|
              if sql_data["name"][:value].toutf8 == ""
                labor_error = true
                break
              else
                if labor_index == 0
                  text_log += @base.db_check_table["test_labor_sio"]
                  text_log += "\n"
                  @text_log_dbs.buffer.set_text(text_log)
                end
              end
            end
          else
            labor_error = true
          end
        else
          labor_error = true
        end

        if labor_error 
          db_version_int = ("1" + db_version.gsub(/-/, "")).to_i
          if db_version_int >= 10407001
            text_log += @base.db_check_table["test_labor_sio"]
            text_log += "[error]"
            text_log += "\n"
            @text_log_dbs.buffer.set_text(text_log)
            check_num+=8
          else
            text_log += @base.db_check_table["test_labor_sio"]
            text_log += " [N/A]"
            text_log += "\n"
            @text_log_dbs.buffer.set_text(text_log)
          end
        end

        db.close

      elsif ret == "connection" or ret == "timeout"
        check_num = 64
      elsif ret == "version"
        check_num = 256
      elsif ret == "authentication"
        check_num = 512
      else
        check_num = 1024
      end

      out_respons = @base.db_check_table[check_num].to_s
      if !db_version.to_s.empty? and db_version != "DBERROR"
        out_respons = out_respons + " " + "DB:#{db_version}"
      elsif db_version.to_s == "DBERROR"
        out_respons = @base.db_check_table["pt_error"].to_s
      else
        out_respons = out_respons
      end

      text_log += out_respons + "\n"
      @text_log_dbs.buffer.set_text(text_log)

      @entry_host_dbs.set_sensitive(true)
      @entry_user_dbs.set_sensitive(true)
      @entry_pass_dbs.set_sensitive(true)
      @entry_panda_dbs.set_sensitive(true)
      @test_con_dbs.set_sensitive(true)

      @combox_db.set_sensitive(true)
      if check_num == 256
        retry_check = "1.4.3"
        if retry_check != @entry_panda_dbs.text
          @entry_panda_dbs.set_text(retry_check)
          @test_con_dbs.signal_emit("clicked")
        end
      end
    end
    return dbs_view_proc
  end

  def dbfile_proc
    dbfile_view_proc = Proc.new do ||
      @check_get_dbfile.set_sensitive(false)
      @entry_url_dbfile.set_sensitive(false)
      @entry_ca_dbfile.set_sensitive(false)
      @entry_path_dbfile.set_sensitive(false)
      @button_fs_dbfile.set_sensitive(false)
      @test_con_dbfile.set_sensitive(false)
      @combox_mode_dbfile.set_sensitive(false)
      @combox_db.set_sensitive(false)

      text_log = ""
      check_num = 0
      hospnum = nil
      ret = ""
      dbfile_url = ""
      dbfile_server = ""
      files = []
      file_list = %w(SHA1SUMS tbl_byomei.rdb tbl_labor_sio.rdb tbl_tensu.rdb)
      if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
        ret_e_path_dbfile = @entry_path_dbfile.text.tosjis
      else
        ret_e_path_dbfile = @entry_path_dbfile.text
      end
      ret_e_path_dbfile += @path_char if /(\/|\\)+$/ !~ ret_e_path_dbfile

      if @combox_db.active == 2 && @check_get_dbfile.active?
        begin
          dbfile_url = @entry_url_dbfile.text
          dbfile_url += "/" if /\/+$/ !~ dbfile_url
          uri = URI.parse(dbfile_url)
          Net::HTTP.version_1_2
          proxy_host, proxy_port, proxy_user, proxy_pass = nil
          if ENV["http_proxy"]
            proxy_env = URI.parse(ENV["http_proxy"])
            proxy_host, proxy_port = proxy_env.host, proxy_env.port
            if proxy_env.userinfo
              proxy_user, proxy_pass = proxy_env.userinfo.split(":")
            end
          elsif /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
            key = 'Software\Microsoft\Windows\CurrentVersion\Internet Settings'
            Win32::Registry::HKEY_CURRENT_USER.open(key) do |reg|
              if reg["ProxyEnable"] == 1
                proxy_env = URI.parse("http://" + reg["ProxyServer"])
                proxy_host, proxy_port = proxy_env.host, proxy_env.port
              end
            end
          end
          proxy_class = Net::HTTP::Proxy(proxy_host, proxy_port, proxy_user, proxy_pass)
          net_http = proxy_class.new(uri.host, uri.port)
          if uri.scheme == "https"
            net_http.use_ssl = true
            net_http.verify_mode = OpenSSL::SSL::VERIFY_PEER
            if @entry_ca_dbfile.text.empty?
              if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
                net_http.ca_file = '.\etc\cert.pem'
              end
            else
              net_http.ca_file = @entry_ca_dbfile.text
            end
          end
          dbfile_server = net_http.get(uri.path)
          raise if dbfile_server.code !~ /2\d{2}/
          # 接続テストでは起動時の挙動とは違いチェックサムファイルをダウンロードするが、
          # ローカルに保存されたDBFileのSHA1ハッシュとの比較はせず、DBFileをダウンロードする
          file_list.each do |file|
            local_file = ret_e_path_dbfile + file
            smime = net_http.get(uri.path + file + ".p7m")
            raise unless smime.code =~ /2\d{2}/
            p7 = OpenSSL::PKCS7.read_smime(smime.body)
            store = OpenSSL::X509::Store.new
            if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
              sign_verify = '.\etc\orca-project-ca-2.crt'
            else
              sign_verify = "/etc/ssl/certs/orca-project-ca-2.crt"
            end
            store.add_file(sign_verify)
            raise OpenSSL::PKCS7::PKCS7Error unless p7.verify(p7.certificates, store)
            if file == "SHA1SUMS"
              checksum = YAML.load(p7.data)
              text_log += "#{dbfile_url} : #{dbfile_server.message}\n"
            else
              open(local_file, 'wb+') { |output| output.write(p7.data) }
            end
            files << file
            text_log += "#{file} : OK\n"
          end
          text_log += @base.db_check_table["found_dbfile"]
          @text_log_dbfile.buffer.set_text(text_log)
        rescue Net::HTTPFatalError        # プロキシ経由でサーバURLが間違いの場合
          text_log += @base.db_check_table["not_found_error"]
        rescue SocketError        # サーバまたはプロキシサーバのURLが正しくない場合
          text_log += @base.db_check_table["not_found_error"]
        rescue Net::HTTPServerException => e        # プロキシサーバは存在するがユーザ認証等で失敗した場合
          if e.message.include?("407")
            text_log += @base.db_check_table["proxy_user_error"]
          else
            text_log += e.message
          end
        rescue Errno::ETIMEDOUT        # プロキシサーバのポートの違い等によりタイムアウトになった場合
          text_log += @base.db_check_table["proxy_url_error"]
        rescue OpenSSL::SSL::SSLError => e        # DBFile取得先のサーバの証明書のエラー
          text_log += e.message
        rescue OpenSSL::X509::StoreError        # DBFileの署名検証の際に存在しない証明書を読み込んだ場合
          text_log += @base.db_check_table["store_error"]
        rescue OpenSSL::PKCS7::PKCS7Error        # DBFileの署名検証に失敗した場合
          text_log += @base.db_check_table["verify_error"]
        rescue Errno::EACCES => e        # DBFileの保存先の書き込み権限がない場合
          text_log += e.message
        rescue Errno::ENOENT        # DBFileの保存先ディレクトリが存在しない場合
          text_log += @base.db_check_table["storage_error"]
        rescue => e
          err_msg = ""
          # DBFile取得先のサーバの設定が正しくない場合（DBFileの存在チェックはしない）
          if dbfile_server != "" && dbfile_server.code !~ /2\d{2}/
            err_msg += "#{dbfile_url} : #{dbfile_server.message}\n"
          end
          unless file_list == files          # DBFile取得先のサーバのURLにDBFileが存在しなかった場合
            (file_list - files).each { |file| err_msg += "#{file} : Not Found\n" }
            err_msg += @base.db_check_table["not_found_error"]
          end
          if err_msg.empty?
            text_log += e.message
          else
            text_log += err_msg
          end
        end
        text_log = text_log.chomp + "\n\n"
        @text_log_dbfile.buffer.set_text(text_log)
      end

      begin
        db = ReceView_DBFile.new
        if @combox_db.active == 2
          %w(tbl_hknjainf tbl_syskanri tbl_dbkanri).each do |table|
            db.tbl_list.delete(table)
            db.column.delete(table)
          end
        end
        if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
          ret = db.con(ret_e_path_dbfile.tosjis)
        else
          ret = db.con(ret_e_path_dbfile)
        end
      rescue
        ret = db.ex_error
      end

      if ret.to_s.empty?

        db.make_db

        text_log += @base.db_check_table["test_tbls"]
        text_log += "\n"
        db.tbl_list.each do |tbl|
          text_log += "  #{tbl}\n"
          @text_log_dbfile.buffer.set_text(text_log)
        end
        text_log += "\n"
        sleep 0.01

        unless @combox_db.active == 2
          text_log += @base.db_check_table["test_syskanri"]
          @text_log_dbfile.buffer.set_text(text_log)

          # DB Version Get
          db_kanri = {
            :record => "tbl_dbkanri",
            :key    => "all",
            :count  => "10",
            :query  => {
            },
          }

          d = []
          begin
            db.transaction do ||
              db.select(db_kanri)
              d = db.fetch(db_kanri)
            end
          rescue
            d = nil
          end

          if d == nil
            db_version = "DB version get failure"
          else
            db_version = d[0]["version"][:value]
            db_version = @base.db_version.to_s if db_version.to_s.empty?
          end

          db_syskanri = {
            :record => "tbl_syskanri_35",
            :key    => "key_hnum",
            :count  => "20",
            :query  => {
              "hospid" => "%JPN%",
            },
          }

          begin
            db.transaction do ||
              db.select(db_syskanri)
              d = db.fetch(db_syskanri)
            end
          rescue
            d = nil
          end

          if d == nil
            hospnum = "1"
            check_num+=1
          else
            hospnum = d[0]["hospnum"][:value]
            hospnum.gsub!(/^0/, "").to_s
          end

          text_log += "[hospnum = " + hospnum + "]\n"
          @text_log_dbfile.buffer.set_text(text_log)
        end

        date_now = Time.now.strftime("%Y%m") + '01'
        test_srycds = ["111000110","111000370"]
        db_tensu = {
          :record => "tbl_tensu_35",
          :key    => "jrvpkey1",
          :count  => "10",
          :query  => {
            "hospnum" => "1",
            "srycds" => test_srycds,
            "yukostymd" => date_now,
            "yukoedymd" => date_now,
          },
        }

        begin
          db.transaction do ||
            db.select(db_tensu)
            d = db.fetch(db_tensu)
          end
        rescue
          d = nil
        end

        tensu_error = false
        if d != nil
          if d.size == test_srycds.size
            d.each_with_index do |sql_data, tensu_index|
              if sql_data["name"][:value].toutf8 == ""
                tensu_error = true
                break
              else
                if tensu_index == 0
                  text_log += @base.db_check_table["test_tensu"]
                  # text_log += "[" + sql_data["srycd"][:value]
                  # text_log += " = " + sql_data["name"][:value].toutf8
                  # text_log += "]\n"
                  text_log += "\n"
                  @text_log_dbfile.buffer.set_text(text_log)
                end
              end
            end
          else
            tensu_error = true
          end
        else
          tensu_error = true
        end

        if tensu_error 
          text_log += @base.db_check_table["test_tensu"]
          text_log += "[error]"
          text_log += "\n"
          @text_log_dbfile.buffer.set_text(text_log)
          check_num+=2
        end

        test_byomeicds= ["7840024", "4278034"]
        db_byomei = {
          :record => "tbl_byomei",
          :key    => "jrvpkey1",
          :count  => "10",
          :query  => {
            "byomeicds" => test_byomeicds,
          },
        }

        begin
          db.transaction do ||
            db.select(db_byomei)
            d = db.fetch(db_byomei)
          end
        rescue
          d = nil
        end

        byomei_error = false
        if d != nil
          if d.size == test_byomeicds.size
            d.each_with_index do |sql_data, byomei_index|
              if sql_data["byomei"][:value].toutf8 == ""
                byomei_error = true
                break
              else
                if byomei_index == 0
                  text_log += @base.db_check_table["test_byomei"]
                  # text_log += "[" + sql_data["byomeicd"][:value]
                  # text_log += " = " + sql_data["byomei"][:value].toutf8
                  # text_log += "]\n"
                  text_log += "\n"
                  @text_log_dbfile.buffer.set_text(text_log)
                end
              end
            end
          else
            byomei_error = true
          end
        else
          byomei_error = true
        end

        if byomei_error 
          text_log += @base.db_check_table["test_byomei"]
          text_log += "[error]"
          text_log += "\n"
          @text_log_dbfile.buffer.set_text(text_log)
          check_num+=4
        end

        test_labors = ["01101"]
        db_labor = {
          :record => "tbl_labor_sio",
          :key    => "key",
          :count  => "10",
          :query  => {
            "syocd" => test_labors[0],
            "yukostymd" => "20130401",
            "yukoedymd" => "99999999",
          },
        }

        begin
          db.transaction do ||
            db.select(db_labor)
            d = db.fetch(db_labor)
          end
        rescue
          d = nil
        end

        labor_error = false
        if d != nil or !d.to_s.empty?
          if d.size == test_labors.size
            d.each_with_index do |sql_data, labor_index|
              if sql_data["name"][:value].nil? == false
                if sql_data["name"][:value].toutf8 == ""
                  labor_error = true
                  break
                else
                  if labor_index == 0
                    text_log += @base.db_check_table["test_labor_sio"]
                    text_log += "\n"
                    @text_log_dbfile.buffer.set_text(text_log)
                  end
                end
              else
                labor_error = true
                break
              end
            end
          else
            labor_error = true
          end
        else
          labor_error = true
        end

        if labor_error 
          text_log += @base.db_check_table["test_labor_sio"]
          text_log += "[error]"
          text_log += "\n"
          @text_log_dbfile.buffer.set_text(text_log)
          check_num+=8
        end

        db.close
      else
        db.all_error.each do |error|
          error_point = ""
          if error == "connection"
            check_num = 2048
          elsif /(File not found: )(\S+)/ =~ error
            check_num = 4096
            error_point = $2
          elsif /(Permission denied: )(\S+)/ =~ error
            check_num = 8192
            error_point = $2
          else
            check_num = 1024
          end
          text_log += @base.db_check_table[check_num].to_s +
            " [" + error_point + "]\n"
        end
        @text_log_dbfile.buffer.set_text(text_log)
      end

      out_respons = @base.db_check_table[check_num].to_s
      if !db_version.to_s.empty? and db_version != "DBERROR"
        @entry_path_dbfile.set_text(db.dir_path.toutf8)
        out_respons = out_respons + " " + "DB:#{db_version}"
      elsif db_version.to_s == "DBERROR"
        out_respons = @base.db_check_table["pt_error"].to_s
      else
        @entry_path_dbfile.set_text(db.dir_path.toutf8)
        out_respons = ""
      end

      text_log += out_respons + "\n"
      @text_log_dbfile.buffer.set_text(text_log)

      if check_num == 0
        msg = @base.message_dbfile
        msg_b = msg["day"]
        msg_n = msg["number"]
        dbfile_slist = "#{msg_b}: #{db.ymd.to_s}\n"
        db.dbfile.each do |key, val|
          if val.class == String
            dbfile_slist += "#{key.to_s}: "
            dbfile_slist += "#{val.split(/\n/).size.to_s + msg_n}\n"
          end
        end
        text_log += "\n" + dbfile_slist
        @database = db
      else
        @database = false
      end

      @text_log_dbfile.buffer.set_text(text_log)

      if @combox_db.active == 2
        @check_get_dbfile.set_sensitive(true)
        @entry_url_dbfile.set_sensitive(true)
        @entry_ca_dbfile.set_sensitive(true)
      end
      @entry_path_dbfile.set_sensitive(true)
      @button_fs_dbfile.set_sensitive(true)
      @test_con_dbfile.set_sensitive(true)
      @combox_mode_dbfile.set_sensitive(true)

      @combox_db.set_sensitive(true)
    end
    return dbfile_view_proc
  end

  def event
    @fs_dialog_ok.signal_connect("clicked") do
      dbfile_path = @fs_dialog.filename
      dbfile_path += @path_char if /(\/|\\)$/ !~ dbfile_path
      @entry_path_dbfile.set_text(dbfile_path)
      @fs_dialog.hide
    end

    @fs_dialog_cancel.signal_connect("clicked") do
      @fs_dialog.hide
    end

    @fs_ca_dialog_ok.signal_connect("clicked") do
      ca_path = @fs_ca_dialog.filename
      @entry_ca_api.set_text(ca_path)
      @fs_ca_dialog.hide
    end

    @fs_ca_dialog_cancel.signal_connect("clicked") do
      @fs_ca_dialog.hide
    end

    @fs_crt_dialog_ok.signal_connect("clicked") do
      crt_path = @fs_crt_dialog.filename
      @entry_crt_api.set_text(crt_path)
      @fs_crt_dialog.hide
    end

    @fs_crt_dialog_cancel.signal_connect("clicked") do
      @fs_crt_dialog.hide
    end

    @fs_pem_dialog_ok.signal_connect("clicked") do
      pem_path = @fs_pem_dialog.filename
      @entry_pem_api.set_text(pem_path)
      @fs_pem_dialog.hide
    end

    @fs_pem_dialog_cancel.signal_connect("clicked") do
      @fs_pem_dialog.hide
    end

    @combox_db.signal_connect("changed") do
      if Gtk::platform_support_os_bionic
        if @combox_db.active == 0
          @combox_db.set_active(2)
        end
      end

      if Gtk::platform_support_os_bionic == false
        if @combox_db.active == 0
          @label_host_dbs.set_sensitive(true)
          @label_user_dbs.set_sensitive(true)
          @label_pass_dbs.set_sensitive(true)
          @label_panda_dbs.set_sensitive(true)
          @entry_host_dbs.set_sensitive(true)
          @entry_user_dbs.set_sensitive(true)
          @entry_pass_dbs.set_sensitive(true)
          @entry_panda_dbs.set_sensitive(true)
          @text_log_dbs.set_sensitive(true)
          @test_con_dbs.set_sensitive(true)

          @text_log_dbfile.set_sensitive(false)
          @check_get_dbfile.set_sensitive(false)
          @label_url_dbfile.set_sensitive(false)
          @entry_url_dbfile.set_sensitive(false)
          @label_ca_dbfile.set_sensitive(false)
          @entry_ca_dbfile.set_sensitive(false)
          @entry_path_dbfile.set_sensitive(false)
          @button_fs_dbfile.set_sensitive(false)
          @test_con_dbfile.set_sensitive(false)
          @label_mode_dbfile.set_sensitive(false)
          @combox_mode_dbfile.set_sensitive(false)

          @label_host_api.set_sensitive(false)
          @label_user_api.set_sensitive(false)
          @label_pass_api.set_sensitive(false)
          @label_ca_api.set_sensitive(false)
          @button_fs_ca.set_sensitive(false)
          @label_crt_api.set_sensitive(false)
          @button_fs_crt.set_sensitive(false)
          @label_pem_api.set_sensitive(false)
          @button_fs_pem.set_sensitive(false)
          @label_phrase_api.set_sensitive(false)
          @entry_host_api.set_sensitive(false)
          @check_mode_api.set_sensitive(false)
          @entry_user_api.set_sensitive(false)
          @entry_pass_api.set_sensitive(false)
          @entry_ca_api.set_sensitive(false)
          @entry_crt_api.set_sensitive(false)
          @entry_pem_api.set_sensitive(false)
          @entry_phrase_api.set_sensitive(false)
          @text_log_api.set_sensitive(false)
          @test_con_api.set_sensitive(false)
          @tab_db.set_page(0)
        end
      end

      if @combox_db.active == 1
        @label_host_dbs.set_sensitive(false)
        @label_user_dbs.set_sensitive(false)
        @label_pass_dbs.set_sensitive(false)
        @label_panda_dbs.set_sensitive(false)
        @entry_host_dbs.set_sensitive(false)
        @entry_user_dbs.set_sensitive(false)
        @entry_pass_dbs.set_sensitive(false)
        @entry_panda_dbs.set_sensitive(false)
        @text_log_dbs.set_sensitive(false)
        @test_con_dbs.set_sensitive(false)

        @text_log_dbfile.set_sensitive(true)
        @check_get_dbfile.set_sensitive(false)
        @label_url_dbfile.set_sensitive(false)
        @entry_url_dbfile.set_sensitive(false)
        @label_ca_dbfile.set_sensitive(false)
        @entry_ca_dbfile.set_sensitive(false)
        @entry_path_dbfile.set_sensitive(true)
        @button_fs_dbfile.set_sensitive(true)
        @test_con_dbfile.set_sensitive(true)
        @label_mode_dbfile.set_sensitive(true)
        @combox_mode_dbfile.set_sensitive(true)

        @label_host_api.set_sensitive(false)
        @label_user_api.set_sensitive(false)
        @label_pass_api.set_sensitive(false)
        @label_ca_api.set_sensitive(false)
        @button_fs_ca.set_sensitive(false)
        @label_crt_api.set_sensitive(false)
        @button_fs_crt.set_sensitive(false)
        @label_pem_api.set_sensitive(false)
        @button_fs_pem.set_sensitive(false)
        @label_phrase_api.set_sensitive(false)
        @entry_host_api.set_sensitive(false)
        @check_mode_api.set_sensitive(false)
        @entry_user_api.set_sensitive(false)
        @entry_pass_api.set_sensitive(false)
        @entry_ca_api.set_sensitive(false)
        @entry_crt_api.set_sensitive(false)
        @entry_pem_api.set_sensitive(false)
        @entry_phrase_api.set_sensitive(false)
        @text_log_api.set_sensitive(false)
        @test_con_api.set_sensitive(false)
        @tab_db.set_page(1)
      elsif @combox_db.active == 2
        @label_host_dbs.set_sensitive(false)
        @label_user_dbs.set_sensitive(false)
        @label_pass_dbs.set_sensitive(false)
        @label_panda_dbs.set_sensitive(false)
        @entry_host_dbs.set_sensitive(false)
        @entry_user_dbs.set_sensitive(false)
        @entry_pass_dbs.set_sensitive(false)
        @entry_panda_dbs.set_sensitive(false)
        @text_log_dbs.set_sensitive(false)
        @test_con_dbs.set_sensitive(false)

        @text_log_dbfile.set_sensitive(true)
        @check_get_dbfile.set_sensitive(true)
        @label_url_dbfile.set_sensitive(true)
        @entry_url_dbfile.set_sensitive(true)
        @label_ca_dbfile.set_sensitive(true)
        @entry_ca_dbfile.set_sensitive(true)
        @entry_path_dbfile.set_sensitive(true)
        @button_fs_dbfile.set_sensitive(true)
        @test_con_dbfile.set_sensitive(true)
        @label_mode_dbfile.set_sensitive(true)
        @combox_mode_dbfile.set_sensitive(true)

        @label_host_api.set_sensitive(true)
        @label_user_api.set_sensitive(true)
        @label_pass_api.set_sensitive(true)
        @label_ca_api.set_sensitive(true)
        @button_fs_ca.set_sensitive(true)
        @label_crt_api.set_sensitive(true)
        @button_fs_crt.set_sensitive(true)
        @label_pem_api.set_sensitive(true)
        @button_fs_pem.set_sensitive(true)
        @label_phrase_api.set_sensitive(true)
        @entry_host_api.set_sensitive(true)
        @check_mode_api.set_sensitive(true)
        @entry_user_api.set_sensitive(true)
        @entry_pass_api.set_sensitive(true)
        @entry_ca_api.set_sensitive(true)
        @entry_crt_api.set_sensitive(true)
        @entry_pem_api.set_sensitive(true)
        @entry_phrase_api.set_sensitive(true)
        @text_log_api.set_sensitive(true)
        @test_con_api.set_sensitive(true)
        @tab_db.set_page(2)
      end
    end

    @button_fs_dbfile.signal_connect("clicked") do
      if File.exist?(@entry_path_dbfile.text)
        @fs_dialog.complete(@entry_path_dbfile.text)
      end
      @fs_dialog.set_filename("")
      if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
        self.hide
        @trans.hide
        shell_obj = WIN32OLE.new("shell.application")
        msg = @base.message_dbfile["select_title"].tosjis
        bit = 0
        root_dir = ""
        shell_dir = shell_obj.browseForFolder(0, msg, bit, root_dir)
        if shell_dir == nil
          @fs_dialog_cancel.signal_emit("clicked")
        else
          @fs_dialog.set_filename(shell_dir.Items.Item.path.to_s.gsub(/\\|\//, @path_char).toutf8)
          @fs_dialog_ok.signal_emit("clicked")
        end
        @trans.show
        self.show
      else
        @fs_dialog.file_list.parent.hide
        @fs_dialog.show
      end
    end

    @button_fs_ca.signal_connect("clicked") do
      if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
        ca_path = @entry_ca_api.text.gsub(/\\/, '/').tosjis
      else
        ca_path = @entry_ca_api.text
      end
      if File.exist?(ca_path)
        @fs_ca_dialog.complete(@entry_ca_api.text.toutf8)
      else
        @fs_ca_dialog.set_filename("")
      end
      @fs_ca_dialog.show
    end

    @button_fs_crt.signal_connect("clicked") do
      if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
        crt_path = @entry_crt_api.text.gsub(/\\/, '/').tosjis
      else
        crt_path = @entry_crt_api.text
      end
      if File.exist?(crt_path)
        @fs_crt_dialog.complete(@entry_crt_api.text.toutf8)
      else
        @fs_crt_dialog.set_filename("")
      end
      @fs_crt_dialog.show
    end

    @button_fs_pem.signal_connect("clicked") do
      if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
        pem_path = @entry_pem_api.text.gsub(/\\/, '/').tosjis
      else
        pem_path = @entry_pem_api.text
      end
      if File.exist?(pem_path)
        @fs_pem_dialog.complete(@entry_pem_api.text.toutf8)
      else
        @fs_pem_dialog.set_filename("")
      end
      @fs_pem_dialog.show
    end

    # 接続テスト dbs
    @test_con_dbs.signal_connect("clicked") do
      text_log = @base.db_check_table["test"] + "\n"
      @text_log_dbs.buffer.set_text(text_log)

      Thread.os do
        self.dbs_proc.call
      end
    end

    # 接続テスト dbfile
    @test_con_dbfile.signal_connect("clicked") do
      text_log = @base.db_check_table["test"] + "\n"
      @text_log_dbfile.buffer.set_text(text_log)

      Gtk.queue do
        self.dbfile_proc.call
      end
    end

    # 接続テスト api
    @test_con_api.signal_connect("clicked") do
      text_log = @base.db_check_table["test"] + "\n"
      @text_log_api.buffer.set_text(text_log)

      Thread.os do
        self.api_proc.call
      end
    end
  end
end

class ReceViewHelpDialog < Gtk::AboutDialog
  def initialize(main_window)
    require 'jma/receview/base'
    @base = ReceView_Base.new
    about = @base.about
    super()

    @windows_shell = nil
    @close_button = self.children[0].children[1].children[2]

    self.icon_init
    self.accel_setting
    self.event
    ReceViewGUI::TransWindow(self, main_window)

    self.replace_pg_name
    self.artists = [about["artists"]]
    self.version   = ReceViewVersion.Text
    self.name      = about["name"].to_s
    self.comments  = about["comments"].to_s
    self.copyright = about["copyright"].to_s
    self.license   = about["license"].to_s
    self.website   = about["website"].to_s
    self.website_label = about["website_label"].to_s
    self
  end

  def windows_shell(shell)
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      @windows_shell = shell
    end
  end

  def get_gtk_version
    gtk_version = 0
    [ Gtk::BINDING_VERSION[0].to_i * 10000,
      Gtk::BINDING_VERSION[1].to_i * 100,
      Gtk::BINDING_VERSION[2].to_i,
    ].each { |v| gtk_version +=v } 

    return gtk_version
  end

  def replace_pg_name
    gtk_version = self.get_gtk_version
    if gtk_version >= 1600
      self.program_name = ReceViewVersion.Program_Name
    end
  end

  def icon_init
    @base.icon.each do |file|
      if File.exist?(file)
        self.logo = Gdk::Pixbuf.new(file)
        self.icon = Gdk::Pixbuf.new(file)
        break
      end
    end
  end

  def accel_setting(accel=nil)
    accel = Gtk::AccelGroup.new if accel.nil?
    accel.connect(Gdk::Keyval::GDK_C, Gdk::Window::CONTROL_MASK, Gtk::ACCEL_VISIBLE) do
        @close_button.signal_emit("clicked")
    end
    self.add_accel_group(accel)
  end

  def event
    Gtk::AboutDialog.set_url_hook {|fake, link|
      if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
        @windows_shell.Run("EXPLORER.EXE #{link}") if not @windows_shell.nil?
      else
        system("/usr/bin/gnome-open #{link}")
      end
      fake = nil
    }

    @close_button.signal_connect("clicked") do
      self.destroy
    end

    self.signal_connect("delete_event") do
      self.destroy
      false
    end
  end
end

class ReceViewColor
  RECAL_OK_COLOR = Gdk::Color.new(60000, 60000, 65000)
  RECAL_ERROR_COLOR1 = Gdk::Color.new(65535, 54000, 0)
  RECAL_ERROR_COLOR2 = Gdk::Color.new(60000, 40000, 40000)
  RECAL_ERROR_COLOR3 = Gdk::Color.new(65535, 54000, 50000)

  SANTEI_DAY_COLOR1 = Gdk::Color.new(60000, 53000, 65000)
  SANTEI_DAY_COLOR2 = Gdk::Color.new(63000, 56000, 65000)

  FIND_COLOR1 = Gdk::Color.new(60000, 60000, 65000)

  TREE_IR_COLOR1 = Gdk::Color.new(50000, 50000, 65000)
  TREE_IR_COLOR2 = Gdk::Color.new(45500, 55000, 65000)
  TREE_IR_COLOR3 = Gdk::Color.new(60000, 54000, 60000)
  TREE_IR_COLOR4 = Gdk::Color.new(60000, 60000, 65000)
  TREE_IR_COLOR5 = Gdk::Color.new(65000, 60000, 60000)

  TREE_HI_COLOR1 = Gdk::Color.new(65000, 63000, 63000)

  TREE_HOKEN_COLOR1 = Gdk::Color.new(55000, 65500, 45000)
  TREE_HOKEN_COLOR2 = Gdk::Color.new(60000, 60000, 65000)

  TREE_EDITSICK_COLOR1 = Gdk::Color.new(60000, 30000, 30000)
end

# Test Code
if __FILE__ == $0
  def wait_test
    loop do
      sleep 1.0
      p "sleep"
    end
  end

  case ARGV[0].to_s
  when "database"
    gui_db = ReceViewGUI::DataBaseDialog.new("接続設定")
    dialog = gui_db
    host_dbs = gui_db.entry_host_dbs
    user_dbs = gui_db.entry_user_dbs
    pass_dbs = gui_db.entry_pass_dbs
    panda_dbs = gui_db.entry_panda_dbs
    path_dbfile = gui_db.entry_path_dbfile

    host_dbs.set_text("localhost")
    user_dbs.set_text("ormaster")
    pass_dbs.set_text("ormaster")
    panda_dbs.set_text("1.4.3")
    path_dbfile.set_text("db/")

    dialog.show_all
    Gtk.main_with_queue(100)
  when "fs"
    @gui = ReceViewGUI.new
    d_fs = @gui.dialog_fs(nil, "test", "dir_only")
    dialog = d_fs["dialog"]
    file_list = d_fs["file_list"]
    dialog.show
    file_list.signal_connect("cursor-changed") do
      p "file"
    end
    Gtk.main_with_queue(100)
  when "etc_setting"
    @gui = ReceViewGUI.new
    w = Gtk::Window.new
    b = Gtk::Button.new("dialog_etc_setting")
    w.add(b)

    o = @gui.dialog_etc_setting(w)
    dialog = o["dialog"]
    ok_button = o["ok_button"]
    dir_combox = o["dir.combox"]
    dir_entry = o["dir.entry"]
    dir_entry_box = o["dir.entry_box"]
    dir_select_dialog = o["dir.select_dialog"]
    fs_combox = o["fs.combox"]
    w.show_all

    b.signal_connect("clicked") do
      file = "/tmp"
      file_history_status = 0
      dir_select_dialog.set_filename(file)
      dir_entry.set_text(file)
      dir_combox.active = 0
      fs_combox.active = 0

      dialog.show_all
      dir_entry_box.hide if file_history_status != 2
    end

    ok_button.signal_connect("clicked") do
      p "ok"
    end

    dir_combox.signal_connect("changed") do
      case dir_combox.active.to_i
      when 2
        dir_entry_box.show
      else
        dir_entry_box.hide
      end
    end
    Gtk.main_with_queue(100)
  when "search", "find"
    search = ReceViewSearch.new
    search.show_all
    Gtk.main_with_queue(100)
  when "tool"
    gui = ReceViewGUI.new
    gui.init_gtk_stock
    tool = ReceViewGUI::ToolBox.new
    tool.show_all
    Gtk.main_with_queue(100)
  end

  print "ruby #{$0} ARGV\n"
  print "ARGVs => database, fs, etc_setting, search(find), tool\n"
  print "ex test $ ruby #{$0} database\n"
end
