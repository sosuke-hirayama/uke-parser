# -*- encoding: utf-8 -*-

require 'monitor'
require 'jma/receview/thread'

#Gtk::BINDING_VERSION
#Gtk::BUILD_VERSION
#Gtk::MAJOR_VERSION
#Gtk::MINOR_VERSION
#Gtk::MACRO_VERSION

if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
  begin
    require 'gtk2'
  rescue LoadError
    begin
      require 'rubygems'
      gem 'gtk2'
      require 'gtk2'
    rescue LoadError
    end
  end
else
  require 'gtk2'
end

begin
  require 'gtksourceview2'
rescue LoadError
  begin
    require 'gtksourceview'
  rescue LoadError
    class Gtk::SourceView < Gtk::TextView
      def initialize
        super
      end
      def set_show_line_numbers(status)
        false
      end
    end

    class Gtk::SourceBuffer < Gtk::TextBuffer
      def initialize
        super
      end
    end
  end
end

# http://ruby-gnome2.sourceforge.jp/hiki.cgi?tips_threads
# ruby-forum.com [http://www.ruby-forum.com/topic/125038]
# keep Gtk responsive.
# GUI is permitted from main thread. 
module Gtk
  GTK_PENDING_BLOCKS = []
  GTK_PENDING_BLOCKS_LOCK = Monitor.new

  GTK_SUPPORT_VERSION = [21006]
  GTK_SUPPORT_VERSION_PRECISE = [22410]
  GTK_SUPPORT_VERSION_TRUSTY  = [22423]
  GTK_SUPPORT_VERSION_XENIAL  = [22430]
  GTK_SUPPORT_VERSION_BIONIC  = [22432]
  GTK_SUPPORT_VERSION_AMD64 = [GTK_SUPPORT_VERSION_PRECISE,
                               GTK_SUPPORT_VERSION_TRUSTY,
                               GTK_SUPPORT_VERSION_XENIAL,
                               GTK_SUPPORT_VERSION_BIONIC]
  # gem GTK_SUPPORT_VERSION = [22201]
  # win GTK_SUPPORT_VERSION = [22400]
  # new GTK_SUPPORT_VERSION = [22400]

  def Gtk.queue &block
    if Thread.current == Thread.main
      block.call
      ThreadDummy.new
    else
      GTK_PENDING_BLOCKS_LOCK.synchronize do
        GTK_PENDING_BLOCKS << block
      end
    end
  end

  def Gtk.main_with_queue timeout
    Gtk.timeout_add timeout do
      GTK_PENDING_BLOCKS_LOCK.synchronize do
        for block in GTK_PENDING_BLOCKS
          block.call
        end
        GTK_PENDING_BLOCKS.clear
      end
      true
    end
    #main_loop = GLib::MainLoop.new
    #main_loop.run
    Gtk.main
  end

  if Thread::platform_support_thread
    def Gtk.iteration
    end
  else
    def Gtk.iteration
      while (Gtk.events_pending?)
        Gtk.main_iteration
      end
    end
  end

  def Gtk::platform_support_os_linux(version_hint)
    support_os = false
    if /linux/ =~ RUBY_PLATFORM.downcase
      version = (Gtk::MAJOR_VERSION * 10000) + \
        (Gtk::MINOR_VERSION * 100) + Gtk::MICRO_VERSION
      version_hint.flatten.each do |sversion|
        if sversion == version
          support_os = true
          break
        end
      end
    end
    return support_os
  end

  def Gtk::platform_support_os_bionic
    support_os = false
    if /linux/ =~ RUBY_PLATFORM.downcase
      version = (Gtk::MAJOR_VERSION * 10000) + \
        (Gtk::MINOR_VERSION * 100) + Gtk::MICRO_VERSION
      if Gtk::GTK_SUPPORT_VERSION_BIONIC.last == version
        support_os = true
      end
    end
    return support_os
  end
end

if Thread::platform_support_thread
  class Array
    def gtk_each
      self.each do |a|
        yield(a)
      end
    end

    def gtk_each_with_index
      self.each_with_index do |a, b|
        yield(a, b)
      end
    end

    def gtk_reverse_each
      self.reverse_each do |a, b|
        yield(a, b)
      end
    end
  end

  class Hash
    def gtk_each
      self.each do |a|
        yield(a)
      end
    end

    def gtk_each_with_index
      self.each_with_index do |a, b|
        yield(a, b)
      end
    end
  end

  class Fixnum
    def gtk_times
      self.times do |a|
        yield(a)
      end
    end
  end
else
  class Array
    def gtk_each
      self.each do |a|
        Gtk.iteration
        yield(a)
      end
    end

    def gtk_each_with_index
      self.each_with_index do |a, b|
        Gtk.iteration
        yield(a, b)
      end
    end

    def gtk_reverse_each
      self.reverse_each do |a|
        Gtk.iteration
        yield(a)
      end
    end
  end

  class Hash
    def gtk_each
      self.each do |a|
        Gtk.iteration
        yield(a)
      end
    end

    def gtk_each_with_index
      self.each_with_index do |a, b|
        Gtk.iteration
        yield(a, b)
      end
    end
  end

  class Fixnum
    def gtk_times
      self.times do |a|
        Gtk.iteration
        yield(a)
      end
    end
  end
end
