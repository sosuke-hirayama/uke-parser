# -*- encoding: utf-8 -*-

require 'jma/receview/generation'
# require 'jma/receview/gtk2_fix'

begin
  require 'jma/receview/base'

  if /linux/ =~ RUBY_PLATFORM.downcase
    raise if Gtk.check_version?(2,20,0)
  else
    raise if Gtk.check_version?(2,22,0)
  end

  class ReceView_PrintManag
    require 'net/http'
    require 'cgi'

    attr_accessor :print_version
    attr_accessor :init_require
    attr_accessor :value
    attr_accessor :name
    attr_accessor :print_scale
    attr_accessor :print_translate_x
    attr_accessor :print_translate_y

    LPC="/usr/sbin/lpc"

    def initialize
      @base = ReceView_Base.new
      @print_version = 1
      @reject_print_name = [
        "Generic Postscript",
        "Create a PDF document",
        "Microsoft XPS Document Writer",
      ]
      @reject_print_id = [
        "GENERIC",
        "PDF",
      ]
      @print_id = []
      @print_name = []

      if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
        @print_scale = 0.470
        @print_translate_x = -10
        @print_translate_y = -5
      else
        @print_scale = 0.485
        @print_translate_x = 5
        @print_translate_y = -5
      end
    end

    def version_check
      Gtk.check_version?(2,10,0)
    end

    def printer_init
      @init_require = true
      if /linux/ =~ RUBY_PLATFORM.downcase
        require "gnomeprintui2"
      else
        shell = WIN32OLE.new("WScript.Shell")
        ruby_exe = ["bin", "ruby"].join(@base.path_char)
        cdir = "'" + @base.get_path + "'"
        if shell.Run("#{ruby_exe} -C #{cdir} -r gnomeprintui2 -e 'exit 0'", 0, true).to_i == 0 
          require "gnomeprintui2"
          @init_require = true
        else
          require "jma/receview/win32network"
          @init_require = false 
        end
      end
      printer_init_defalut
    end

    def printer_init_safe
      if /linux/ =~ RUBY_PLATFORM.downcase
        begin
          require "gnomeprintui2"
        rescue LoadError
        end
        @init_require = true
      else
        require "jma/receview/win32network"
        @init_require = false 
      end
      printer_init_defalut
    end

    def get_lpc_printer
      printer = []
      if File.exist?(LPC)
        print_data = `LANG=C; #{LPC} status`
        print_data.split(/\n/).each do |pname|
          if /^\t+/ !~ pname
            printer.push(pname.sub(/:$/, ""))
          end
        end
      end
      return printer
    end

    def web_printer(host="localhost", port=631)
      # Version 1.2.7
      printer = []
      pname = ""
      ptname = ""
      begin
        Net::HTTP.version_1_2
        Net::HTTP.start(host, port) do |http|
          response = http.get('/printers/')
          response.body.scan(/printer_name\=\S+/).each do |print_tmp|
            pname = CGI.unescapeHTML(print_tmp).sub(/(&shared=\d+)*\">$/, "").split(/\=/)[1]
            if pname != ptname
              printer.push(pname)
            end
            ptname = pname
          end
        end
      rescue Errno::ECONNREFUSED
        ''
      end
      return printer
    end

    def printer_init_defalut
      if @init_require
        @job = Gnome::PrintJob.new
      else
        @job = ReceView_PrintManag_Dummy.new
      end
      @context = @job.context
    end

    def context
      @context
    end

    def job
      @job
    end

    def reject_printer?(printer)
      reject = false
      @reject_print_name.each_with_index do |name, index|
        if @init_require
          if name == printer.value and @reject_print_id[index] == printer.id
            reject = true
            break
          end
        else
          if name == printer
            reject = true
            break
          end
        end
      end
      reject
    end

    def reset
      @print_id = []
      @print_name = []
      if @init_require
        Gnome::GPARoot.printers.each do |print|
          if !reject_printer?(print)
            @print_id.push(print.id)
            @print_name.push(print.value)
          end
        end
      else
        begin
          win32_net = Win32Network.new
          win32_net.enum_printer_name.each do |print|
            if !reject_printer?(print.toutf8)
              @print_id.push(print)
              @print_name.push(print)
            end
          end
        rescue NameError
          get_lpc_printer.each do |print|
            if !reject_printer?(print.toutf8)
              @print_id.push(print)
              @print_name.push(print)
            end
          end
        end
      end
    end

    def print_value
      self.reset
      @print_name
    end

    def print_name
      self.reset
      @print_id
    end

    def page_finish(pixbuf)
      if @init_require
        @context.begin_page do
          job_pixbuf(pixbuf)
        end
      end
    end

    def print_to_file(filename)
      return @job.print_to_file(filename)
    end

    def job_pixbuf(pixbuf)
      @context.save do
        @context.translate(@print_translate_x, @print_translate_y)
        @context.scale(@print_scale, @print_scale)
        @context.image(pixbuf)
      end
      @context.close
    end

    def job_config
      @job.config
    end

    def set_job_config(key, value)
      @job.config[key] = value if key != nil
    end

    def job_print
      @job.print
    end

    def job_close
      @job.close
    end

    def job_new
      if @init_require
        @job = Gnome::PrintJob.new
        @context = @job.context
      else
        @job = ReceView_PrintManag_Dummy.new
        @context = @job.context
      end
    end

    def set_print_settings
    end
  end
rescue
  class ReceView_PrintManag < Gtk::PrintOperation
    attr_accessor :print_version
    attr_accessor :init_require
    attr_accessor :value
    attr_accessor :name
    attr_accessor :print_scale
    attr_accessor :print_translate_x
    attr_accessor :print_translate_y
    attr_accessor :config

    attr_reader :context
    attr_reader :job

    LPC="/usr/sbin/lpc"

    def initialize
      super()
      @base = ReceView_Base.new
      @print_version = 2
      @config = {}
      @reject_print_name = [
        "Generic Postscript",
        "Create a PDF document",
        "Microsoft XPS Document Writer",
      ]
      @reject_print_id = [
        "GENERIC",
        "PDF",
      ]
      @print_id = []
      @print_name = []

      if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
        @print_scale = 0.470
        @print_translate_x = -10
        @print_translate_y = -5
      else
        @print_scale = 0.485
        @print_translate_x = 5
        @print_translate_y = -30
      end

      self.use_full_page = true
      self.unit = Gtk::PaperSize::UNIT_POINTS

      page_setup = Gtk::PageSetup.new
      paper_size = Gtk::PaperSize.new(Gtk::PaperSize.default)
      page_setup.paper_size_and_default_margins = paper_size
      self.default_page_setup = page_setup

      self.show_progress = true        

      self.signal_connect("begin-print") do |pop, context|
        pop.n_pages = 1
      end

      self.signal_connect("draw-page") do |pop, context, page_num|
        context = context.cairo_context
        if @pixbuf.class == Gdk::Pixbuf
          context.scale(0.48, 0.48)
          context.translate(0, 0)
          context.set_source_pixbuf(@pixbuf, 0, 0)
          context.paint
        else
          context.scale(1.0, 1.0)
          context.translate(0, 0)
          context.render_poppler_page(@pixbuf)
        end
      end
    end

    def printer_init
      if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
        require "jma/receview/win32network"
      end
      @init_require = true
      printer_init_defalut
    end

    def printer_init_safe
      if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
        require "jma/receview/win32network"
      end
      @init_require = true
      printer_init_defalut
    end

    def get_lpc_printer
      printer = []
      if File.exist?(LPC)
        print_data = `LANG=C; #{LPC} status`
        print_data.split(/\n/).each do |pname|
          if /^\t+/ !~ pname
            printer.push(pname.sub(/:$/, ""))
          end
        end
      end
      return printer
    end

    def printer_init_defalut
      @job = ReceView_PrintManag_Dummy.new
      @context = @job.context
    end

    def reject_printer?(printer)
      reject = false
      @reject_print_name.each_with_index do |name, index|
        if @init_require
          if printer.class == String
            if name == printer
              reject = true
              break
            end
          else
            if name == printer.value and @reject_print_id[index] == printer.id
              reject = true
              break
            end
          end
        else
          if name == printer
            reject = true
            break
          end
        end
      end
      reject
    end

    def reset
      @print_id = []
      @print_name = []
      begin
        win32_net = Win32Network.new
        win32_net.enum_printer_name.each do |print|
          if !reject_printer?(print.toutf8)
            @print_id.push(print)
            @print_name.push(print)
          end
        end
      rescue NameError
        get_lpc_printer.each do |print|
          if !reject_printer?(print.toutf8)
            @print_id.push(print)
            @print_name.push(print)
          end
        end
      end
    end

    def print_value
      self.reset
      @print_name
    end

    def print_name
      self.reset
      @print_id
    end

    def page_finish(pixbuf)
      job_pixbuf(pixbuf)
    end

    def print_to_file(filename)
      # return @job.print_to_file(filename)
    end

    def job_pixbuf(pixbuf)
      @pixbuf = pixbuf
      run(ACTION_PRINT)
    end

    #def print
      #@context.save do
      #  @context.translate(@print_translate_x, @print_translate_y)
      #  @context.scale(@print_scale, @print_scale)
      #  @context.image(pixbuf)
      #end
      #@context.close
    #end

    def job_config
      @job.config
    end

    def set_job_config(key, value)
      @config[key] = value if key != nil
    end

    def job_print
      # @job.print
    end

    def job_close
      # @job.close
    end

    def job_new
      # @job = Gnome::PrintJob.new
      @job = ReceView_PrintManag_Dummy.new
      @context = @job.context
    end
  end
end

class ReceView_PrintManag_Dummy
  def initialize
    @context_dummy = nil
    @job_dummy = self
  end

  def context
    @context_dummy
  end

  def job
    @job_dummy
  end

  def print
    @job_dummy
  end

  def config(prop=nil, name=nil)
    @job_dummy
  end

  def set(prop, name)
    @job_dummy
  end

  def close 
    @job_dummy
  end

  def job_config
    @job_dummy
  end

  def set_job_config(key, value)
    @job_dummy
  end

  def job_print
    @job_dummy
  end

  def job_close
    @job_dummy
  end

  def job_new
    @job_dummy
  end
end

