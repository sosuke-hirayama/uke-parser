# -*- encoding: utf-8 -*-
# Ruby1.8 -> Ruby1.9

module ReceViewEnv
  def replace_temppath
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      replace_temppath_win
    else
      replace_temppath_linux
    end
  end

  def replace_temppath_win
    ENV['HOME_ORG'] = ENV['HOME'].to_s if !ENV['HOME'].to_s.empty?
    ENV['HOME'] = ENV['APPDATA'].to_s

    if ENV['LOCAL_APPDATA'].to_s.empty?
      #windows_user_temppaths
      [ "\\AppData\\Local\\Temp",
        "\\Local Settings\\Temp"
      ].each do |wpath|
        if File.exist?(ENV['USERPROFILE']+wpath)
          ENV['TEMP_ORG'] = ENV['TEMP']
          ENV['TEMP'] = ENV['USERPROFILE']+wpath
          break
        end
      end
    else
      lpath = "\\Temp"
      if File.exist?(ENV['LOCAL_APPDATA']+lpath)
        ENV['TEMP_ORG'] = ENV['TEMP']
        ENV['TEMP'] = ENV['LOCAL_APPDATA']+lpath
      end
    end
  end

  def replace_temppath_linux
    if ENV['TEMP'].to_s.empty?
      ENV['TEMP'] = "/tmp"
    end
  end

  def add_GtkPath
    if /mingw|mswin|mswin32/ =~ RUBY_PLATFORM
      topdir = File.expand_path(File.dirname(__FILE__).chomp!("/lib/ruby/1.8/i386-mingw32").to_s)
      destdir = topdir && topdir[/\A[a-z]:/i] || '' unless defined? destdir
      prefix = (topdir || destdir+ "")

      if File::ALT_SEPARATOR == nil
        path_char = File::SEPARATOR
      else
        path_char = File::ALT_SEPARATOR
      end
      ENV['PATH'] = %w(bin lib).collect{|dir|
        [
          [prefix, "#{dir};"].join(path_char),
          [prefix, "lib", "GTK", "#{dir};"].join(path_char)
        ]
      }.join('') + ENV['PATH']
    end
    ENV['PATH']
  end
end

include ReceViewEnv if defined?(ReceViewEnv)
ReceViewEnv::add_GtkPath
