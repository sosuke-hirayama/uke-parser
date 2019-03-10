# -*- encoding: utf-8 -*-

# require 'gtk2'
class PreView_Widget < Gtk::EventBox
   attr_accessor :move_max_x
   attr_accessor :move_max_y
  def initialize
    super
    set_visible_window(false)
    @drag_stat = false
    @drag_button = 1
    set_button_press_event
    set_button_release_event
    set_motion_notify_event
    @move_max_x = 1000
    @move_max_y = 1000
  end

  def layout
    return parent
  end

  def move(x, y)
    if layout
      layout.move(self, x, y)
      true
    else
      false
    end
  end

  def drag_stat?
    return @drag_stat
  end

  private
  def set_button_press_event
    signal_connect("button_press_event") do |widget, event|
      if event.button == @drag_button
        Gtk.grab_add(widget)
        xywh_array = widget.allocation.to_a
        x, y = xywh_array[0], xywh_array[1]
        drag_start(x, y, event.x_root, event.y_root)
      end
      false
    end
  end

  def set_motion_notify_event
    signal_connect("motion_notify_event") do |widget, event|
      if drag_stat?
        drag_motion(event.x_root, event.y_root)
      else
        false
      end
    end
  end

  def set_button_release_event
    signal_connect("button_release_event") do |widget, event|
      if event.button == @drag_button
        Gtk.grab_remove(widget)
        drag_end
      else
        false
      end
    end
  end

  def set_drag_move_position_event
    signal_connect("drag_move_position") do |widget, x, y|
      if layout
        layout.move(widget, x, y)
        true
      else
        false
      end
    end
  end

  def drag_start(x, y, base_x, base_y)
    @drag_stat = true
    @drag_x = x
    @drag_y = y
    @drag_base_x = base_x
    @drag_base_y = base_y
    true
  end

  def drag_motion(base_x, base_y)
    delta_x = base_x - @drag_base_x
    delta_y = base_y - @drag_base_y
    if delta_x != 0 and delta_y != 0
      set_x = @drag_x + delta_x
      set_y = @drag_y + delta_y

      set_x = @move_max_x if set_x < @move_max_x
      set_y = @move_max_y if set_y < @move_max_y
      set_x = 0 if set_x > 0
      set_y = 0 if set_y > 0

      move(set_x, set_y)
    else
      false
    end
  end
    
  def drag_end
    @drag_stat = false
    true
  end
end

if __FILE__ == $0
end
