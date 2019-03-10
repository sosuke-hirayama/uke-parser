# -*- encoding: utf-8 -*-
#
require 'jma/receview/generation'

unless defined?(ReceViewGUI)
  begin
    require 'jma/receview/gtk2_fix'
    require 'jma/receview/gui'
  rescue LoadError
    require 'gtk2_fix'
    require 'gui'
  end
end

class ReceViewGUI::KeyBind
  def initialize(accel, gui)
    raise if not accel.class == Gtk::AccelGroup
    raise if not gui.class == ReceViewGUI

    # execProc
    @preview_proc = nil

    @accel = accel
    @gui = gui

    # TextView Tags
    @gui.all_code["tags"] = []
    @gui.all_code["tags_pos"] = 0

    self.key_event
  end

  def set_preview_proc(proc_block)
    @preview_proc = proc_block
  end

  def key_event
    self.key_binding
  end

  def key_binding
    @accel.connect(Gdk::Keyval::GDK_1, Gdk::Window::MOD1_MASK, Gtk::ACCEL_VISIBLE) do
      @gui.main_tab.set_page(0)
    end

    @accel.connect(Gdk::Keyval::GDK_2, Gdk::Window::MOD1_MASK, Gtk::ACCEL_VISIBLE) do
      @gui.main_tab.set_page(1)
    end

    @accel.connect(Gdk::Keyval::GDK_3, Gdk::Window::MOD1_MASK, Gtk::ACCEL_VISIBLE) do
      @gui.main_tab.set_page(2)
    end

    @accel.connect(Gdk::Keyval::GDK_4, Gdk::Window::MOD1_MASK, Gtk::ACCEL_VISIBLE) do
      @gui.main_tab.set_page(1)
      @gui.user_tab.set_page(0)
    end

    @accel.connect(Gdk::Keyval::GDK_5, Gdk::Window::MOD1_MASK, Gtk::ACCEL_VISIBLE) do
      @gui.main_tab.set_page(1)
      @gui.user_tab.set_page(1)
    end
    
    @accel.connect(Gdk::Keyval::GDK_6, Gdk::Window::MOD1_MASK, Gtk::ACCEL_VISIBLE) do
      @gui.main_tab.set_page(1)
      @gui.user_tab.set_page(2)
    end

    @accel.connect(Gdk::Keyval::GDK_7, Gdk::Window::MOD1_MASK, Gtk::ACCEL_VISIBLE) do
      @gui.main_tab.set_page(1)
      @gui.user_tab.set_page(3)
    end

    @accel.connect(Gdk::Keyval::GDK_Return, Gdk::Window::MOD1_MASK, Gtk::ACCEL_VISIBLE) do
      tree_select_line
    end

    @accel.connect(Gdk::Keyval::GDK_j, Gdk::Window::MOD1_MASK, Gtk::ACCEL_VISIBLE) do
      tree_forward_line
    end

    @accel.connect(Gdk::Keyval::GDK_k, Gdk::Window::MOD1_MASK, Gtk::ACCEL_VISIBLE) do
      tree_backward_line
    end

    @accel.connect(Gdk::Keyval::GDK_h, Gdk::Window::MOD1_MASK, Gtk::ACCEL_VISIBLE) do
      tab_backward_page
    end

    @accel.connect(Gdk::Keyval::GDK_l, Gdk::Window::MOD1_MASK, Gtk::ACCEL_VISIBLE) do
      tab_forward_page
    end

    # TextView Start
    @accel.connect(Gdk::Keyval::GDK_0, nil, Gtk::ACCEL_VISIBLE) do
      textview_forward_start
    end

    @accel.connect(Gdk::Keyval::GDK_g, Gdk::Window::SHIFT_MASK, Gtk::ACCEL_VISIBLE) do
      textview_forward_end
    end

    @accel.connect(Gdk::Keyval::GDK_f, nil, Gtk::ACCEL_VISIBLE) do
      textview_forward_page
    end

    @accel.connect(Gdk::Keyval::GDK_space, nil, Gtk::ACCEL_VISIBLE) do
      textview_forward_page
    end

    @accel.connect(Gdk::Keyval::GDK_space, Gdk::Window::SHIFT_MASK, Gtk::ACCEL_VISIBLE) do
      textview_backward_page
    end

    @accel.connect(Gdk::Keyval::GDK_b, nil, Gtk::ACCEL_VISIBLE) do
      textview_backward_page
    end

    @accel.connect(Gdk::Keyval::GDK_j, nil, Gtk::ACCEL_VISIBLE) do
      textview_forward_line
    end

    @accel.connect(Gdk::Keyval::GDK_k, nil, Gtk::ACCEL_VISIBLE) do 
      textview_backward_line
    end

    @accel.connect(Gdk::Keyval::GDK_h, nil, Gtk::ACCEL_VISIBLE) do
      textview_leftward
    end

    @accel.connect(Gdk::Keyval::GDK_l, nil, Gtk::ACCEL_VISIBLE) do
      textview_rightward
    end

    @accel.connect(Gdk::Keyval::GDK_n, nil, Gtk::ACCEL_VISIBLE) do
      textview_search_forward
    end

    @accel.connect(Gdk::Keyval::GDK_n, Gdk::Window::SHIFT_MASK, Gtk::ACCEL_VISIBLE) do
      textview_search_backward
    end

    @accel.connect(Gdk::Keyval::GDK_slash, nil, Gtk::ACCEL_VISIBLE) do
      textview_search_function
    end

    @accel.connect(Gdk::Keyval::GDK_Escape, nil, Gtk::ACCEL_VISIBLE) do
      textview_search_function_move
    end
    # TextView End

    # preview
    @accel.connect(Gdk::Keyval::GDK_plus, nil, Gtk::ACCEL_VISIBLE) do
      if @gui.user_tab.page == 2
        @gui.preview_object["preview.button.up"].signal_emit("clicked")
      end
    end

    @accel.connect(Gdk::Keyval::GDK_minus, nil, Gtk::ACCEL_VISIBLE) do
      if @gui.user_tab.page == 2
        @gui.preview_object["preview.button.down"].signal_emit("clicked")
      end
    end

    @accel.connect(Gdk::Keyval::GDK_equal, nil, Gtk::ACCEL_VISIBLE) do
      if @gui.user_tab.page == 2
        @gui.preview_object["preview.button.fit"].signal_emit("clicked")
      end
    end

    @accel.connect(Gdk::Keyval::GDK_0, nil, Gtk::ACCEL_VISIBLE) do
      if @gui.user_tab.page == 2
        @gui.preview_object["preview.button.100"].signal_emit("clicked")
      end
    end
    true
  end

  def tree_select_line
    case @gui.main_tab.page.to_s
    when "0"
      @gui.re_tree.signal_emit("select-cursor-row", false)
    when "1"
      case @gui.main_window.focus
      when @gui.ir_tree
        @gui.ir_tree.signal_emit("select-cursor-row", false)
      when @gui.tekiyo_tree
        @gui.tekiyo_tree.signal_emit("select-cursor-row", false)
      end
    end
  end

  def tree_forward_line
    case @gui.main_tab.page.to_s
    when "0"
      @gui.re_tree.signal_emit("move-cursor", Gtk::MOVEMENT_DISPLAY_LINES, 1)
    when "1"
      case @gui.main_window.focus
      when @gui.ir_tree
        @gui.ir_tree.signal_emit("move-cursor", Gtk::MOVEMENT_DISPLAY_LINES, 1)
      when @gui.tekiyo_tree
        @gui.tekiyo_tree.signal_emit("move-cursor", Gtk::MOVEMENT_DISPLAY_LINES, 1)
      when @gui.santei_tree
        @gui.santei_tree.signal_emit("move-cursor", Gtk::MOVEMENT_DISPLAY_LINES, 1)
      end
    when "2"
      @gui.all_code["view"].signal_emit("move-cursor", Gtk::MOVEMENT_DISPLAY_LINES, 1, false)
    end
  end

  def tree_backward_line
    case @gui.main_tab.page.to_s
    when "0"
      @gui.re_tree.signal_emit("move-cursor", Gtk::MOVEMENT_DISPLAY_LINES, -1)
    when "1"
      case @gui.main_window.focus
      when @gui.ir_tree
        @gui.ir_tree.signal_emit("move-cursor", Gtk::MOVEMENT_DISPLAY_LINES, -1)
      when @gui.tekiyo_tree
        @gui.tekiyo_tree.signal_emit("move-cursor", Gtk::MOVEMENT_DISPLAY_LINES, -1)
      when @gui.santei_tree
        @gui.santei_tree.signal_emit("move-cursor", Gtk::MOVEMENT_DISPLAY_LINES, -1)
      end
    when "2"
      @gui.all_code["view"].signal_emit("move-cursor", Gtk::MOVEMENT_DISPLAY_LINES, -1, false)
    end
  end

  def tab_forward_page
    case @gui.main_tab.page.to_s
    when "0"
      @gui.main_tab.set_page(1)
      @gui.ir_tree.grab_focus
    when "1"
      case @gui.main_window.focus
      when @gui.ir_tree
        @gui.user_tab.set_page(0)
        @gui.tekiyo_tree.grab_focus
      when @gui.tekiyo_tree, @gui.byomei_tree
        @gui.user_tab.set_page(1)
        @gui.santei_tree.grab_focus
      when @gui.santei_tree
        @gui.user_tab.set_page(2)
        @gui.preview_object["preview.entry.scale"].grab_focus
      when @gui.preview_object["preview.entry.scale"]
        @gui.user_tab.set_page(3)
        @gui.user_viewbox["view_box.view"].grab_focus
      when @gui.user_viewbox["view_box.view"]
        @gui.main_tab.set_page(2)
        @gui.all_code["view"].grab_focus
      else
        @gui.user_tab.set_page(1)
        @gui.preview_object["preview.entry.scale"].grab_focus
        @preview_proc.call
      end
    when "2"
      @gui.all_code["view"].grab_focus
    end
  end

  def tab_backward_page
    case @gui.main_tab.page.to_s
    when "0"
      @gui.re_tree.grab_focus
    when "1"
      case @gui.main_window.focus
      when @gui.ir_tree
        @gui.main_tab.set_page(0)
        @gui.re_tree.grab_focus
      when @gui.santei_tree
        @gui.user_tab.set_page(0)
        @gui.tekiyo_tree.grab_focus
      when @gui.preview_object["preview.entry.scale"]
        @gui.user_tab.set_page(1)
        @gui.santei_tree.grab_focus
      when @gui.user_viewbox["view_box.view"]
        @gui.user_tab.set_page(2)
        @gui.main_tab.set_page(1)
        @gui.preview_object["preview.entry.scale"].grab_focus
        @preview_proc.call
      else
        @gui.ir_tree.grab_focus
      end
    when "2"
      @gui.user_tab.set_page(3)
      @gui.main_tab.set_page(1)
      @gui.user_viewbox["view_box.view"].grab_focus
    end
  end

  def textview_forward_start
    return false if @gui.main_window.focus.nil?
    case @gui.main_window.focus
    when @gui.all_code["view"]
      iter = -(@gui.all_code["view"].buffer.line_count)
      @gui.all_code["view"].move_cursor(Gtk::MOVEMENT_DISPLAY_LINES, iter, false)
    when @gui.user_viewbox["view_box.view"]
      view = @gui.user_viewbox["view_box.view"]
      iter = -(view.buffer.line_count)
      view.move_cursor(Gtk::MOVEMENT_DISPLAY_LINES, iter, false)
    else
      false
    end
  end

  def textview_forward_end
    case @gui.main_window.focus
    when @gui.all_code["view"]
      @gui.all_code["view"].move_cursor(Gtk::MOVEMENT_BUFFER_ENDS, 1, false)
    when @gui.user_viewbox["view_box.view"]
      view = @gui.user_viewbox["view_box.view"]
      view != nil ? view.move_cursor(Gtk::MOVEMENT_BUFFER_ENDS, 1, false) : false
    else
      false
    end
  end

  def textview_forward_page
    case @gui.main_window.focus
    when @gui.all_code["view"]
      @gui.all_code["view"].move_cursor(Gtk::MOVEMENT_PAGES, 1, false)
    when @gui.user_viewbox["view_box.view"]
      view = @gui.user_viewbox["view_box.view"]
      view != nil ? view.move_cursor(Gtk::MOVEMENT_PAGES, 1, false) : false
    else
      false
    end
  end

  def textview_backward_page
    case @gui.main_window.focus
    when @gui.all_code["view"]
      @gui.all_code["view"].move_cursor(Gtk::MOVEMENT_PAGES, -1, false)
      @gui.all_code["view"].move_cursor(Gtk::MOVEMENT_DISPLAY_LINES, -1, false)
    when @gui.user_viewbox["view_box.view"]
      view = @gui.user_viewbox["view_box.view"]
      if view != nil
        view.move_cursor(Gtk::MOVEMENT_PAGES, -1, false)
        view.move_cursor(Gtk::MOVEMENT_DISPLAY_LINES, -1, false)
      end
    else
      false
    end
  end

  def textview_forward_line
    case @gui.main_window.focus
    when @gui.all_code["view"]
      @gui.all_code["view"].move_cursor(Gtk::MOVEMENT_DISPLAY_LINES, 1, false)
    when @gui.user_viewbox["view_box.view"]
      view = @gui.user_viewbox["view_box.view"]
      view != nil ? view.move_cursor(Gtk::MOVEMENT_DISPLAY_LINES, 1, false) : false
    else
      false
    end
  end

  def textview_backward_line
    case @gui.main_window.focus
    when @gui.all_code["view"]
      @gui.all_code["view"].move_cursor(Gtk::MOVEMENT_DISPLAY_LINES, -1, false)
    when @gui.user_viewbox["view_box.view"]
      view = @gui.user_viewbox["view_box.view"]
      view != nil ? view.move_cursor(Gtk::MOVEMENT_DISPLAY_LINES, -1, false) : false
    else
      false
    end
  end

  def textview_leftward
    case @gui.main_window.focus
    when @gui.all_code["view"]
      @gui.all_code["view"].move_cursor(Gtk::MOVEMENT_VISUAL_POSITIONS, -1, false)
    when @gui.user_viewbox["view_box.view"]
      view = @gui.user_viewbox["view_box.view"]
      view != nil ? view.move_cursor(Gtk::MOVEMENT_VISUAL_POSITIONS, -1, false) : false
    else
      false
    end
  end

  def textview_rightward
    case @gui.main_window.focus
    when @gui.all_code["view"]
      @gui.all_code["view"].move_cursor(Gtk::MOVEMENT_VISUAL_POSITIONS, 1, false)
    when @gui.user_viewbox["view_box.view"]
      view = @gui.user_viewbox["view_box.view"]
      view != nil ? view.move_cursor(Gtk::MOVEMENT_VISUAL_POSITIONS, 1, false) : false
    else
      false
    end
  end

  def textview_search_forward
    case @gui.main_window.focus
    when @gui.all_code["view"]
      if @gui.all_code["tags"][@gui.all_code["tags_pos"]] == nil
        @gui.all_code["tags_pos"] = 0
      end

      view = @gui.all_code["view"]
      line = @gui.all_code["tags"][@gui.all_code["tags_pos"]]

      if !(line.nil?)
        iters = view.buffer.get_iter_at_line(line[1])
        view.buffer.place_cursor(iters)
        view.scroll_to_iter(iters, 0.2, 0.0, 0, 0)
        @gui.all_code["tags_pos"] += 1
      end
    end
  end

  def textview_search_backward
    case @gui.main_window.focus
    when @gui.all_code["view"]
      if @gui.all_code["tags_pos"] <= -1
        @gui.all_code["tags_pos"] = @gui.all_code["tags"].size - 1
      end

      view = @gui.all_code["view"]
      line = @gui.all_code["tags"][@gui.all_code["tags_pos"]]

      if !(line.nil?)
        iters = view.buffer.get_iter_at_line(line[1])
        view.buffer.place_cursor(iters)
        view.scroll_to_iter(iters, 0.2, 0.0, 0, 0)
        @gui.all_code["tags_pos"] -= 1
      end
    end
  end

  def textview_search_function
    case @gui.main_tab.page.to_s
    when "2"
      if @gui.main_window.focus != @gui.all_code["search"]
        @gui.all_code["search"].show
        text_size = @gui.all_code["search"].text.size
        @gui.all_code["search"].select_region(0, text_size)
        @gui.all_code["search"].grab_focus
        true
      else
        false
      end
    end
  end

  def textview_search_function_move
    case @gui.main_tab.page.to_s
    when "2"
      if @gui.main_window.focus == @gui.all_code["search"]
        @gui.all_code["search"].hide
        @gui.all_code["view"].grab_focus
      else
        text_size = @gui.all_code["search"].text.size
        @gui.all_code["search"].show
        @gui.all_code["search"].select_region(0, text_size)
        @gui.all_code["search"].grab_focus
      end
      true
    end
  end
end
