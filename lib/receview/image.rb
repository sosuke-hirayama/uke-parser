# -*- encoding: utf-8 -*-

require 'jma/receview/generation'
require 'jma/receview/strconv'
require 'jma/receview/intconv'
require 'jma/receview/red2cairo'
include StrConv
include IntConv

class ReceView_Image_Manag_Test
  def initialize
    @info_data = []
    @kouhi_data = []
    @sickname_data = []
    @diagnosis_data = []
  end

  def add_info
  end

  def add_sickname(sickname_data=[])
    sickname_data.each do |data|
      p data
    end
  end

  # def add_public_expense
  def add_kouhi()
  end

  def add_diagnosis
  end
end

class ReceView_Image
  attr_accessor :background_reander

  attr_accessor :auto_show_page
  attr_accessor :font
  attr_accessor :predata

  attr_reader   :page
  attr_reader   :npage

  attr_accessor :base_type1_png
  attr_accessor :base_type2_png
  attr_accessor :base_type3_png
  attr_accessor :base_type4_png
  attr_accessor :base_type5_png
  attr_accessor :base_type6_png
  attr_accessor :base_type7_png
  attr_accessor :base_type8_png
  attr_accessor :base_type9_png
  attr_accessor :tmp_dir
  attr_accessor :out_dir

  attr_accessor :pdf_width
  attr_accessor :pdf_height

  attr_accessor :rosai
  attr_accessor :rosai_s
  attr_accessor :hospital
  attr_accessor :hospital_day
  attr_accessor :meal_claim
  attr_accessor :meal
  attr_accessor :meal_money

  attr_accessor :dot
  attr_accessor :kanja_no
  attr_accessor :kana
  attr_accessor :name
  attr_accessor :sex
  attr_accessor :sex_str
  attr_accessor :all_birthday
  attr_accessor :age
  attr_accessor :hoken_person
  attr_accessor :clinic_name
  attr_accessor :medical_icode
  attr_accessor :prefecture
  attr_accessor :claim_y
  attr_accessor :claim_m
  attr_accessor :tel

  attr_accessor :rr_form
  attr_accessor :rr_form_no
  attr_accessor :rr_seikyu_kikan
  attr_accessor :rr_receipt_syubetu
  attr_accessor :rr_hoken_nenkin
  attr_accessor :rr_kananame
  attr_accessor :rr_big_number
  attr_accessor :ryo_kikan_stedymd
  attr_accessor :rr_sinkei
  attr_accessor :rr_tenki
  attr_accessor :rr_sickymd
  attr_accessor :rr_sickname_after
  attr_accessor :rr_A_total
  attr_accessor :rr_B_total
  attr_accessor :rr_C_total
  attr_accessor :rr_AB_total
  attr_accessor :rr_ABC_total
  attr_accessor :rr_enterprise_name
  attr_accessor :rr_enterprise_addr

  attr_accessor :tokki
  attr_accessor :life_division
  attr_accessor :diagnosis_TD
  attr_accessor :sickbed

  attr_accessor :hoken
  attr_accessor :hoken_kigo
  attr_accessor :hoken_no
  attr_accessor :hoken_hp
  attr_accessor :hoken_duty
  attr_accessor :hoken_payment
  attr_accessor :hoken_reduction
  attr_accessor :hoken_reduction_kbn
  attr_accessor :hoken_reduction_point
  attr_accessor :hoken_reduction_money

  attr_accessor :kouhi

  attr_accessor :hoken_type
  attr_accessor :hoken_day

  attr_accessor :sickname
  attr_accessor :diagnosis

  PAGE_MAX = 30

  def initialize
    require 'gtk2'
    require 'cairo'
    require 'jma/receview/base'

    @base = ReceView_Base.new
    @path_char = @base.path_char

    @background_reander = "PDF"
    #@background_reander = "PNG"
    #@background_reander = "CAIRO"

    @background_reander_text = "OLD"
    #@background_reander_text = "PANGO"

    @r2cairo = RedCairo.new
    @r2cairo.scale = 59.0

    # context draw?
    @auto_show_page = true

    # Font
    @font = "Sans"

    # Color Format
    @format = Cairo::FORMAT_RGB24

    case @background_reander
    when "CAIRO"
      # BackGround Image for YAML
      @base_type1_file = "receipt_first-000001.yaml.gz"
      @base_type2_file = "receipt_next-000001.yaml.gz"
      @base_type3_file = "receipt_hosp_first-000001.yaml.gz"
      @base_type4_file = "receipt_next-000001.yaml.gz"
      @base_type5_file = "receipt_rosai_first-000001.yaml.gz"
      @base_type6_file = "receipt_rosai_next-000001.yaml.gz"
      @base_type7_file = "receipt_rosai_hosp_first-000001.yaml.gz"
      @base_type8_file = "receipt_rosai_sick_first-000001.yaml.gz"
      @base_type9_file = "receipt_rosai_sick_hosp_first-000001.yaml.gz"
    when "PDF"
      # BackGround Image for PDF
      @base_type1_file = "receipt_first.pdf"
      @base_type2_file = "receipt_next.pdf"
      @base_type3_file = "receipt_hosp_first.pdf"
      @base_type4_file = "receipt_next.pdf"
      @base_type5_file = "receipt_rosai_first.pdf"
      @base_type6_file = "receipt_rosai_next.pdf"
      @base_type7_file = "receipt_rosai_hosp_first.pdf"
      @base_type8_file = "receipt_rosai_sick_first.pdf"
      @base_type9_file = "receipt_rosai_sick_hosp_first.pdf"
    else
      # BackGround Image
      @base_type1_file = "receipt_first-000001.png"
      @base_type2_file = "receipt_next-000001.png"
      @base_type3_file = "receipt_hosp_first-000001.png"
      @base_type4_file = "receipt_next-000001.png"
      @base_type5_file = "receipt_rosai_first-000001.png"
      @base_type6_file = "receipt_rosai_next-000001.png"
      @base_type7_file = "receipt_rosai_hosp_first-000001.png"
      @base_type8_file = "receipt_rosai_sick_first-000001.png"
      @base_type9_file = "receipt_rosai_sick_hosp_first-000001.png"
    end

    install_path = @base.get_path
    home_drive   = ENV['HOMEDRIVE'].to_s

    @base_path = [
      "make_red" + @path_char,
      "share/make_red" + @path_char,
      "/usr/local/share/jma-receview/make_red/",
      "/usr/local/share/jma-receview/red/",
      "/usr/share/jma-receview/make_red/",
      "/usr/share/jma-receview/red/",
      "/home/yasumi/work/ruby+gtk/receview/trunk/make_red/",
      [home_drive, "make_red", ""].join(@path_char),
      [home_drive, "red", ""].join(@path_char),
      [install_path, "make_red", ""].join(@path_char),
      [install_path, "red", ""].join(@path_char),
    ]

    @base_path.each do |file|
      if File.exist?(file + @base_type1_file)
        @base_type1_png = file + @base_type1_file
        break
      end
    end

    @base_path.each do |file|
      if File.exist?(file + @base_type2_file)
        @base_type2_png = file + @base_type2_file
        break
      end
    end

    @base_path.each do |file|
      if File.exist?(file + @base_type3_file)
        @base_type3_png = file + @base_type3_file
        break
      end
    end

    @base_path.each do |file|
      if File.exist?(file + @base_type4_file)
        @base_type4_png = file + @base_type4_file
        break
      end
    end

    @base_path.each do |file|
      if File.exist?(file + @base_type5_file)
        @base_type5_png = file + @base_type5_file
        break
      end
    end

    @base_path.each do |file|
      if File.exist?(file + @base_type6_file)
        @base_type6_png = file + @base_type6_file
        break
      end
    end

    @base_path.each do |file|
      if File.exist?(file + @base_type7_file)
        @base_type7_png = file + @base_type7_file
        break
      end
    end

    @base_path.each do |file|
      if File.exist?(file + @base_type8_file)
        @base_type8_png = file + @base_type8_file
        break
      end
    end

    @base_path.each do |file|
      if File.exist?(file + @base_type9_file)
        @base_type9_png = file + @base_type9_file
        break
      end
    end

    @page_line_max = {
      "sick" => 5,
      "first" => 34,
      "next"  => 58,
      "last"  => 116,
      "max"   => 228,
      "first_h" => 23,
      "next_h"  => 58,
      "last_h"  => 116,
      "max_h"   => 228,

      "sick_r" => 2,
      "first_r" => 27,
      "next_r"  => 56,
      "last_r"  => 112,
      "max_r"   => 224,

      "sick_rh" => 2,
      "first_rh" => 20,
      "next_rh"  => 56,
      "last_rh"  => 112,
      "max_rh"   => 224,

      "sick_sr" => 4,
      "first_sr" => 28,
      "next_sr"  => 56,
      "last_sr"  => 112,
      "max_sr"   => 224,

      "sick_srh" => 4,
      "first_srh" => 20,
      "next_srh"  => 66,
      "last_srh"  => 132,
      "max_srh"   => 262
    }
    @page  = 0
    @npage = 0

    @rosai = false
    @rosai_s = false
    @hospital = false
    @hospital_day = "　"

    @kanja_no = "　"
    @kana = "　"
    @name = "　"
    @sex  = "　"
    @sex_str = "　"
    @all_birthday = "　"
    @age = "　"
    @hoken_person = "　"
    @clinic_name = "　"
    @medical_icode = "　"
    @prefecture = "　"
    @claim_y = "　"
    @claim_m = "　"
    @tel = "　"

    @rr_form = "　"
    @rr_form_no = "　"
    @rr_seikyu_kikan = "　"
    @rr_receipt_syubetu = "　"
    @rr_hoken_nenkin = "　"
    @rr_kananame = "　"
    @ryo_kikan_stedymd = "　"
    @rr_sinkei = "　"
    @rr_tenki = "　"
    @rr_sickymd = "　"
    @rr_sickname_after = "　"
    @rr_A_total = "　"
    @rr_B_total = "　"
    @rr_C_total = "　"
    @rr_AB_total = "　"
    @rr_ABC_total = "　"
    @rr_enterprise_name = "　"
    @rr_enterprise_addr = "　"
    @rr_big_number = "　"

    @tokki = []
    @life_division = "　"
    @diagnosis_TD = "　"
    @sickbed = "　"

    @hoken = "　"
    @hoken_kigo = "　"
    @hoken_no = "　"
    @hoken_hp = "　"
    @hoken_type = []
    @hoken_day = "　"
    @hoken_duty = "　"
    @hoken_payment = "　"
    @hoken_reduction = "　"
    @hoken_reduction_kbn = "　"
    @hoken_reduction_point = "　"
    @hoken_reduction_money = "　"

    @kouhi = []

    @sickname = []
    @diagnosis = []

    @next_str  = "＊＊＊次のページ＊＊＊"
    @next_sick = "以下、摘要欄"
    @sick2_brank = " 　 "

    @predata = ""

    @width_Pixel = 1240
    @height_Pixel = 1754
    @width_A4 = 595.0
    @height_A4 = 842.0
    # scale = (width_A4.to_f / width.to_f * 100).to_i.to_f / 100
    # scale = 0.48
    @pdf_width = nil
    @pdf_height = nil

    @postscript_scale = 0.48

    @image_zoom_table = {
      "PDF" => [
        0.39,
        0.44,
        0.52,
        0.55,
        0.65,
        0.75,
        0.80,
        0.90,
        1.00,
        1.10,
        1.20,
        1.30,
        1.50,
        1.70,
        2.00,
        2.30,
        2.60,
        3.00,
        3.50,
        4.00,
      ],
      "CAIRO" => [
        0.39,
        0.44,
        0.52,
        0.55,
        0.65,
        0.75,
        0.80,
        0.90,
        1.00,
        1.10,
        1.20,
        1.30,
        1.50,
        1.70,
        2.00,
        2.30,
        2.60,
        3.00,
        3.50,
        4.00,
      ],
      "PNG" => [
        0.39,
        0.44,
        0.52,
        0.55,
        0.65,
        0.75,
        0.80,
        0.90,
        1.00,
        1.10,
        1.20,
        1.30,
        1.50,
        1.70,
        2.00,
      ]
    }

    @zoom_table_point_100 =  {
      "PDF" => 14,
      "CAIRO" => 14,
      "PNG" => 8,
    }

    if Gtk::platform_support_os_linux(Gtk::GTK_SUPPORT_VERSION_TRUSTY)
      @image_zoom_table['PNG'].reject! {|x| x == 1.00}
      @zoom_table_point_100['PNG'] -= 1
    end

    @image_zoom_table_point = 2
    @image_zoom_max = @image_zoom_table["PNG"].last
    @image_zoom_min = @image_zoom_table["PNG"].first
    @image_zoom_100 = @image_zoom_table["PNG"][@zoom_table_point_100['PNG']]
    @pdf_zoom_max = @image_zoom_table["PDF"].last
    @pdf_zoom_min = @image_zoom_table["PDF"].first
    @pdf_zoom_100 = @image_zoom_table["PDF"][@zoom_table_point_100['PDF']]
  end

  def scale_search(sc_size)
    return @image_zoom_table[@background_reander].index(sc_size.to_f)
  end

  def reset_reander_format(reander)
    @background_reander = reander

    @r2cairo = RedCairo.new
    @r2cairo.scale = 59.0

    case @background_reander
    when "CAIRO"
      # BackGround Image for YAML
      @base_type1_file = "receipt_first-000001.yaml.gz"
      @base_type2_file = "receipt_next-000001.yaml.gz"
      @base_type3_file = "receipt_hosp_first-000001.yaml.gz"
      @base_type4_file = "receipt_next-000001.yaml.gz"
      @base_type5_file = "receipt_rosai_first-000001.yaml.gz"
      @base_type6_file = "receipt_rosai_next-000001.yaml.gz"
      @base_type7_file = "receipt_rosai_hosp_first-000001.yaml.gz"
      @base_type8_file = "receipt_rosai_sick_first-000001.yaml.gz"
      @base_type9_file = "receipt_rosai_sick_hosp_first-000001.yaml.gz"
      self.zoom_max("1.30")
      self.zoom_min("0.39")
    when "PDF"
      # BackGround Image for PDF
      @base_type1_file = "receipt_first.pdf"
      @base_type2_file = "receipt_next.pdf"
      @base_type3_file = "receipt_hosp_first.pdf"
      @base_type4_file = "receipt_next.pdf"
      @base_type5_file = "receipt_rosai_first.pdf"
      @base_type6_file = "receipt_rosai_next.pdf"
      @base_type7_file = "receipt_rosai_hosp_first.pdf"
      @base_type8_file = "receipt_rosai_sick_first.pdf"
      @base_type9_file = "receipt_rosai_sick_hosp_first.pdf"
      self.zoom_max("4.00")
      self.zoom_min("0.39")
    else
      # BackGround Image
      @base_type1_file = "receipt_first-000001.png"
      @base_type2_file = "receipt_next-000001.png"
      @base_type3_file = "receipt_hosp_first-000001.png"
      @base_type4_file = "receipt_next-000001.png"
      @base_type5_file = "receipt_rosai_first-000001.png"
      @base_type6_file = "receipt_rosai_next-000001.png"
      @base_type7_file = "receipt_rosai_hosp_first-000001.png"
      @base_type8_file = "receipt_rosai_sick_first-000001.png"
      @base_type9_file = "receipt_rosai_sick_hosp_first-000001.png"
      self.zoom_max("1.30")
      self.zoom_min("0.39")
    end

    @base_path.each do |file|
      if File.exist?(file + @base_type1_file)
        @base_type1_png = file + @base_type1_file
        break
      end
    end

    @base_path.each do |file|
      if File.exist?(file + @base_type2_file)
        @base_type2_png = file + @base_type2_file
        break
      end
    end

    @base_path.each do |file|
      if File.exist?(file + @base_type3_file)
        @base_type3_png = file + @base_type3_file
        break
      end
    end

    @base_path.each do |file|
      if File.exist?(file + @base_type4_file)
        @base_type4_png = file + @base_type4_file
        break
      end
    end

    @base_path.each do |file|
      if File.exist?(file + @base_type5_file)
        @base_type5_png = file + @base_type5_file
        break
      end
    end

    @base_path.each do |file|
      if File.exist?(file + @base_type6_file)
        @base_type6_png = file + @base_type6_file
        break
      end
    end

    @base_path.each do |file|
      if File.exist?(file + @base_type7_file)
        @base_type7_png = file + @base_type7_file
        break
      end
    end

    @base_path.each do |file|
      if File.exist?(file + @base_type8_file)
        @base_type8_png = file + @base_type8_file
        break
      end
    end

    @base_path.each do |file|
      if File.exist?(file + @base_type9_file)
        @base_type9_png = file + @base_type9_file
        break
      end
    end
  end

  def clear
    @page  = 0
    @npage = 0

    @rosai = false
    @rosai_s = false
    @hospital = false
    @hospital_day = "　"

    @kanja_no = "　"
    @kana = "　"
    @name = "　"
    @sex  = "　"
    @sex_str = "　"
    @all_birthday = "　"
    @hoken_person = "　"
    @clinic_name = "　"
    @medical_icode = "　"
    @prefecture = "　"
    @claim_y = "　"
    @claim_m = "　"
    @tel = "　"

    @tokki = []
    @life_division = "　"

    @hoken = "　"
    @hoken_kigo = "　"
    @hoken_no = "　"
    @hoken_hp = "　"
    @hoken_type = []
    @hoken_day = "　"
    @hoken_duty = "　"
    @hoken_payment = "　"

    @meal = "　"
    @meal_money = "　"

    @kouhi = []

    @sickname = []
    @diagnosis = []

    @predata = ""
  end

  def zoom_table(reander)
    return @image_zoom_table[reander]
  end

  def zoom_max(point=nil)
    if !point.nil?
      @image_zoom_max = point.to_f
    end
    return @image_zoom_max
  end

  def zoom_min(point=nil)
    if !point.nil?
      @image_zoom_min = point.to_f
    end
    return @image_zoom_min
  end

  def zoom_table_up
    if @image_zoom_table[@background_reander][@image_zoom_table_point] < @image_zoom_max
      @image_zoom_table_point += 1
      if (@image_zoom_table_point + 1) > @image_zoom_table[@background_reander].size
        @image_zoom_table_point = @image_zoom_table[@background_reander].size - 1
      end
    end
    return @image_zoom_table[@background_reander][@image_zoom_table_point]
  end

  def zoom_table_down
    if @image_zoom_table[@background_reander][@image_zoom_table_point] > @image_zoom_min
      @image_zoom_table_point -= 1
      if @image_zoom_table_point < 0
        @image_zoom_table_point = 0
      end
    end
    return @image_zoom_table[@background_reander][@image_zoom_table_point]
  end

  def zoom_table_100
    @image_zoom_table_point = @zoom_table_point_100[@background_reander]
    case @background_reander
    when "PDF", "CAIRO"
      s = @pdf_zoom_100
    when "PNG"
      s = @image_zoom_100
    else
      s = @image_zoom_100
    end
    return s
  end

  def zoom_table_fit(fit_size)
    @image_zoom_table[@background_reander].each_with_index do |size, index|
      if fit_size <= size
        @image_zoom_table_point = index
        break
      end
    end
    return @image_zoom_table_point
  end

  def zoom_table_point
    return @image_zoom_table_point
  end

  def set_zoom_table_point(int=0)
    return @image_zoom_table_point = int.to_i
  end

  def set_font(font)
    @font = font.gsub(/ [0-9]+$/, "")
  end

  def make_rece_predata_size(pixbuf)
    case @background_reander
    when "CAIRO"
      width = @width_Pixel
      height = @height_Pixel
    when "PDF"
      width = @width_A4
      height = @height_A4
    else
      if (@page + @npage) == 0
        if @rosai
          case @rr_form.to_i
          when ReceModelData::ROSAI_34702
            width = pixbuf["type7"].width
            height = pixbuf["type7"].height
          when ReceModelData::ROSAI_34703
            width = pixbuf["type5"].width
            height = pixbuf["type5"].height
          when ReceModelData::ROSAI_34704
            width = pixbuf["type9"].width
            height = pixbuf["type9"].height
          when ReceModelData::ROSAI_34705
            width = pixbuf["type8"].width
            height = pixbuf["type8"].height
          else
            width = pixbuf["type5"].width
            height = pixbuf["type5"].height
          end
        else
          width = pixbuf["type1"].width
          height = pixbuf["type1"].height
        end
      else
        if @rosai
          width = pixbuf["type6"].width
          height = pixbuf["type6"].height
        else
          width = pixbuf["type2"].width
          height = pixbuf["type2"].height
        end
      end
    end

    return {
      "width" => width,
      "height" => height,
    }
  end

  def make_rece_predata_png(pixbuf, out_png)
    pixel_size = make_rece_predata_size(pixbuf)
    width = pixel_size["width"]
    height = pixel_size["height"]

    ret_name = []

    if @background_reander == "PDF"
      surface = Cairo::ImageSurface.new(@format, @width_Pixel, @height_Pixel)
    else
      surface = Cairo::ImageSurface.new(@format, width, height)
    end

    if @predata == ""
      predata = self.make_rece_predata(0, 0)
    else
      predata = @predata
    end
    page_size = @page + @npage

    page_size.times do |page|
      context = Cairo::Context.new(surface)
      if @background_reander == "PDF"
        context.scale(@width_Pixel / width, @height_Pixel / height)
      end

      self.make_rece_predata_context(context, pixbuf, 0, 0,
                                     width, height, 1, 1, predata, page)

      context.show_page
      if page_size != 1
        out_png_plus = out_png.gsub(/\.png/, "-#{(page+1).to_s}.png")
      else
        out_png_plus = out_png
      end
      surface.write_to_png(out_png_plus)
      ret_name.push(out_png_plus)
    end
    surface.finish
    return ret_name
  end

  def make_rece_predata_pdf(pixbuf, out_pdf, finish=true, surface=nil, context=nil)
    pixel_size = make_rece_predata_size(pixbuf)
    width = pixel_size["width"]
    height = pixel_size["height"]

    if @predata == ""
      predata = self.make_rece_predata(0, 0)
    else
      predata = @predata
    end

    if surface.class != Cairo::PDFSurface
      surface = Cairo::PDFSurface.new(out_pdf, width, height)
    end
    if context.class != Cairo::Context
      context = Cairo::Context.new(surface)
    end
    page_size = @page + @npage

    page_size.times do |page|
      self.make_rece_predata_context(context, pixbuf, 0, 0,
                                     width, height, 1.0, 1.0, predata, page)
    end

    if finish
      surface.finish
    else
      return {
        "surface" => surface,
        "context" => context,
      }
    end
  end

  def make_rece_predata_ps(pixbuf, out_ps)
    pixel_size = make_rece_predata_size(pixbuf)
    width = pixel_size["width"]
    height = pixel_size["height"]

    if @predata == ""
      predata = self.make_rece_predata(0, 0)
    else
      predata = @predata
    end

    case @background_reander
    when "PDF"
      scale = 1.00
    else
      scale = 0.48
    end

    width = width*scale
    height = height*scale

    surface = Cairo::PSSurface.new(out_ps, width, height)
    context = Cairo::Context.new(surface)
    page_size = @page + @npage

    page_size.times do |page|
      scale = 1.0 if page >= 1
      self.make_rece_predata_context(context, pixbuf, 0, 0,
                                     width, height, scale, scale, predata, page)
    end
    surface.finish
    return out_ps
  end

  def make_rece_predata_sickname(x,y,page_line_max)
    p_sick = []
    p_nsick = []
    PAGE_MAX.times do |next_int|
      p_nsick[next_int] = []
    end

    y1 = 0
    y2 = 0
    y3 = 0
    y4 = 0
    y5 = 0
    sick_index = 1
    sick_no = 1
    sick_no_sub = 0
    page = 0
    index_sum = 0
    index_real = 0
    @sickname.each do |data|
      index_sum = sick_index+sick_no+sick_no_sub
      fpage_L = page_line_max["sick"]
      if @diagnosis.empty?
        fpage_R = page_line_max["sick"]+page_line_max["first"]
        npage_L = page_line_max["sick"]+page_line_max["first"]+page_line_max["next"]
        npage_R = page_line_max["sick"]+page_line_max["first"]+page_line_max["next"]+page_line_max["last"] - 70
      else
        fpage_R = page_line_max["sick"]+page_line_max["first"] + 4
        npage_L = page_line_max["sick"]+page_line_max["first"]+page_line_max["next"] +  4
        npage_R = page_line_max["sick"]+page_line_max["first"]+page_line_max["next"]+page_line_max["last"] - 72
      end

      name   = data[0].to_s
      day    = data[1].to_s
      status = data[2].to_s

      name1 = ""
      name2 = ""
      if @rosai
        if @rosai_s
          rever_size = 13
          max_size = 18
        else
          rever_size = 12
          max_size = 18
        end
      else
        rever_size = 17
        max_size = 32
      end

      if sick_no >= 10
        name = "（#{sick_no.to_s}）#{name}"
      else
        name = "（#{sw2bw(sick_no.to_s)}）#{name}"
      end

      if sick_index <= fpage_L and sick_index < fpage_R
        if !@rosai
          day  = "（#{sw2bw(sick_no.to_s)}）#{day}"
          status = "（#{sw2bw(sick_no.to_s)}）#{status}"

          if sick_index == page_line_max["sick"] and @sickname.size > page_line_max["sick"]
            se = (max_size - @next_sick.split(//).size - name.split(//).size)
            se.times do |ia| name += "　" end
            name += @next_sick
          end
        end

        if name.split(//).size > rever_size
          name.split(//).each_with_index do |str, index|
            if index >= max_size
              name2 += str
            else
              name1 += str
            end
          end

          if @rosai
            if @rosai_s
              if @hospital
                fm_remove_x = -560
                fm_remove_y = 80
                fm_remove_x2 = -10
                fm_remove_y2 = 0
              else
                fm_remove_x = 0
                fm_remove_y = 0
                fm_remove_x2 = 0
                fm_remove_y2 = 0
              end
            else
              if @hospital
                fm_remove_x = 5
                fm_remove_y = 0
                fm_remove_x2 = 0
                fm_remove_y2 = 0
              else
                fm_remove_x = 0
                fm_remove_y = 0
                fm_remove_x2 = 0
                fm_remove_y2 = 0
              end
            end

            p_sick.push({
              "size" => 17,
              "move" => [720+x+fm_remove_x, 540+y+y1+fm_remove_y],
              "text" => name1
            })

            p_sick.push({
              "size" => 17,
              "move" => [1040+x+fm_remove_x+fm_remove_x2, 540+y+y1+fm_remove_y+fm_remove_y2],
              "text" => day
            })
          else
            p_sick.push({
                "size" => 17,
                "move" => [85+x, 458+y+y1],
                "text" => name1
            })

            p_sick.push({
                "size" => 17,
                "move" => [675+x, 455+y+y1],
                "text" => day
            })

            p_sick.push({
                "size" => 17,
                "move" => [902+x, 455+y+y1],
                "text" => status
            })
          end

          y1 += 25
          sick_index += 1
          sick_no += 1
          index_real +=1

          if !name2.empty?
            if @rosai
              if @rosai_s
                if @hospital
                  fm_remove_x = -555
                  fm_remove_y = 80
                  fm_remove_x2 = -10
                  fm_remove_y2 = 0
                else
                  fm_remove_x = 0
                  fm_remove_y = 0
                  fm_remove_x2 = 0
                  fm_remove_y2 = 0
                end
              else
                if @hospital
                  fm_remove_x = 10
                  fm_remove_y = 0
                  fm_remove_x2 = 0
                  fm_remove_y2 = 0
                else
                  fm_remove_x = 10
                  fm_remove_y = 0
                  fm_remove_x2 = 0
                  fm_remove_y2 = 0
                end
              end

              p_sick.push({
                  "size" => 16,
                  "move" => [720+x+fm_remove_x+fm_remove_x2, 540+y+y1+fm_remove_y],
                  "text" => @sick2_brank + name2
              })
              if sick_index == page_line_max["sick"] and @sickname.size > page_line_max["sick"]
                p_sick.push({
                  "size" => 17,
                  "move" => [1090+x, 565+y+y1],
                  "text" => @next_sick
                })
              end
            else
              p_sick.push({
                  "size" => 17,
                  "move" => [90+x, 458+y+y1],
                  "text" => @sick2_brank + name2
              })
            end

            y1 += 25
            sick_index += 1
            index_real +=1
          end
        else
          if @rosai
            if @rosai_s
              fm_remove_x = -560
              fm_remove_y = 80
              fm_remove_x2 = -10
              fm_remove_y2 = 0
            else
              fm_remove_x = 5
              fm_remove_y = 0
              fm_remove_x2 = 0
              fm_remove_y2 = 0
            end

            p_sick.push({
              "size" => 17,
              "move" => [720+x+fm_remove_x, 540+y+y1+fm_remove_y],
              "text" => name
            })
            p_sick.push({
              "size" => 17,
              "move" => [1040+x+fm_remove_x+fm_remove_x2, 540+y+y1+fm_remove_y+fm_remove_y2],
              "text" => day
            })

            if sick_index == page_line_max["sick"] and @sickname.size > page_line_max["sick"]
              p_sick.push({
                "size" => 17,
                "move" => [1090+x+fm_remove_x+fm_remove_x2, 565+y+y1+fm_remove_y],
                "text" => @next_sick
              })
            end
          else
            p_sick.push({
              "size" => 17,
              "move" => [85+x, 458+y+y1],
              "text" => name
            })

            p_sick.push({
              "size" => 17,
              "move" => [675+x, 455+y+y1],
              "text" => day
            })

            p_sick.push({
              "size" => 17,
              "move" => [902+x, 455+y+y1],
              "text" => status
            })
          end

          y1 += 25
          sick_index += 1
          sick_no += 1
          index_real +=1
        end
      elsif index_sum >= fpage_L and index_sum < fpage_R
        if name.split(//).size > rever_size
          name.split(//).each_with_index do |str, index|
            if index >= max_size
              name2 += str
            else
              name1 += str
            end
          end

          if @rosai
            if @rosai_s
              if @hospital
                fm_remove_x = 0
                fm_remove_y = 580
                fm_remove_x2 = 110
                fm_remove_y2 = 0
              else
                fm_remove_x = 0
                fm_remove_y = 580
                fm_remove_x2 = 110
                fm_remove_y2 = 0
              end
            else
              if @hospital
                fm_remove_x = 0
                fm_remove_y = 580
                fm_remove_x2 = 110
                fm_remove_y2 = 0
              else
                fm_remove_x = 0
                fm_remove_y = 395
                fm_remove_x2 = 110
                fm_remove_y2 = 0
              end
            end
          else
            fm_remove_x = 0
            fm_remove_y = 0
            fm_remove_x2 = 0
            fm_remove_y2 = 0
          end
          
          p_sick.push({
            "size" => 17,
            "move" => [650+x+fm_remove_x, 600+y+y2+fm_remove_y],
            "text" => name1
          })

          y2 += 30
          sick_no += 1
          index_real +=1

          if !name2.empty?
            p_sick.push({
              "size" => 17,
              "move" => [650+x+fm_remove_x, 600+y+y2+fm_remove_y],
              "text" => @sick2_brank + name2
            })

            if name2.split(//).size >= max_size
              y2 += 30
              sick_no_sub += 1
              index_real +=1
            end
          end

          p_sick.push({
            "size" => 17,
            "move" => [930+x+fm_remove_x+fm_remove_x2, 600+y+y2+fm_remove_y],
            "text" => day
          })

          p_sick.push({
            "size" => 17,
            "move" => [1120+x+fm_remove_x, 600+y+y2+fm_remove_y],
            "text" => status
          })

          y2 += 30
          sick_no_sub += 1
          index_real +=1
        else
          if @rosai
            if @rosai_s
              if @hospital
                fm_remove_x = 0
                fm_remove_y = 180
                fm_remove_x2 = 0
                fm_remove_y2 = 0
              else
                fm_remove_x = 0
                fm_remove_y = 0
                fm_remove_x2 = 0
                fm_remove_y2 = 0
              end
            else
              if @hospital
                fm_remove_x = 0
                fm_remove_y = 180
                fm_remove_x2 = 0
                fm_remove_y2 = 0
              else
                fm_remove_x = 0
                fm_remove_y = 0
                fm_remove_x2 = 0
                fm_remove_y2 = 0
              end
            end

            p_sick.push({
              "size" => 17,
              "move" => [650+x+fm_remove_x, 1000+y+y2+fm_remove_y],
              "text" => name
            })

            p_sick.push({
              "size" => 17,
              "move" => [1040+x+fm_remove_x, 1000+y+y2+fm_remove_y],
              "text" => day
            })
          else
            p_sick.push({
              "size" => 17,
              "move" => [650+x, 600+y+y2],
              "text" => name
            })

            p_sick.push({
              "size" => 17,
              "move" => [930+x, 600+y+y2],
              "text" => day
            })

            p_sick.push({
              "size" => 17,
              "move" => [1120+x, 600+y+y2],
              "text" => status
            })
          end

          y2 += 30
          sick_no += 1
          index_real +=1
        end
      elsif index_sum >= fpage_R and index_sum < npage_L
        if name.split(//).size > rever_size
          name.split(//).each_with_index do |str, index|
            if index >= max_size
              name2 += str
            else
              name1 += str
            end
          end

          if @rosai
            if @rosai_s
              if @hospital
                fm_remove_x = 30
                fm_remove_y = 60
                fm_remove_x2 = 60
                fm_remove_y2 = 0
              else
                fm_remove_x = 30
                fm_remove_y = 60
                fm_remove_x2 = 60
                fm_remove_y2 = 0
              end
            else
              if @hospital
                fm_remove_x = 30
                fm_remove_y = 60
                fm_remove_x2 = 60
                fm_remove_y2 = 0
              else
                fm_remove_x = 30
                fm_remove_y = 60
                fm_remove_x2 = 60
                fm_remove_y2 = 0
              end
            end
          else
            fm_remove_x = 0
            fm_remove_y = 0
            fm_remove_x2 = 0
            fm_remove_y2 = 0
          end

          p_nsick[page].push({
            "size" => 17,
            "move" => [105+x+fm_remove_x, 250+y+y4+fm_remove_y],
            "text" => name1
          })

          y4 += 30
          sick_no += 1
          index_real +=1

          if !name2.empty?
            p_nsick[page].push({
              "size" => 17,
              "move" => [105+x+fm_remove_x, 250+y+y4+fm_remove_y],
              "text" => @sick2_brank + name2
            })

            if name2.split(//).size >= max_size
              y4 += 30
              sick_no += 1
              index_real +=1
            end
          end

          p_nsick[page].push({
            "size" => 17,
            "move" => [390+x+fm_remove_x+fm_remove_x2, 250+y+y4+fm_remove_y],
            "text" => day
          })

          p_nsick[page].push({
            "size" => 17,
            "move" => [580+x, 250+y+y4],
            "text" => status
          })

          y4 += 30
          sick_no_sub += 1
          index_real +=1
        else
          if @rosai
            if @rosai_s
              if @hospital
                fm_remove_x = 30
                fm_remove_y = 60
                fm_remove_x2 = 60
                fm_remove_y2 = 0
              else
                fm_remove_x = 30
                fm_remove_y = 60
                fm_remove_x2 = 60
                fm_remove_y2 = 0
              end
            else
              if @hospital
                fm_remove_x = 30
                fm_remove_y = 60
                fm_remove_x2 = 60
                fm_remove_y2 = 0
              else
                fm_remove_x = 30
                fm_remove_y = 60
                fm_remove_x2 = 0
                fm_remove_y2 = 0
              end
            end
          else
            fm_remove_x = 0
            fm_remove_y = 0
            fm_remove_x2 = 0
            fm_remove_y2 = 0
          end

          p_nsick[page].push({
            "size" => 17,
            "move" => [105+x+fm_remove_x, 250+y+y4+fm_remove_y],
            "text" => name
          })

          p_nsick[page].push({
            "size" => 17,
            "move" => [390+x+fm_remove_x+fm_remove_x2, 250+y+y4+fm_remove_y],
            "text" => day
          })

          p_nsick[page].push({
            "size" => 17,
            "move" => [580+x, 250+y+y4],
            "text" => status
          })

          y4 += 30
          sick_no += 1
          index_real +=1
        end
      elsif index_sum >= npage_L and index_sum <= npage_R
        if name.split(//).size > rever_size
          name.split(//).each_with_index do |str, index|
            if index >= max_size
              name2 += str
            else
              name1 += str
            end
          end

          p_nsick[page].push({
            "size" => 17,
            "move" => [680+x, 250+y+y5],
            "text" => name1
          })

          y5 += 30
          sick_no += 1
          index_real +=1

          if !name2.empty?
            p_nsick[page].push({
              "size" => 17,
              "move" => [680+x, 250+y+y5],
              "text" => @sick2_brank + name2
            })
            y5 += 30
            sick_no_sub += 1
            index_real +=1
          end

          p_nsick[page].push({
            "size" => 17,
            "move" => [960+x, 250+y+y5],
            "text" => day
          })

          p_nsick[page].push({
            "size" => 17,
            "move" => [1150+x, 250+y+y5],
            "text" => status
          })

          y5 += 30
          sick_no_sub += 1
          index_real +=1
        else
          p_nsick[page].push({
            "size" => 17,
            "move" => [680+x, 250+y+y5],
            "text" => name
          })

          p_nsick[page].push({
            "size" => 17,
            "move" => [960+x, 250+y+y5],
            "text" => day
          })

          p_nsick[page].push({
            "size" => 17,
            "move" => [1150+x, 250+y+y5],
            "text" => status
          })

          y5 += 30
          sick_no += 1
          index_real +=1
        end

        if sick_index+sick_no+sick_no_sub >= npage_R
          sick_no_sub -= npage_L + 8
          page += 1
          y4 = 0
          y5 = 0
        end
      else
        p "@@@@@@@@@@"
        p name
      end
    end

    y3 = y4 if y4 != 0

    return {
      "y1" => y1,
      "y2" => y2,
      "y3" => y3,
      "index" => index_real,
      "page" => page,
      "pdata" => p_sick,
      "pdata_next" => p_nsick,
    }
  end

  def make_rece_predata_kouhi(other_kouhi, y2, y3, sick_index, page_line_max)
    p_diag = []
    p_next_diag = []
    kc_def_int = 3
    kc_line = 0
    kc_line_if = 0
    kx = 0
    ky = y2
    ky2 = y3
    ky3 = 0
    x = 0
    y = 0
    # fpage_L = page_line_max["sick"]
    fpage_R = page_line_max["sick"]+page_line_max["first"]
    npage_L = page_line_max["sick"]+page_line_max["first"]+page_line_max["next"]
    other_kouhi.each do |kouhi_data|
      if fpage_R > sick_index and (fpage_R - 5) >= sick_index+kc_line
        p_diag.push({
          "size" => 20,
          "move" => [650+x+kx, 600+y+ky],
          "text" => "第#{sw2bw(kc_def_int.to_s)}公費",
        })
        ky +=25

        p_diag.push({
          "size" => 20,
          "move" => [650+x+kx, 600+y+ky],
          "text" => "公#{sw2bw(kc_def_int.to_s)}（#{sw2bw(kouhi_data["h_no"])}）",
        })
        ky +=25

        p_diag.push({
          "size" => 20,
          "move" => [650+x+kx, 600+y+ky],
          "text" => "受　（#{sw2bw(kouhi_data["u_no"])}）",
        })
        ky +=25

        p_diag.push({
          "size" => 20,
          "move" => [650+x+kx, 600+y+ky],
          "text" => "実　（#{sw2bw(word2kotei2(kouhi_data["day"], 2))}日）",
        })
        ky +=25

        kc_line += 4
        kc_line_if += 4
        kc_def_int += 1
      elsif npage_L > sick_index and (npage_L - 15) > (sick_index+kc_line_if)
        if ky2 != 25 and kc_def_int == 3
          p_next_diag.push({
            "size" => 1,
            "move" => [110+x+kx, 240+y+ky2],
            "line" => [620+x+kx, 240+y+ky2],
            "text" => false,
            "stat" => [12, 6, 0]
          })
          ky2 +=25
          kc_line += 1
          kc_line_if += 1
        end

        p_next_diag.push({
          "size" => 20,
          "move" => [120+x+kx, 250+y+ky2],
          "text" => "第#{sw2bw(kc_def_int.to_s)}公費",
        })
        ky2 +=25

        p_next_diag.push({
          "size" => 20,
          "move" => [120+x+kx, 250+y+ky2],
          "text" => "公#{sw2bw(kc_def_int.to_s)}（#{sw2bw(kouhi_data["h_no"])}）",
        })
        ky2 +=25

        p_next_diag.push({
          "size" => 20,
          "move" => [120+x+kx, 250+y+ky2],
          "text" => "受　（#{sw2bw(kouhi_data["u_no"])}）",
        })
        ky2 +=25

        p_next_diag.push({
          "size" => 20,
          "move" => [120+x+kx, 250+y+ky2],
          "text" => "実　（#{sw2bw(word2kotei2(kouhi_data["day"], 2))}日）",
        })
        ky2 +=25

        kc_line += 4
        kc_line_if += 4
        kc_def_int += 1
      else
        if ky3 != 0 and kc_def_int == 3
          p_next_diag.push({
            "size" => 1,
            "move" => [680+x+kx, 240+y+ky3],
            "line" => [1190+x+kx, 240+y+ky3],
            "text" => false,
            "stat" => [12, 6, 0]
          })
          ky3 +=25
          kc_line += 1
        end

        p_next_diag.push({
          "size" => 20,
          "move" => [685+x+kx, 250+y+ky3],
          "text" => "第#{sw2bw(kc_def_int.to_s)}公費",
        })
        ky3 +=25

        p_next_diag.push({
          "size" => 20,
          "move" => [685+x+kx, 250+y+ky3],
          "text" => "公#{sw2bw(kc_def_int.to_s)}（#{sw2bw(kouhi_data["h_no"])}）",
        })
        ky3 +=25

        p_next_diag.push({
          "size" => 20,
          "move" => [685+x+kx, 250+y+ky3],
          "text" => "受　（#{sw2bw(kouhi_data["u_no"])}）",
        })
        ky3 +=25

        p_next_diag.push({
          "size" => 20,
          "move" => [685+x+kx, 250+y+ky3],
          "text" => "実　（#{sw2bw(word2kotei2(kouhi_data["day"], 2))}日）",
        })
        ky3 +=25

        kc_line += 4
        kc_def_int += 1
      end
    end
    return {
      "kdata_x" => kx,
      "kdata_y" => ky,
      "kdata_y2" => ky2,
      "kc_int" => kc_line,
      "kc_diag" => p_diag,
      "kc_next_diag" => p_next_diag,
    }
  end

  def make_rece_predata(x, y)
    x = 0
    y = 0

    page_line_max = {}
    if @rosai
      if @rosai_s
        if @hospital
          page_line_max["sick"] = @page_line_max["sick_srh"]
          page_line_max["first"] = @page_line_max["first_srh"]
          page_line_max["next"] = @page_line_max["next_srh"]
          page_line_max["last"] = @page_line_max["last_srh"]
          page_line_max["max"] = @page_line_max["max_srh"]
        else
          page_line_max["sick"] = @page_line_max["sick_sr"]
          page_line_max["first"] = @page_line_max["first_sr"]
          page_line_max["next"] = @page_line_max["next_sr"]
          page_line_max["last"] = @page_line_max["last_sr"]
          page_line_max["max"] = @page_line_max["max_sr"]
        end
      else
        if @hospital
          page_line_max["sick"] = @page_line_max["sick_rh"]
          page_line_max["first"] = @page_line_max["first_rh"]
          page_line_max["next"] = @page_line_max["next_rh"]
          page_line_max["last"] = @page_line_max["last_rh"]
          page_line_max["max"] = @page_line_max["max_rh"]
        else
          page_line_max["sick"] = @page_line_max["sick_r"]
          page_line_max["first"] = @page_line_max["first_r"]
          page_line_max["next"] = @page_line_max["next_r"]
          page_line_max["last"] = @page_line_max["last_r"]
          page_line_max["max"] = @page_line_max["max_r"]
        end
      end
    else
      if @hospital
        page_line_max["sick"] = @page_line_max["sick"]
        page_line_max["first"] = @page_line_max["first_h"]
        page_line_max["next"] = @page_line_max["next_h"]
        page_line_max["last"] = @page_line_max["last_h"]
        page_line_max["max"] = @page_line_max["max_h"]
      else
        page_line_max["sick"] = @page_line_max["sick"]
        page_line_max["first"] = @page_line_max["first"]
        page_line_max["next"] = @page_line_max["next"]
        page_line_max["last"] = @page_line_max["last"]
        page_line_max["max"] = @page_line_max["max"]
      end
    end

    p_info = []
    p_sick = []
    p_diag = []
    p_skbn = []
    p_ten  = []
    p_total = []
    p_next_info = []
    p_next_diag = []
    p_next_skbn = []
    other_kouhi = []

    PAGE_MAX.times do |next_int|
      p_next_diag[next_int] = []
      p_next_skbn[next_int] = []
    end

    if @rosai
      p_info.push({
          "size" => 16,
          "move" => [80+x, 95+y],
          "text" => @kanja_no
      })
      p_next_info.push({
          "size" => 16,
          "move" => [900+x, 215+y],
          "text" => @kanja_no
      })

      p_info.push({
          "size" => 20,
          "move" => [78+x, 45+y],
          "text" => @rr_receipt_syubetu
      })
      p_next_info.push({
          "size" => 20,
          "move" => [40+x, 45+y],
          "text" => @rr_receipt_syubetu
      })

      p_info.push({
          "size" => 16,
          "move" => [345+x, 70+y],
          "text" => sw2bw(@rr_seikyu_kikan)
      })

      if @rosai_s
        if @hospital
          rr_remove_x = 3
          rr_remove_y = 1.5
        else
          rr_remove_x = 0
          rr_remove_y = 2
        end
      else
        if @hospital
          rr_remove_x = 3
          rr_remove_y = 0.5
        else
          rr_remove_x = 0
          rr_remove_y = 2
        end
      end
      p_info.push({
          "size" => 16,
          "move" => [175+x+rr_remove_x, 70+y+rr_remove_y],
          "text" => sw2bw(word2kotei2(@rr_big_number, 3))
      })

      p_info.push({
          "size" => 18,
          "move" => [170+x, 540+y],
          "text" => @kana
      })
      p_next_info.push({
          "size" => 14,
          "move" => [920+x, 80+y],
          "text" => @rr_kananame
      })

      name_split = @name.split(//)
      if name_split.size >= 15
        p_info.push({
            "size" => 22,
            "move" => [170+x, 550+y],
            "text" => name_split[0..14]
        })
        p_info.push({
            "size" => 22,
            "move" => [170+x, 570+y],
            "text" => name_split[15..-1]
        })

        p_next_info.push({
            "size" => 18,
            "move" => [920+x, 105+y],
            "text" => name_split[0..14]
        })
        p_next_info.push({
            "size" => 18,
            "move" => [920+x, 125+y],
            "text" => name_split[15..-1]
        })
      else
        p_info.push({
            "size" => 22,
            "move" => [170+x, 550+y],
            "text" => @name
        })
        p_next_info.push({
            "size" => 18,
            "move" => [920+x, 105+y],
            "text" => @name
        })
      end

      p_info.push({
          "size" => 16,
          "move" => [170+x, 530+y],
          "text" => @rr_kananame
      })

      p_info.push({
          "size" => 18,
          "move" => [555+x, 570+y],
          "text" => @age
      })
      p_next_info.push({
          "size" => 18,
          "move" => [1150+x, 127+y],
          "text" => @age
      })

      order_x = 0
      @rr_form_no.split(//).each do |order_text|
        p_info.push({
            "font" => "OCRROSAI",
            "size" => 42,
            "move" => [80+x+order_x, 177+y],
            "text" => order_text
        })
        order_x += 36
      end

      if !@rosai_s
        order_x = 0
        @all_birthday.split(//).each do |order_text|
          p_info.push({
            "font" => "OCRROSAI",
            "size" => 42,
            "move" => [117+x+order_x, 330+y],
            "text" => order_text
          })
          order_x += 36
        end
      else
        birthday = wadate6make(@all_birthday, "rosai2wa").split(//)
        wareki_birthday = birthday[0..1].join("")
        order_birthday = [
          birthday[2..5].join(""),
          birthday[6..9].join(""),
          birthday[10..14].join(""),
        ]

        p_info.push({
          "size" => 16,
          "move" => [300+x, 595+y],
          "text" => wareki_birthday
        })

        order_x = 0
        order_birthday.each do |order_text|
          p_info.push({
            "size" => 16,
            "move" => [335+x+order_x, 595+y],
            "text" => order_text
          })
          order_x += 60
        end
      end

      if !@rosai_s
        order_x = 0
        @rr_sickymd.split(//).each do |order_text|
          p_info.push({
              "font" => "OCRROSAI",
              "size" => 42,
              "move" => [400+x+order_x, 330+y],
              "text" => order_text
          })
          order_x += 36
        end
      end

      if @rosai_s
        order_x = 0
        @ryo_kikan_stedymd.split(//).each do |order_text|
          p_info.push({
              "font" => "OCRROSAI",
              "size" => 42,
              "move" => [116+x+order_x, 330+y],
              "text" => order_text
          })
          order_x += 36
        end
      else
        order_x = 0
        @ryo_kikan_stedymd.split(//).each do |order_text|
          p_info.push({
              "font" => "OCRROSAI",
              "size" => 42,
              "move" => [116+x+order_x, 405+y],
              "text" => order_text
          })
          order_x += 36
        end
      end

      p_info.push({
          "size" => 35.5,
          "move" => [380+x, 1680+y],
          "text" => word2kotei2(int2kanma(@rr_A_total), 11)
      })

      if @hospital
        p_info.push({
            "size" => 18,
            "move" => [805+x, 905+y],
            "text" => word2kotei2(int2kanma(@rr_B_total), 11)
        })
        p_info.push({
            "size" => 28,
            "move" => [1000+x, 1120+y],
            "text" => word2kotei2(int2kanma(@rr_C_total), 11)
        })
      else
        p_info.push({
            "size" => 18,
            "move" => [805+x, 920+y],
            "text" => word2kotei2(int2kanma(@rr_B_total), 11)
        })
      end

      if @rosai_s
        if @hospital
          order_x = 0
          @rr_ABC_total.split(//).each do |order_text|
            p_info.push({
                "font" => "OCRROSAI",
                "size" => 42,
                "move" => [115+x+order_x, 403+y],
                "text" => order_text
            })
            order_x += 36
          end
        else
          order_x = 0
          @rr_AB_total.split(//).each do |order_text|
            p_info.push({
                "font" => "OCRROSAI",
                "size" => 42,
                "move" => [115+x+order_x, 403+y],
                "text" => order_text
            })
            order_x += 36
          end
        end
      else
        if @hospital
          order_x = 0
          @rr_ABC_total.split(//).each do |order_text|
            p_info.push({
                "font" => "OCRROSAI",
                "size" => 42,
                "move" => [115+x+order_x, 480+y],
                "text" => order_text
            })
            order_x += 36
          end
        else
          order_x = 0
          @rr_AB_total.split(//).each do |order_text|
            p_info.push({
                "font" => "OCRROSAI",
                "size" => 42,
                "move" => [115+x+order_x, 480+y],
                "text" => order_text
            })
            order_x += 36
          end
        end
      end

      if @rosai_s
        order_x = 0
        @rr_sinkei.split(//).each do |order_text|
          p_info.push({
              "font" => "OCRROSAI",
              "size" => 42,
              "move" => [420+x+order_x, 180+y],
              "text" => order_text
          })
        end

        @rr_tenki.split(//).each do |order_text|
          p_info.push({
              "font" => "OCRROSAI",
              "size" => 42,
              "move" => [617+x+order_x, 180+y],
              "text" => order_text
          })
        end
      else
        order_x = 0
        @rr_sinkei.split(//).each do |order_text|
          p_info.push({
              "font" => "OCRROSAI",
              "size" => 42,
              "move" => [570+x+order_x, 180+y],
              "text" => order_text
          })
        end

        @rr_tenki.split(//).each do |order_text|
          p_info.push({
              "font" => "OCRROSAI",
              "size" => 42,
              "move" => [645+x+order_x, 180+y],
              "text" => order_text
          })
        end
      end

      if !@rosai_s
        p_info.push({
            "size" => 22,
            "move" => [170+x, 622+y],
            "text" => @rr_enterprise_name
        })

        addr_split = @rr_enterprise_addr.split(//)
        if addr_split.size >= 21
          p_info.push({
              "size" => 22,
              "move" => [170+x, 690+y],
              "text" => addr_split[0..19]
          })
          p_info.push({
              "size" => 22,
              "move" => [170+x, 710+y],
              "text" => addr_split[20..-1]
          })
        else
          p_info.push({
              "size" => 22,
              "move" => [170+x, 695+y],
              "text" => @rr_enterprise_addr
          })
        end
      end

      if @rosai_s
        sa_text_x = 0
        sa_text_y = 19
        @rr_sickname_after.each do |sickname_after_text|
          p_info.push({
              "size" => 22,
              "move" => [630+x+sa_text_x, 543+y+sa_text_y],
              "text" => sickname_after_text
          })
          sa_text_y += 25
        end
      else
        sa_text_x = 0
        sa_text_y = 19
        @rr_sickname_after.each do |sickname_after_text|
          p_info.push({
              "size" => 22,
              "move" => [630+x+sa_text_x, 643+y+sa_text_y],
              "text" => sickname_after_text
          })
          sa_text_y += 25
        end
      end

      p_info.push({
          "size" => 18,
          "move" => [545+x, 50+y],
          "text" => @medical_icode
      })
      p_next_info.push({
          "size" => 18,
          "move" => [165+x, 107+y],
          "text" => @medical_icode
      })

      clinic_split = @clinic_name.split(//)
      if clinic_split.size >= 15
        p_info.push({
            "size" => 18,
            "move" => [915+x, 45+y],
            "text" => clinic_split[0..14]
        })
        p_info.push({
            "size" => 18,
            "move" => [915+x, 65+y],
            "text" => clinic_split[15..-1]
        })

        p_next_info.push({
            "size" => 18,
            "move" => [545+x, 90+y],
            "text" => clinic_split[0..14]
        })
        p_next_info.push({
            "size" => 18,
            "move" => [545+x, 110+y],
            "text" => clinic_split[15..-1]
        })
      else
        p_info.push({
            "size" => 18,
            "move" => [925+x, 50+y],
            "text" => @clinic_name
        })
        p_next_info.push({
            "size" => 18,
            "move" => [545+x, 90+y],
            "text" => @clinic_name
        })
      end
    else
      p_info.push({
          "size" => 16,
          "move" => [90+x, 85+y],
          "text" => @kanja_no
      })
      p_next_info.push({
          "size" => 16,
          "move" => [90+x, 85+y],
          "text" => @kanja_no
      })

      p_info.push({
          "size" => 18,
          "move" => [100+x, 320+y],
          "text" => @kana
      })

      p_info.push({
          "size" => 24,
          "move" => [100+x, 355+y],
          "text" => @name
      })
      p_next_info.push({
          "size" => 18,
          "move" => [100+x, 202+y],
          "text" => @name
      })

      p_info.push({
          "size" => 22,
          "move" => [100+x, 395+y],
          "text" => [@sex, @sex_str, @all_birthday]
      })

      p_info.push({
          "size" => 24,
          "move" => [345+x, 125+y],
          "text" => @hoken_person
      })
      p_next_info.push({
          "size" => 24,
          "move" => [345+x, 108+y],
          "text" => @hoken_person
      })

      p_info.push({
          "size" => 18,
          "move" => [445+x, 124+y],
          "text" => @claim_y
      })
      p_next_info.push({
          "size" => 18,
          "move" => [445+x, 107+y],
          "text" => @claim_y
      })

      p_info.push({
          "size" => 18,
          "move" => [505+x, 124+y],
          "text" => @claim_m
      })
      p_next_info.push({
          "size" => 18,
          "move" => [505+x, 107+y],
          "text" => @claim_m
      })

      p_info.push({
          "size" => 18,
          "move" => [625+x, 124+y],
          "text" => @prefecture
      })
      p_next_info.push({
          "size" => 18,
          "move" => [625+x, 107+y],
          "text" => @prefecture
      })

      p_next_info.push({
          "size" => 18,
          "move" => [710+x, 107+y],
          "text" => @medical_icode
      })

      p_info.push({
          "size" => 18,
          "move" => [710+x, 124+y],
          "text" => @medical_icode
      })

      p_info.push({
          "size" => 26,
          "move" => [670+x, 360+y],
          "text" => @clinic_name
      })

      p_info.push({
          "size" => 18,
          "move" => [670+x, 395+y],
          "text" => @tel
      })
    end

    if !@tokki.to_s.empty?
      tokki_y = 0
      @tokki.each do |tokki_data|
        p_info.push({
            "size" => 16,
            "move" => [485+x, 345+y+tokki_y],
            "text" => tokki_data
        })
        tokki_y += 20
      end
    end

    if !@life_division.to_s.empty?
      if @hospital
        p_info.push({
            "size" => 20,
            "move" => [830+x, 1330+y],
            "text" => @life_division 
        })
      else
        p_info.push({
            "size" => 20,
            "move" => [680+x, 1480+y],
            "text" => @life_division 
        })
      end
    end

    if !@diagnosis_TD.to_s.empty?
      p_info.push({
          "size" => 18,
          "move" => [735+x, 425+y],
          "text" => sw2bw(word2kotei(@diagnosis_TD, 1+2+12+1))
      })
    end

    if !@sickbed.to_s.empty?
      p_info.push({
          "size" => 18,
          "move" => [1065+x, 425+y],
          "text" => sw2bw(word2kotei2(@sickbed, 4))
      })
    end

    if @hospital
      if @rosai
        fm_remove_x = 121
        fm_remove_y = 26
        fm_size = 14
      else
        fm_remove_x = 0
        fm_remove_y = 0
        fm_size = 22
      end

      p_info.push({
          "size" => fm_size,
          "move" => [215+x+fm_remove_x, 1293+y+fm_remove_y],
          "text" => @hospital_day
      })
    end

    if @rosai
      if @rosai_s
        order_x = 0
        next_order_x = 0
        @hoken.split(//).each do |order_text|
          p_next_info.push({
              "size" => 30,
              "move" => [120+x+next_order_x, 218+y],
              "text" => order_text
          })
          order_x += 35.5
          next_order_x += 29.5
        end

        order_x = 0
        next_order_x = 0
        @rr_hoken_nenkin.split(//).each do |order_text|
          p_info.push({
              "font" => "OCRROSAI",
              "size" => 42,
              "move" => [119+x+order_x, 253+y],
              "text" => order_text
          })
          p_next_info.push({
              "size" => 30,
              "move" => [630+x+next_order_x, 218+y],
              "text" => order_text
          })
          order_x += 35.5
          next_order_x += 29.5
        end

        order_x = 0
        @hoken_day.split(//).each do |order_text|
          p_info.push({
              "font" => "OCRROSAI",
              "size" => 42,
              "move" => [615+x+order_x, 330+y],
              "text" => order_text
          })
          order_x += 35.5
        end
      else
        order_x = 0
        next_order_x = 0
        @hoken.split(//).each do |order_text|
          p_info.push({
              "font" => "OCRROSAI",
              "size" => 42,
              "move" => [119+x+order_x, 253+y],
              "text" => order_text
          })
          p_next_info.push({
              "size" => 30,
              "move" => [120+x+next_order_x, 218+y],
              "text" => order_text
          })
          order_x += 35.5
          next_order_x += 29.5
        end

        order_x = 0
        @hoken_day.split(//).each do |order_text|
          p_info.push({
              "font" => "OCRROSAI",
              "size" => 42,
              "move" => [630+x+order_x, 405+y],
              "text" => order_text
          })
          order_x += 35.5
        end
      end
    else
      order_x = 0
      @hoken.split(//).each do |order_text|
        p_info.push({
            "size" => 32,
            "move" => [752+x+order_x, 178+y],
            "text" => order_text
        })
        order_x += 38.5
      end

      order_x = 0
      @hoken.split(//).each do |order_text|
        p_next_info.push({
            "size" => 18,
            "move" => [752+x+order_x, 130+y],
            "text" => order_text
        })
        order_x += 40.5
      end

      p_total.push({
          "size" => 26,
          "move" => [1110+x, 465+y],
          "text" => @hoken_day
      })
    end

    p_info.push({
        "size" => 22,
        "move" => [850+x, 220+y],
        "text" => @hoken_kigo
    })
    p_next_info.push({
        "size" => 18,
        "move" => [850+x, 155+y],
        "text" => @hoken_kigo
    })

    p_info.push({
        "size" => 22,
        "move" => [850+x, 245+y],
        "text" => @hoken_no
    })
    p_next_info.push({
        "size" => 18,
        "move" => [850+x, 175+y],
        "text" => @hoken_no
    })

    if @rosai
      p_total.push({
          "size" => 22,
          "move" => [170+x, 1678+y],
          "text" => word2kotei2(@hoken_hp, 10)
      })
    else
      p_total.push({
          "size" => 22,
          "move" => [80+x, 1520+y],
          "text" => sw2bw(word2kotei2(@hoken_hp, 10))
      })
    end

    p_total.push({
        "size" => 18,
        "move" => [172+x, 424+y],
        "text" => sw2bw(@hoken_duty)
    })

    case @hoken_reduction.to_i
    when 1
      if @hoken_reduction_point.empty? and @hoken_reduction_money.empty?
        hoken_h_reduction = "減額後金額"
        p_total.push({
           "size" => 12,
           "move" => [520+x, 1524+y],
           "text" => sw2bw(hoken_h_reduction)
        })
      else
        if !@hoken_reduction_point.empty?
          hoken_h_reduction = @hoken_reduction_point
          p_total.push({
              "size" => 12,
              "move" => [520+x, 1524+y],
              "text" => sw2bw(hoken_h_reduction)
          })
        end
        if !@hoken_reduction_money.empty?
          hoken_h_reduction = @hoken_reduction_money
          p_total.push({
              "size" => 12,
              "move" => [520+x, 1524+y],
              "text" => sw2bw(hoken_h_reduction)
          })
        end
      end

      hoken_h_point = word2kotei2(int2kanma(@hoken_payment), 6+1)
      p_total.push({
          "size" => 14,
          "move" => [540+x, 1512+y],
          "text" => sw2bw(hoken_h_point)
      })
    when 2, 3
      hoken_h_reduction  = @hoken_reduction_kbn
      p_total.push({
         "size" => 12,
         "move" => [520+x, 1524+y],
         "text" => sw2bw(hoken_h_reduction)
      })

      hoken_h_point = word2kotei2(int2kanma(@hoken_payment), 6+1)
      p_total.push({
          "size" => 14,
          "move" => [540+x, 1512+y],
          "text" => sw2bw(hoken_h_point)
      })
    else
      hoken_h_point = word2kotei2(int2kanma(@hoken_payment), 6+1)
      p_total.push({
          "size" => 16,
          "move" => [540+x, 1524+y],
          "text" => sw2bw(hoken_h_point)
      })
    end

    p_info.push({
        "size" => 18,
        "move" => [980+x, 134+y],
        "text" => @hoken_type[1]
    })
    p_next_info.push({
        "size" => 18,
        "move" => [985+x, 107+y],
        "text" => @hoken_type[1]
    })

    p_info.push({
        "size" => 18,
        "move" => [1035+x, 134+y],
        "text" => @hoken_type[2]
    })
    p_next_info.push({
        "size" => 18,
        "move" => [1040+x, 107+y],
        "text" => @hoken_type[2]
    })

    p_info.push({
        "size" => 18,
        "move" => [1095+x, 134+y],
        "text" => @hoken_type[3]
    })
    p_next_info.push({
        "size" => 18,
        "move" => [1100+x, 107+y],
        "text" => @hoken_type[3]
    })

    y1 = 0
    y2 = 0
    y3 = 0
    y4 = 0
    y5 = 0
    if !@kouhi.to_s.empty?
      if @kouhi.size <= 2
        @kouhi.gtk_each_with_index do |kouhi_data, kouhi_index|
          if kouhi_index < 2
            p_info.push({
                "size" => 30,
                "move" => [100+x, 230+y+y1],
                "text" => sw2bw(word2kotei2(kouhi_data["h_no"], 8))
            })
            p_next_info.push({
                "size" => 22,
                "move" => [110+x, 157+y+y3],
                "text" => sw2bw(word2kotei2(kouhi_data["h_no"], 8))
            })

            p_info.push({
                "size" => 30,
                "move" => [390+x, 230+y+y1],
                "text" => sw2bw(word2kotei2(kouhi_data["u_no"], 7))
            })
            p_next_info.push({
                "size" => 22,
                "move" => [410+x, 155+y+y3],
                "text" => sw2bw(word2kotei2(kouhi_data["u_no"], 7))
            })

            p_info.push({
                "size" => 26,
                "move" => [1110+x, 510+y+y4],
                "text" => sw2bw(word2kotei2(kouhi_data["day"], 2))
            })

            p_total.push({
                "size" => 22,
                "move" => [80+x, 1570+y+y2],
                "text" => sw2bw(word2kotei2(kouhi_data["point"], 10))
            })

            kh_point = word2kotei2(int2kanma(kouhi_data["h_point"]), 6+1)
            p_total.push({
                "size" => 20,
                "move" => [525+x, 1570+y+y2],
                "text" => sw2bw(kh_point)
            })

            if !kouhi_data["Co_payment"].empty?
              kh_pay_t = mark(int2kanma(kouhi_data["Co_payment"]))
              kh_pay = word2kotei2(kh_pay_t, 6+3)
              p_total.push({
                "size" => 16,
                "move" => [540+x, 1488+y+y5],
                "text" => sw2bw(kh_pay)
              })
            end

            if @hospital
              # 食事・生活療養 食事回数[hospital] 公費
              if !kouhi_data["meal"].to_s.empty?
                p_total.push({
                    "size" => 14,
                    "move" => [710+x, 1575+y+y2],
                    "text" => sw2bw(word2kotei2(kouhi_data["meal"], 3))
                })
              end

              # 食事,生活,環境 合計請求金額[hospital] 公費
              if !kouhi_data["meal_money"].to_s.empty?
                money_97_sum = kouhi_data["meal_money"]
                p_total.push({
                    "size" => 18,
                    "move" => [805+x, 1575+y+y2],
                    "text" => sw2bw(word2kotei2(i2k_l(money_97_sum), 7))
                })
              end
            end

            y1 += 45
            y2 += 52
            y3 += 24
            y4 += 48
            y5 += 16
          else
            other_kouhi.push(kouhi_data)
          end
        end
      elsif @kouhi.size == 3
        @kouhi.gtk_each_with_index do |kouhi_data, kouhi_index|
          if kouhi_index <= 1
            p_info.push({
                "size" => 30,
                "move" => [100+x, 230+y+y1],
                "text" => sw2bw(word2kotei2(kouhi_data["h_no"], 8))
            })
            p_next_info.push({
                "size" => 22,
                "move" => [110+x, 157+y+y3],
                "text" => sw2bw(word2kotei2(kouhi_data["h_no"], 8))
            })

            p_info.push({
                "size" => 30,
                "move" => [390+x, 230+y+y1],
                "text" => sw2bw(word2kotei2(kouhi_data["u_no"], 7))
            })
            p_next_info.push({
                "size" => 22,
                "move" => [410+x, 155+y+y3],
                "text" => sw2bw(word2kotei2(kouhi_data["u_no"], 7))
            })

            p_info.push({
                "size" => 26,
                "move" => [1110+x, 510+y+y4],
                "text" => sw2bw(word2kotei2(kouhi_data["day"], 2))
            })
          end

          if kouhi_index == 0
            p_total.push({
                "size" => 22,
                "move" => [80+x, 1570+y+y2],
                "text" => sw2bw(word2kotei2(kouhi_data["point"], 10))
            })
          else
            p_total.push({
                "size" => 15,
                "move" => [140+x, 1580+y+y2],
                "text" => sw2bw(word2kotei2(kouhi_data["point"], 10))
            })
          end

          kh_point = word2kotei2(int2kanma(kouhi_data["h_point"]), 6+1)
          if kouhi_index == 0
            p_total.push({
                "size" => 20,
                "move" => [525+x, 1570+y+y2],
                "text" => sw2bw(kh_point)
            })
          else
            p_total.push({
                "size" => 14,
                "move" => [565+x, 1580+y+y2],
                "text" => sw2bw(kh_point)
            })
          end

          if @hospital
            if kouhi_index == 0
              # 食事・生活療養 食事回数[hospital] 公費
              if !kouhi_data["meal"].to_s.empty?
                p_total.push({
                    "size" => 14,
                    "move" => [710+x, 1575+y+y2],
                    "text" => sw2bw(word2kotei2(kouhi_data["meal"], 3))
                })
              end

              # 食事,生活,環境 合計請求金額[hospital] 公費
              if !kouhi_data["meal_money"].to_s.empty?
                money_97_sum = kouhi_data["meal_money"]
                p_total.push({
                    "size" => 18,
                    "move" => [805+x, 1575+y+y2],
                    "text" => sw2bw(word2kotei2(i2k_l(money_97_sum), 7))
                })
              end
            else
              # 食事・生活療養 食事回数[hospital] 公費
              if !kouhi_data["meal"].to_s.empty?
                p_total.push({
                    "size" => 14,
                    "move" => [710+x, 1585+y+y2],
                    "text" => sw2bw(word2kotei2(kouhi_data["meal"], 3))
                })
              end

              # 食事,生活,環境 合計請求金額[hospital] 公費
              if !kouhi_data["meal_money"].to_s.empty?
                money_97_sum = kouhi_data["meal_money"]
                p_total.push({
                    "size" => 18,
                    "move" => [805+x, 1585+y+y2],
                    "text" => sw2bw(word2kotei2(i2k_l(money_97_sum), 7))
                })
              end
            end
          end

          y1 += 45
          y2 += 20
          y3 += 24
          y4 += 48
          if kouhi_index >= 2
            other_kouhi.push(kouhi_data)
          end
        end
      elsif @kouhi.size == 4
        @kouhi.gtk_each_with_index do |kouhi_data, kouhi_index|
          if kouhi_index <= 1
            p_info.push({
                "size" => 30,
                "move" => [100+x, 230+y+y1],
                "text" => sw2bw(word2kotei2(kouhi_data["h_no"], 8))
            })
            p_next_info.push({
                "size" => 22,
                "move" => [110+x, 157+y+y3],
                "text" => sw2bw(word2kotei2(kouhi_data["h_no"], 8))
            })

            p_info.push({
                "size" => 30,
                "move" => [390+x, 230+y+y1],
                "text" => sw2bw(word2kotei2(kouhi_data["u_no"], 7))
            })
            p_next_info.push({
                "size" => 22,
                "move" => [410+x, 155+y+y3],
                "text" => sw2bw(word2kotei2(kouhi_data["u_no"], 7))
            })

            p_info.push({
                "size" => 26,
                "move" => [1110+x, 510+y+y4],
                "text" => sw2bw(word2kotei2(kouhi_data["day"], 2))
            })
          end

          if kouhi_index <= 1
            p_total.push({
                "size" => 15,
                "move" => [145+x, 1550+y+y2],
                "text" => sw2bw(word2kotei2(kouhi_data["point"], 10))
            })
          else
            p_total.push({
                "size" => 15,
                "move" => [145+x, 1560+y+y2],
                "text" => sw2bw(word2kotei2(kouhi_data["point"], 10))
            })
          end

          kh_point = word2kotei2(int2kanma(kouhi_data["h_point"]), 6+1)
          if kouhi_index <= 1
            p_total.push({
                "size" => 14,
                "move" => [570+x, 1550+y+y2],
                "text" => sw2bw(kh_point)
            })
          else
            p_total.push({
                "size" => 14,
                "move" => [570+x, 1560+y+y2],
                "text" => sw2bw(kh_point)
            })
          end

          if @hospital
            if kouhi_index <= 1
              # 食事・生活療養 食事回数[hospital] 公費
              if !kouhi_data["meal"].to_s.empty?
                p_total.push({
                    "size" => 14,
                    "move" => [710+x, 1555+y+y2],
                    "text" => sw2bw(word2kotei2(kouhi_data["meal"], 3))
                })
              end

              # 食事,生活,環境 合計請求金額[hospital] 公費
              if !kouhi_data["meal_money"].to_s.empty?
                money_97_sum = kouhi_data["meal_money"]
                p_total.push({
                    "size" => 18,
                    "move" => [805+x, 1555+y+y2],
                    "text" => sw2bw(word2kotei2(i2k_l(money_97_sum), 7))
                })
              end
            else
              # 食事・生活療養 食事回数[hospital] 公費
              if !kouhi_data["meal"].to_s.empty?
                p_total.push({
                    "size" => 14,
                    "move" => [710+x, 1565+y+y2],
                    "text" => sw2bw(word2kotei2(kouhi_data["meal"], 3))
                })
              end

              # 食事,生活,環境 合計請求金額[hospital] 公費
              if !kouhi_data["meal_money"].to_s.empty?
                money_97_sum = kouhi_data["meal_money"]
                p_total.push({
                    "size" => 18,
                    "move" => [805+x, 1565+y+y2],
                    "text" => sw2bw(word2kotei2(i2k_l(money_97_sum), 7))
                })
              end
            end
          end

          y1 += 45
          y2 += 20
          y3 += 24
          y4 += 48
          if kouhi_index >= 2
            other_kouhi.push(kouhi_data)
          end
        end
      end
    end

    y2 = 0
    y3 = 0
    x3 = 0
    sick_index = 1
    pdata = self.make_rece_predata_sickname(x,y,page_line_max)

    y2 = pdata["y2"]
    y3 = pdata["y3"]
    sick_index = pdata["index"]
    p_sick = pdata["pdata"]
    p_next_diag = pdata["pdata_next"]

    if sick_index >= page_line_max["sick"]
      sep_line = 1
      all_page_count = sick_index - page_line_max["sick"] + sep_line
    else
      all_page_count = 0
    end

    sick_index_reg = 0
    pdata["pdata_next"].each do |pd|
      break if pd.size == 0
      sick_index_reg = pd.size
    end

    kdata = self.make_rece_predata_kouhi(other_kouhi, y2, y3, sick_index, page_line_max)

    kdata["kc_diag"].each do |kc|
      p_diag.push(kc)
    end

    kdata["kc_next_diag"].each do |kc|
      p_next_diag[pdata["page"]].push(kc)
    end

    y2 = kdata["kdata_y"]
    y3 = kdata["kdata_y2"]
    all_page_count += kdata["kc_int"]

    if sick_index_reg != 0
      next_diag_no = kdata["kc_int"] + sick_index_reg
    else
      next_diag_no = kdata["kc_int"]
    end

    if all_page_count + next_diag_no >= page_line_max["first"]
      diag_no = next_diag_no
    else
      diag_no = 0
    end
    npage = pdata["page"]

    y2 += 20
    y3 += 20

    first_medical_11 = []
    first_medical_12 = []
    first_medical_13 = []
    first_medical_14 = []
    first_medical_20 = []
    first_medical_30 = []
    first_medical_40 = []
    first_medical_50 = []
    first_medical_60 = []
    first_medical_70 = []
    first_medical_80 = []
    first_medical_90 = []
    no_history = ""

    if @rosai
      if @hospital
        x += 6
        y += 570
        sx = 20
        sy = 0
      else
        x += 5
        y += 400
        sx = 20
        sy = 0
      end
    else
      sx = 0
      sy = 0
    end

    next_page = 0
    @diagnosis.gtk_each do |jin|
      if (next_diag_no) >= page_line_max["next"] && (next_diag_no) < page_line_max["last"]
        if next_page == 0
          x3 = 570
          y3 = 25
          next_page = 1
        end
      elsif (next_diag_no) >= page_line_max["last"] && (next_diag_no) < page_line_max["max"]
        if next_page == 1
          x3 = 0
          y3 = 25
          npage += 1
          next_diag_no = 0
          next_page = 0
        end
      end

      futan_no = jin[1]
      no    = jin[0]
      name  = jin[2]
      tani  = jin[3]
      point = jin[4]
      kbn   = jin[5]
      ameal = jin[6]
      parent = jin[7]
      blink = jin[8]
      #rece_kbn = jin[9]

      name1 = ""
      name2 = ""

      if @rosai
        rever_size = 15 * 2
        max_size = 26 * 2
      else
        rever_size = 15 * 2
        max_size = 26 * 2
      end

      if no == "11" or (no == "" and  no_history == "11")
        first_medical_11.push([point, futan_no])
      elsif no == "12" or (no == "" and  no_history == "12")
        first_medical_12.push([name, point, kbn, futan_no])
      elsif no == "13" or (no == "" and  no_history == "13")
        first_medical_13.push([name, point, kbn, futan_no])
      elsif no == "14" or (no == "" and  no_history == "14")
        first_medical_14.push([name, point, kbn, futan_no])
      elsif no == "21" or (no == "" and  no_history == "21")
        first_medical_20.push([name, point, kbn, futan_no])
      elsif no == "22" or (no == "" and  no_history == "22")
        first_medical_20.push([name, point, kbn, futan_no])
      elsif no == "23" or (no == "" and  no_history == "23")
        first_medical_20.push([name, point, kbn, futan_no])
      elsif no == "24" or (no == "" and  no_history == "24")
        first_medical_20.push([name, point, kbn, futan_no])
      elsif no == "25" or (no == "" and  no_history == "25")
        first_medical_20.push([name, point, kbn, futan_no])
      elsif no == "26" or (no == "" and  no_history == "26")
        first_medical_20.push([name, point, kbn, futan_no])
      elsif no == "27" or (no == "" and  no_history == "27")
        first_medical_20.push([name, point, kbn, futan_no])
      elsif no == "31" or (no == "" and  no_history == "31")
        first_medical_30.push([name, point, kbn, futan_no, blink])
      elsif no == "32" or (no == "" and  no_history == "32")
        first_medical_30.push([name, point, kbn, futan_no, blink])
      elsif no == "33" or (no == "" and  no_history == "33")
        first_medical_30.push([name, point, kbn, futan_no, blink])
      elsif no == "40" or (no == "" and  no_history == "40")
        first_medical_40.push([name, point, kbn, futan_no, blink])
      elsif no == "50" or (no == "" and  no_history == "50")
        first_medical_50.push([name, point, kbn, futan_no])
      elsif no == "54" or (no == "" and  no_history == "54")
        first_medical_50.push([name, point, kbn, futan_no])
      elsif no == "60" or (no == "" and  no_history == "60")
        first_medical_60.push([name, point, kbn, futan_no])
      elsif no == "64" or (no == "" and  no_history == "64")
        first_medical_60.push([name, point, kbn, futan_no])
      elsif no == "70" or (no == "" and  no_history == "70")
        first_medical_70.push([name, point, kbn, futan_no])
      elsif no == "80" or (no == "" and  no_history == "80")
        first_medical_80.push([name, point, kbn, futan_no])
      elsif no == "90" or (no == "" and  no_history == "90")
        first_medical_90.push([name, point, kbn, futan_no, tani])
      elsif no == "92" or (no == "" and  no_history == "92")
        first_medical_90.push([name, point, kbn, futan_no, tani])
      elsif no == "97" or (no == "" and  no_history == "97")
        first_medical_90.push([name, point, kbn, futan_no, tani, ameal])
      end

      if no != no_history and !no.empty?
        # 罫線 最終
        if y2 != 20
          if (all_page_count + diag_no) < page_line_max["first"]
            p_diag.push({
              "size" => 1,
              "move" => [650+x, 575+y+y2],
              "line" => [1187+x, 575+y+y2],
              "text" => false,
              "stat" => [12, 6, 0]
            })
            y2 += 20
            diag_no += 1
          else
            if @rosai
              if @hospital
                rr_remove_x = 5
                rr_remove_y = -520
              else
                rr_remove_x = 5
                rr_remove_y = -350
              end
            else
              rr_remove_x = 0
              rr_remove_y = 0
            end

            if y3 != 25 and y3 != 20
              p_next_diag[npage].push({
                "size" => 1,
                "move" => [110+x+x3+rr_remove_x, 225+y+y3+rr_remove_y],
                "line" => [620+x+x3+rr_remove_x, 225+y+y3+rr_remove_y],
                "text" => false,
                "stat" => [12, 6, 0]
              })
              y3 += 20
              next_diag_no += 1
            end
          end
        end

        if (all_page_count + diag_no) < page_line_max["first"]
          # 診療区分 [1ページ目]
          p_skbn.push({
            "size" => 19,
            "move" => [603+x+sx, 580+y+y2+sy],
            "text" => no
          })
        else
          if @rosai
            if @hospital
              rr_remove_x = 5
              rr_remove_y = -520
            else
              rr_remove_x = 5
              rr_remove_y = -350
            end
          else
            rr_remove_x = 0
            rr_remove_y = 0
          end

          # 診療区分 [次ページ目]
          p_next_skbn[npage].push({
            "size" => 19,
            "move" => [55+x+x3+sx+rr_remove_x, 230+y+y3+sy+rr_remove_y],
            "text" => no
          })
        end
      end

      # 単位コード付加
      name_plus_tani = make_preview_mark(name, tani, parent)

      if word_size(name_plus_tani) > rever_size
        index = 0
        (name_plus_tani).split(//).each do |str|
          index += word_size(str)
          if index >= max_size
            name2 += str
          else
            name1 += str
          end
        end
        name1 = name1.gsub(/^　+$/, "")
        name2 = name2.gsub(/^　+$/, "")

        if (all_page_count + diag_no) < page_line_max["first"]
          if @rosai
            if @hospital
              rr_remove_x = 0
              rr_remove_y = 0
              rr_remove_x2 = 10
              rr_remove_y2 = 0
            else
              rr_remove_x = 0
              rr_remove_y = 0
              rr_remove_x2 = 10
              rr_remove_y2 = 0
            end
          else
            rr_remove_x = 0
            rr_remove_y = 0
            rr_remove_x2 = 0
            rr_remove_y2 = 0
          end

          if !no.empty?
            at_str = "＊"
            if !futan_no.empty?
              p_skbn.push({
                "size" => 19,
                "move" => [635+x, 580+y+y2],
                "text" => futan_no
              })
            end
          else
            at_str = "　"
          end

          p_diag.push({
            "size" => 19,
            "move" => [650+x, 580+y+y2],
            "text" => at_str + name1
          })

          #if !name2.empty? and (!futan_no.empty? or !no.empty?)
          #  y2 += 25
          #  diag_no += 1
          #end

          if !name2.empty?
            y2 += 25
            diag_no += 1

            p_diag.push({
              "size" => 19,
              "move" => [650+x, 580+y+y2],
              "text" => "　" + name2
            })

            if (!futan_no.empty?) && (!no.empty?) && (kbn != "110") && (!tani.empty? || !point.empty?)
              y2 += 25
              diag_no += 1
            end
            # 点数改行
            if word_size(name2) == max_size
              y2 += 25
              diag_no += 1
            end
          else
            # 点数改行
            if word_size(name1) == max_size
              if !point.empty?
                y2 += 25
                diag_no += 1
              end
            end
          end

          # 労災 金額,点数改行[1ページ折り返しあり]
          if /　/ =~ point
            money, tensu = point.split(/　/)
            mtensu, mcount = money.split(/ x /)
            ptensu, pcount = tensu.split(/ x /)
            mstring = word2kotei2(mtensu, 8).sub(/-/, "▲") + " x" + word2kotei2(mcount, 3)
            pstring = word2kotei2(ptensu, 8).sub(/-/, "▲") + " x" + word2kotei2(pcount, 3)

            if !name2.to_s.empty?
              name3 = name2.to_s + mstring
            else
              name3 = name1.to_s + mstring
            end
            name3_size = word_size(name3)

            if name3_size >= max_size
              y2 += 25
              diag_no += 1
            end

            p_diag.push({
              "size" => 19,
              "move" => [1050+x+rr_remove_x2, 580+y+y2+rr_remove_y2],
              "text" => mstring
            })

            y2 += 25
            diag_no += 1

            p_diag.push({
              "size" => 19,
              "move" => [1050+x+rr_remove_x2, 580+y+y2+rr_remove_y2],
              "text" => pstring
            })
          else
            if !point.empty?
              ptensu, pcount = point.split(/ x /)
              pstring = word2kotei2(ptensu, 8).sub(/-/, "▲") + " x" + word2kotei2(pcount, 3)
              if !name2.to_s.empty?
                name3 = name2.to_s + point.to_s
              else
                name3 = name1.to_s + point.to_s
              end
              name3_size = word_size(name3)

              if name3_size >= max_size
                y2 += 25
                diag_no += 1
              end

              p_diag.push({
                "size" => 19,
                "move" => [1050+x+rr_remove_x2, 580+y+y2+rr_remove_y2],
                "text" => pstring
              })
            end
          end

          y2 += 25
          diag_no += 1
        else
          # 次ページ以降
          if @rosai
            if @hospital
              rr_remove_x = 0
              rr_remove_y = -520
            else
              rr_remove_x = 0
              rr_remove_y = -350
            end
          else
            rr_remove_x = 0
            rr_remove_y = 0
          end

          if !no.empty?
            at_str = "＊"
            at_space = "　"
            if !futan_no.empty?
              p_next_skbn[npage].push({
                "size" => 19,
                "move" => [93+x+x3+rr_remove_x, 230+y+y3+rr_remove_y],
                "text" => futan_no
              })
            end
          else
            at_str = "　"
            at_space = "　"
          end

          p_next_diag[npage].push({
            "size" => 19,
            "move" => [120+x+x3+rr_remove_x, 230+y+y3+rr_remove_y],
            "text" => at_str + name1
          })

          y3 += 25
          next_diag_no += 1

          if !name2.empty?
            p_next_diag[npage].push({
              "size" => 19,
              "move" => [120+x+x3+rr_remove_x, 230+y+y3+rr_remove_y],
              "text" => at_space + name2
            })

            y3 += 25
            next_diag_no += 1
          end

          # 労災 金額,点数改行[次ページ折り返しあり]
          if /　/ =~ point
            money, tensu = point.split(/　/)
            mtensu, mcount = money.split(/ x /)
            ptensu, pcount = tensu.split(/ x /)
            mstring = word2kotei2(mtensu, 8).sub(/-/, "▲") + " x" + word2kotei2(mcount, 3)
            pstring = word2kotei2(ptensu, 8).sub(/-/, "▲") + " x" + word2kotei2(pcount, 3)

            if !name2.to_s.empty?
              name3 = at_space + name2.to_s + mstring
            else
              name3 = at_str + name1.to_s + mstring
            end
            name3_size = word_size(name3)

            if name3_size >= max_size and !name2.to_s.empty?
              y3 += 25
              diag_no += 1
            end

            p_next_diag[npage].push({
              "size" => 19,
              "move" => [495+x+x3+rr_remove_x, 230+y+y3+rr_remove_y],
              "text" => mstring
            })

            y3 += 25
            diag_no += 1

            p_next_diag[npage].push({
              "size" => 19,
              "move" => [495+x+x3+rr_remove_x, 230+y+y3+rr_remove_y],
              "text" => pstring
            })
          else
            if !point.empty?
              ptensu, pcount = point.split(/ x /)
              pstring = word2kotei2(ptensu, 8).sub(/-/, "▲") + " x" + word2kotei2(pcount, 3)
              if !name2.to_s.empty?
                name3 = at_space + name2.to_s + pstring
              else
                name3 = at_str + name1.to_s + pstring
              end
              name3_size = word_size(name3)

              if name3_size >= max_size and !name2.to_s.empty?
                y3 += 25
                diag_no += 1
              end

              p_next_diag[npage].push({
                "size" => 19,
                "move" => [495+x+x3+rr_remove_x, 230+y+y3+rr_remove_y],
                "text" => pstring
              })
            end
          end

          if !point.empty?
            y3 += 25
            next_diag_no += 1
          end
        end
      else
        if @rosai
          if @hospital
            rr_remove_x = 0
            rr_remove_y = 0
            rr_remove_x2 = 10
            rr_remove_y2 = 0
          else
            rr_remove_x = 0
            rr_remove_y = 0
            rr_remove_x2 = 10
            rr_remove_y2 = 0
          end
        else
          rr_remove_x = 0
          rr_remove_y = 0
          rr_remove_x2 = 0
          rr_remove_y2 = 0
        end

        if !no.empty?
          name_plus_tani = ("＊" + name_plus_tani)
        else
          name_plus_tani = ("　" + name_plus_tani)
        end

        if (all_page_count + diag_no) < (page_line_max["first"])
          if !no.empty?
            if !futan_no.empty?
              p_skbn.push({
                "size" => 19,
                "move" => [635+x+rr_remove_x, 580+y+y2+rr_remove_y],
                "text" => futan_no
              })
            end
          end

          p_diag.push({
            "size" => 19,
            "move" => [650+x+rr_remove_x, 580+y+y2+rr_remove_y],
            "text" => name_plus_tani
          })

          # 労災 金額,点数改行[1ページ]
          if /　/ =~ point
            money, tensu = point.split(/　/)
            mtensu, mcount = money.split(/ x /)
            ptensu, pcount = tensu.split(/ x /)
            mstring = word2kotei2(mtensu, 8).sub(/-/, "▲") + " x" + word2kotei2(mcount, 3)
            pstring = word2kotei2(ptensu, 8).sub(/-/, "▲") + " x" + word2kotei2(pcount, 3)

            p_diag.push({
              "size" => 19,
              "move" => [1050+x+rr_remove_x2, 580+y+y2+rr_remove_y2],
              "text" => mstring
            })

            y2 += 25
            diag_no += 1

            p_diag.push({
              "size" => 19,
              "move" => [1050+x+rr_remove_x2, 580+y+y2+rr_remove_y2],
              "text" => pstring
            })
          else
            if !point.empty?
              ptensu, pcount = point.split(/ x /)
              pstring = word2kotei2(ptensu, 8).sub(/-/, "▲") + " x" + word2kotei2(pcount, 3)
              p_diag.push({
                "size" => 19,
                "move" => [1050+x+rr_remove_x2, 580+y+y2+rr_remove_y2],
                "text" => pstring
              })
            end
          end

          y2 += 25
          diag_no += 1
        else
          # 次ページ以降
          if @rosai
            if @hospital
              rr_remove_x = 0
              rr_remove_y = -520
            else
              rr_remove_x = 0
              rr_remove_y = -350
            end
          else
            rr_remove_x = 0
            rr_remove_y = 0
          end

          if !no.empty?
            if !futan_no.empty?
              p_next_skbn[npage].push({
                "size" => 19,
                "move" => [92+x+x3+rr_remove_x, 230+y+y3+rr_remove_y],
                "text" => futan_no
              })
            end
          end

          p_next_diag[npage].push({
            "size" => 19,
            "move" => [120+x+x3+rr_remove_x, 230+y+y3+rr_remove_y],
            "text" => name_plus_tani
          })

          # 労災 金額,点数改行[次ページ]
          if /　/ =~ point
            money, tensu = point.split(/　/)
            mtensu, mcount = money.split(/ x /)
            ptensu, pcount = tensu.split(/ x /)
            mstring = word2kotei2(mtensu, 8).sub(/-/, "▲") + " x" + word2kotei2(mcount, 3)
            pstring = word2kotei2(ptensu, 8).sub(/-/, "▲") + " x" + word2kotei2(pcount, 3)

            p_next_diag[npage].push({
              "size" => 19,
              "move" => [495+x+x3+rr_remove_x, 230+y+y3+rr_remove_y],
              "text" => mstring
            })

            y3 += 25
            next_diag_no += 1

            p_next_diag[npage].push({
              "size" => 19,
              "move" => [495+x+x3+rr_remove_x, 230+y+y3+rr_remove_y],
              "text" => pstring
            })
          else
            if !point.empty?
              ptensu, pcount = point.split(/ x /)
              pstring = word2kotei2(ptensu, 8).sub(/-/, "▲") + " x" + word2kotei2(pcount, 3)
              name3 = name_plus_tani + pstring
              name3_size = word_size(name3)

              if name3_size >= max_size
                y3 += 25
                diag_no += 1
              end

              p_next_diag[npage].push({
                "size" => 19,
                "move" => [495+x+x3+rr_remove_x, 230+y+y3+rr_remove_y],
                "text" => pstring
              })
            end
          end

          y3 += 25
          next_diag_no += 1
        end
      end
      no_history = no if no != no_history and !no.empty?
    end

    all_page_count += diag_no

    # 次ページ表示
    if p_next_diag[0].size != 0
      if @rosai
        next_point_x = 800
        if @hospital
          next_point_y = 1110
        else
          next_point_y = 1285
        end
      else
        next_point_x = 800
        if @hospital
          next_point_y = 1245
        else
          next_point_y = 1445
        end
      end

      p_diag.push({
        "size" => 19,
        "move" => [next_point_x+x, next_point_y+y],
        "text" => @next_str
      })
    end

    # 次回表示ページ
    if p_next_diag[npage].size != 0
      if next_diag_no < page_line_max["max"]
        # 次ページ以降
        if @rosai
          if @hospital
            rr_remove_x = 5
            rr_remove_y = -520
          else
            rr_remove_x = 5
            rr_remove_y = -350
          end
        else
          rr_remove_x = 0
          rr_remove_y = 0
        end
        p_next_diag[npage].push({
          "size" => 1,
          "move" => [110+x+x3+rr_remove_x, 225+y+y3+rr_remove_y],
          "line" => [620+x+x3+rr_remove_x, 225+y+y3+rr_remove_y],
          "text" => false,
          "stat" => [12, 6, 0]
        })
      end
    else
      if p_diag.size != 0 and diag_no < page_line_max["first"]
        p_diag.push({
          "size" => 1,
          "move" => [650+x, 575+y+y2],
          "line" => [1187+x, 575+y+y2],
          "text" => false,
          "stat" => [12, 6, 0]
        })
      end
    end

    p_diag.concat(p_skbn)
    p_next_diag.each_with_index do |next_diag, pn_index|
      if !next_diag.nil?
        next_diag.concat(p_next_skbn[pn_index])
      end
    end

    totel_fm = {}

    totel_fm["120_sum"] = [0,0]
    totel_fm["120_point"] = 0
    totel_fm["120_int"] = 0
    totel_fm["120_no"] = 0
    totel_fm["122_sum"] = [0,0]
    totel_fm["122_point"] = 0
    totel_fm["122_int"] = 0
    totel_fm["122_no"] = 0
    totel_fm["123_sum"] = [0,0]
    totel_fm["123_point"] = 0
    totel_fm["123_int"] = 0
    totel_fm["123_no"] = 0
    totel_fm["124_sum"] = [0,0]
    totel_fm["124_point"] = 0
    totel_fm["124_int"] = 0
    totel_fm["124_no"] = 0
    totel_fm["125_sum"] = [0,0]
    totel_fm["125_point"] = 0
    totel_fm["125_int"] = 0
    totel_fm["125_no"] = 0

    totel_fm["130_sum"] = [0,0]
    totel_fm["130_point"] = 0
    totel_fm["130_int"] = 0
    totel_fm["130_no"] = 0

    totel_fm["140_sum"] = [0,0]
    totel_fm["140_int"] = 0

    totel_fm["141_sum"] = 0
    totel_fm["141_point"] = 0
    totel_fm["141_int"] = 0
    totel_fm["142_sum"] = 0
    totel_fm["142_point"] = 0
    totel_fm["142_int"] = 0
    totel_fm["143_sum"] = 0
    totel_fm["143_point"] = 0
    totel_fm["143_int"] = 0

    totel_fm["210_sum"] = [0,0]
    totel_fm["210_point"] = 0
    totel_fm["210_int"] = 0
    totel_fm["211_sum"] = [0,0]
    totel_fm["211_point"] = 0
    totel_fm["211_int"] = 0

    totel_fm["220_sum"] = [0,0]
    totel_fm["220_point"] = 0
    totel_fm["220_int"] = 0

    totel_fm["230_sum"] = [0,0]
    totel_fm["230_point"] = 0
    totel_fm["230_int"] = 0
    totel_fm["231_sum"] = [0,0]
    totel_fm["231_point"] = 0
    totel_fm["231_int"] = 0

    totel_fm["240_sum"] = [0,0]
    totel_fm["240_point"] = 0
    totel_fm["240_int"] = 0
    totel_fm["250_sum"] = [0,0]
    totel_fm["250_point"] = 0
    totel_fm["250_int"] = 0
    totel_fm["260_sum"] = [0,0]
    totel_fm["260_point"] = 0
    totel_fm["260_int"] = 0
    totel_fm["270_sum"] = [0,0]
    totel_fm["270_point"] = 0
    totel_fm["270_int"] = 0

    totel_fm["310_sum"] = [0,0]
    totel_fm["310_point"] = 0
    totel_fm["310_int"] = 0
    totel_fm["320_sum"] = [0,0]
    totel_fm["320_point"] = 0
    totel_fm["320_int"] = 0
    totel_fm["330_sum"] = [0,0]
    totel_fm["330_point"] = 0
    totel_fm["330_int"] = 0

    totel_fm["400_sum"] = [0,0]
    totel_fm["400_point"] = 0
    totel_fm["400_int"] = 0

    totel_fm["500_sum"] = [0,0]
    totel_fm["500_point"] = 0
    totel_fm["500_int"] = 0
    totel_fm["540_sum"] = [0,0]
    totel_fm["540_point"] = 0
    totel_fm["540_int"] = 0

    totel_fm["600_sum"] = [0,0]
    totel_fm["600_point"] = 0
    totel_fm["600_int"] = 0

    totel_fm["700_sum"] = [0,0]
    totel_fm["700_point"] = 0
    totel_fm["700_int"] = 0

    totel_fm["800_sum"] = [0,0]
    totel_fm["800_point"] = 0
    totel_fm["800_int"] = 0

    totel_fm["903_sum"] = [0,0]
    totel_fm["920_sum"] = [0,0]

    totel_fm["970_sum"] = 0
    totel_fm["970_point"] = 0

    totel_fm["971_sum"] = ["","","","",""]

    totel_fm["972_sum"] = 0
    # totel_fm["972_point"] = 0

    totel_fm["973_sum"] = ["","","","",""]

    totel_fm["974_sum"] = 0
    # totel_fm["974_point"] = 0

    totel_fm["975_sum"] = ["","","","",""]

    totel_fm_ex = 0
    totel_fm_ex_point = [0,0]
    totel_fm_ex_money = {}
    totel_fm_ex_freq = {}

    fm_ex_fno = 0
    fm_remove_x = 0

    # 初診 金額,点数分離
    totel_fm_ex_money["11"] = 0
    totel_fm_ex_freq["11"] = 0
    first_medical_11.each do |fm_ex|
      rosai_fm = fm_ex[0].split(/　/)
      case rosai_fm.size
      when 1
        m_tmp = rosai_fm[0].gsub(/ /, "").split(/円x/)
        case m_tmp.size
        when 1
          # 点数
          ten, freq = rosai_fm[0].gsub(/ /, "").split(/x/)
          point = ten.to_i * freq.to_i
          totel_fm_ex += freq.to_i if point != 0
          totel_fm_ex_point = set_futan_group(0, totel_fm_ex_point, point)
        when 2
          # 金額
          mpoint, mfreq = m_tmp
          totel_fm_ex_money["11"] += mpoint.to_i
        end
      when 2
        #金額,点数
        mpoint, mfreq = rosai_fm[0].gsub(/ /, "").split(/円x/)
        ten, freq = rosai_fm[1].gsub(/ /, "").split(/x/)
        point = ten.to_i * freq.to_i

        totel_fm_ex_money["11"] += mpoint.to_i
        totel_fm_ex += freq.to_i if point != 0
        totel_fm_ex_point[0] += ten.to_i
      else
      end
    end

    # 再診 金額,点数分離
    totel_fm_ex_money["12"] = 0
    totel_fm_ex_freq["12"] = 0
    first_medical_12.each do |fm|
      rosai_fm = fm[1].split(/　/)
      kbn = fm[2]
      case rosai_fm.size
      when 1
        m_tmp = rosai_fm[0].gsub(/ /, "").split(/円x/)
        case m_tmp.size
        when 1
          # 点数
          ten, freq = rosai_fm[0].gsub(/ /, "").split(/x/)
          point = ten.to_i * freq.to_i
          fm_ex_fno = chutan_check(fm[3].to_s).to_i
          ten, freq = fm[1].gsub(/ /, "").split(/x/)
        when 2
          # 金額
          mpoint, mfreq = m_tmp
          totel_fm_ex_money["12"] += mpoint.to_i * mfreq.to_i
          totel_fm_ex_freq["12"] += mfreq.to_i
        end
      when 2
        #金額,点数
        mpoint, mfreq = rosai_fm[0].gsub(/ /, "").split(/円x/)
        ten, freq = rosai_fm[1].gsub(/ /, "").split(/x/)
        point = ten.to_i * freq.to_i

        totel_fm_ex_money["12"] += mpoint.to_i * mfreq.to_i
        totel_fm_ex_freq["12"] += mfreq.to_i
      else
      end

      # /再診/
      if "120" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["120_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["120_sum"], point)
        totel_fm["120_int"] += freq.to_i if ten.to_i > -1
        totel_fm["120_point"] = ten
        totel_fm["120_no"] = fm_ex_fno
      # /外来管理加算/
      elsif "122" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["122_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["122_sum"], point)
        totel_fm["122_int"] += freq.to_i if ten.to_i > -1
        totel_fm["122_point"] = ten
        totel_fm["122_no"] = fm_ex_fno
      # /時間外加算/
      elsif "123" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["123_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["123_sum"], point)
        totel_fm["123_int"] += freq.to_i if ten.to_i > -1
        totel_fm["123_point"] = ten
        totel_fm["123_no"] = fm_ex_fno
      # /休日加算/
      elsif "124" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["124_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["124_sum"], point)
        totel_fm["124_int"] += freq.to_i if ten.to_i > -1
        totel_fm["124_point"] = ten
        totel_fm["124_no"] = fm_ex_fno
      # /深夜加算/
      elsif "125" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["125_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["125_sum"], point)
        totel_fm["125_int"] += freq.to_i if ten.to_i > -1
        totel_fm["125_point"] = ten
        totel_fm["125_no"] = fm_ex_fno
      else
        point = ten.to_i * freq.to_i
        totel_fm["120_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["120_sum"], point)
        totel_fm["120_int"] += freq.to_i if ten.to_i > -1
        totel_fm["120_point"] = ten
        totel_fm["120_no"] = fm_ex_fno
      end
    end

    # 指導 金額,点数分離
    totel_fm_ex_money["13"] = 0
    totel_fm_ex_freq["13"] = 0
    first_medical_13.each do |fm|
      rosai_fm = fm[1].split(/　/)
      kbn = fm[2]
      case rosai_fm.size
      when 1
        m_tmp = rosai_fm[0].gsub(/ /, "").split(/円x/)
        case m_tmp.size
        when 1
          # 点数
          ten, freq = rosai_fm[0].gsub(/ /, "").split(/x/)
          point = ten.to_i * freq.to_i
          fm_ex_fno = chutan_check(fm[3].to_s).to_i
          ten, freq = fm[1].gsub(/ /, "").split(/x/)
        when 2
          # 金額
          mpoint, mfreq = m_tmp
          totel_fm_ex_money["13"] += mpoint.to_i * mfreq.to_i
          totel_fm_ex_freq["13"] += mfreq.to_i
        end
      when 2
        #金額,点数
        mpoint, mfreq = rosai_fm[0].gsub(/ /, "").split(/円x/)
        ten, freq = rosai_fm[1].gsub(/ /, "").split(/x/)
        point = ten.to_i * freq.to_i

        totel_fm_ex_money["13"] += mpoint.to_i * mfreq.to_i
        totel_fm_ex_freq["13"] += mfreq.to_i
      else
      end

      # /医学管理/
      if "130" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["130_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["130_sum"], point)
        totel_fm["130_int"] += freq.to_i
        totel_fm["130_point"] = ten
        totel_fm["130_no"] = fm_ex_fno
      end
    end

    first_medical_14.each do |fm|
      # name = fm[0]
      kbn  = fm[2]
      fm_ex_fno = chutan_check(fm[3].to_s).to_i
      ten, freq = fm[1].gsub(/ /, "").split(/x/)
      # /在宅管理/
      if "141" == kbn
        totel_fm["141_int"] += freq.to_i
        totel_fm["141_point"] = ten
        totel_fm["141_sum"] += ten.to_i * freq.to_i
        totel_fm["141_no"] = fm_ex_fno
      elsif "142" == kbn
        totel_fm["142_int"] += freq.to_i
        totel_fm["142_point"] = ten
        totel_fm["142_sum"] += ten.to_i * freq.to_i
        totel_fm["142_no"] = fm_ex_fno
      elsif "143" == kbn
        totel_fm["143_int"] += freq.to_i
        totel_fm["143_point"] = ten
        totel_fm["143_sum"] += ten.to_i * freq.to_i
        totel_fm["143_no"] = fm_ex_fno
      end
      point = ten.to_i * freq.to_i
      totel_fm["140_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["140_sum"], point)
      totel_fm["140_int"] += freq.to_i
      totel_fm["140_no"] = fm_ex_fno
    end

    first_medical_20.each do |fm|
      # name = fm[0]
      kbn  = fm[2]
      fm_ex_fno = chutan_check(fm[3].to_s).to_i
      ten, freq = fm[1].gsub(/ /, "").split(/x/)
      # /投薬/
      if "210" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["210_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["210_sum"], point)
        totel_fm["210_int"] += freq.to_i if ten.to_i > -1
        totel_fm["210_point"] = ten.to_i
      elsif "211" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["211_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["211_sum"], point)
        totel_fm["211_int"] += freq.to_i if ten.to_i > -1
        totel_fm["211_point"] = ten.to_i
      elsif "220" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["220_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["220_sum"], point)
        totel_fm["220_int"] += freq.to_i if ten.to_i > -1
        totel_fm["220_point"] = ten.to_i
      elsif "230" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["230_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["230_sum"], point)
        totel_fm["230_int"] += freq.to_i if ten.to_i > -1
        totel_fm["230_point"] += ten.to_i
      elsif "231" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["231_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["231_sum"], point)
        totel_fm["231_int"] += freq.to_i if ten.to_i > -1
        totel_fm["231_point"] += ten.to_i
      elsif "240" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["240_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["240_sum"], point)
        totel_fm["240_int"] += freq.to_i if ten.to_i > -1
        totel_fm["240_point"] = ten
      elsif "250" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["250_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["250_sum"], point)
        totel_fm["250_int"] += freq.to_i if ten.to_i > -1
        totel_fm["250_point"] = ten
      elsif "260" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["260_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["260_sum"], point)
        totel_fm["260_int"] += freq.to_i if ten.to_i > -1
        totel_fm["260_point"] = ten
      elsif "270" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["270_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["270_sum"], point)
        totel_fm["270_int"] += freq.to_i if ten.to_i > -1
        totel_fm["270_point"] = ten
      end
    end

    first_medical_30.each do |fm|
      kbn = fm[2]
      blink = fm[4]
      fm_ex_fno = chutan_check(fm[3].to_s).to_i
      ten, freq = fm[1].gsub(/ /, "").split(/x/)
      # /注射/
      if "300" == kbn or "310" == kbn or "311" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["310_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["310_sum"], point)
        totel_fm["310_int"] += freq.to_i if blink
        totel_fm["310_point"] = ten
      elsif "320" == kbn or "321" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["320_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["320_sum"], point)
        totel_fm["320_int"] += freq.to_i if blink
        totel_fm["320_point"] = ten
      elsif "330" == kbn or "331" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["330_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["330_sum"], point)
        totel_fm["330_int"] += freq.to_i if blink
        totel_fm["330_point"] = ten
      end
    end

    first_medical_40.each do |fm|
      kbn = fm[2]
      blink = fm[4]
      fm_ex_fno = chutan_check(fm[3].to_s).to_i
      ten, freq = fm[1].gsub(/ /, "").split(/x/)
      # /処置/
      if "400" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["400_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["400_sum"], point)
        totel_fm["400_int"] += freq.to_i if blink
        totel_fm["400_point"] = ten
      end
    end

    first_medical_50.each do |fm|
      # name = fm[0]
      kbn  = fm[2]
      fm_ex_fno = chutan_check(fm[3].to_s).to_i
      ten, freq = fm[1].gsub(/ /, "").split(/x/)
      # /手術/
      if "500" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["500_sum"] = set_futan_group(fm_ex_fno,
                                            totel_fm["500_sum"], point)
        totel_fm["500_int"] += freq.to_i
        totel_fm["500_point"] = ten
      # /輸血/
      elsif "502" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["500_sum"] = set_futan_group(fm_ex_fno,
                                            totel_fm["500_sum"], point)
        totel_fm["500_int"] += freq.to_i
        totel_fm["500_point"] = ten
      elsif "540" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["540_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["540_sum"], point)
        totel_fm["540_int"] += freq.to_i
        totel_fm["540_point"] = ten
      end
    end

    first_medical_60.each do |fm|
      # name = fm[0]
      kbn  = fm[2]
      fm_ex_fno = chutan_check(fm[3].to_s).to_i
      ten, freq = fm[1].gsub(/ /, "").split(/x/)
      # /検査/
      if "600" == kbn or "640" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["600_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["600_sum"], point)
        totel_fm["600_int"] += freq.to_i
        totel_fm["600_point"] = ten
      end
    end

    first_medical_70.each do |fm|
      kbn = fm[2]
      fm_ex_fno = chutan_check(fm[3].to_s).to_i
      ten, freq = fm[1].gsub(/ /, "").split(/x/)
      # /画像診断/
      if "700" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["700_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["700_sum"], point)
        totel_fm["700_int"] += freq.to_i
        totel_fm["700_point"] = ten
      end
    end

    # その他 金額,点数分離
    totel_fm_ex_money["80"] = 0
    totel_fm_ex_freq["80"] = 0
    first_medical_80.each do |fm|
      rosai_fm = fm[1].split(/　/)
      kbn = fm[2]
      case rosai_fm.size
      when 1
        m_tmp = rosai_fm[0].gsub(/ /, "").split(/円x/)
        case m_tmp.size
        when 1
          # 点数
          ten, freq = rosai_fm[0].gsub(/ /, "").split(/x/)
          point = ten.to_i * freq.to_i
          fm_ex_fno = chutan_check(fm[3].to_s).to_i
          ten, freq = fm[1].gsub(/ /, "").split(/x/)
        when 2
          # 金額
          mpoint, mfreq = m_tmp
          totel_fm_ex_money["80"] += mpoint.to_i * mfreq.to_i
          totel_fm_ex_freq["80"] += mfreq.to_i
        end
      when 2
        #金額,点数
        mpoint, mfreq = rosai_fm[0].gsub(/ /, "").split(/円x/)
        ten, freq = rosai_fm[1].gsub(/ /, "").split(/x/)
        point = ten.to_i * freq.to_i

        totel_fm_ex_money["80"] += mpoint.to_i * mfreq.to_i
        totel_fm_ex_freq["80"] += mfreq.to_i
      else
      end

      # /その他/
      if "800" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["800_sum"] = set_futan_group(fm_ex_fno, totel_fm["800_sum"], point)
        totel_fm["800_int"] += freq.to_i
        totel_fm["800_point"] = ten
      end
    end

    first_medical_90.each do |fm|
      # name = fm[0]
      kbn  = fm[2]
      fm_ex_fno = chutan_check(fm[3].to_s).to_i
      tani = fm[4]
      ten, freq = fm[1].gsub(/ /, "").split(/x/)
      ameal = fm[5]
      ameal_fkbn = chutan_check(fm[3].to_s, "bit").to_i
      # /入院/
      if "903" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["903_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["903_sum"], point)
        totel_fm["903_array"] = [] if totel_fm["903_array"].nil?
        totel_fm["903_array"].push([point.to_i, ten.to_i, freq.to_i])
      elsif "920" == kbn
        point = ten.to_i * freq.to_i
        totel_fm["920_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["920_sum"], point)
      elsif "970" == kbn
        totel_fm["970_point"] += tani.to_i * freq.to_i
        totel_fm["970_sum"] += ten.to_i * freq.to_i
        totel_fm["970_array"] = [] if totel_fm["970_array"].nil?
        totel_fm["970_array"].push([point.to_i, ten.to_i, freq.to_i, tani.to_i])
      elsif "971" == kbn
        if ameal
          point_971x = ten.to_i * freq.to_i

          totel_fm["971_sum"] = set_futan_group(ameal_fkbn,
            totel_fm["971_sum"], point_971x, "5way")
        end
      elsif "972" == kbn
        # totel_fm["972_point"] += tani.to_i * freq.to_i
        totel_fm["972_sum"] += ten.to_i * freq.to_i
      elsif "973" == kbn
        if ameal
          point_973x = ten.to_i * freq.to_i

          totel_fm["973_sum"] = set_futan_group(ameal_fkbn,
            totel_fm["973_sum"], point_973x, "5way")
        end
      elsif "974" == kbn
        # tani = 1 if tani.to_i == 0
        # totel_fm["974_point"] += tani.to_i * freq.to_i
        totel_fm["974_sum"] += ten.to_i * freq.to_i
      elsif "975" == kbn
        if ameal
          point_975x = ten.to_i * freq.to_i

          totel_fm["975_sum"] = set_futan_group(ameal_fkbn,
            totel_fm["975_sum"], point_975x, "5way")
        end
      else
        point = ten.to_i * freq.to_i
        totel_fm["903_sum"] = set_futan_group(fm_ex_fno, 
                                            totel_fm["903_sum"], point)
      end
    end

    # 初診
    if totel_fm_ex != 0
      if @rosai
        ex_11 = totel_fm_ex.to_s
        ex_11_point1 = totel_fm_ex_point[0].to_s
        ex_11_point2 = totel_fm_ex_point[1].to_s
        if @hospital
          fm_remove_x = 100
          fm_remove_y = -426
        else
          fm_remove_x = 105
          fm_remove_y = -256
        end
      else
        ex_11 = totel_fm_ex.to_s
        ex_11_point1 = totel_fm_ex_point[0].to_s
        ex_11_point2 = totel_fm_ex_point[1].to_s
        fm_remove_x = 0
        fm_remove_y = 0
      end

      p_ten.push({
        "size" => 20,
        "move" => [345+x+fm_remove_x, 628+y+fm_remove_y],
        "text" => word2kotei2(ex_11, 2)
      })

      # 保険 点
      if ex_11_point1 != "0"
        p_ten.push({
          "size" => 20,
          "move" => [380+x+fm_remove_x, 628+y+fm_remove_y],
          "text" => word2kotei2(ex_11_point1, 10)
        })
      end

      # 公費 点
      if ex_11_point2 != "0"
        p_ten.push({
          "size" => 20,
          "move" => [493+x+fm_remove_x, 628+y+fm_remove_y],
          "text" => word2kotei2(ex_11_point2, 10)
        })
      end
    end

    # 初診 労災 金額
    if totel_fm_ex_money["11"] != 0
      if @rosai
        if @hospital
          fm_remove_x = 0
          fm_remove_y = -173
        else
          fm_remove_x = 0
          fm_remove_y = 0
        end
      else
        fm_remove_x = 0
        fm_remove_y = 0
      end

      p_ten.push({
        "size" => 18,
        "move" => [800+x+fm_remove_x, 371+y+fm_remove_y],
        "text" => word2kotei2(int2kanma(totel_fm_ex_money["11"].to_s), 11)
      })
    end

    # 再診 保険
    if totel_fm["120_point"] != 0 and !@hospital
      if @rosai
        fm_remove_x = 105
        fm_remove_y = -262
      else
        fm_remove_x = 0
        fm_remove_y = 0
      end

      # 回数
      if totel_fm["120_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [345+x+fm_remove_x, 658+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["120_int"].to_s, 2)
        })
      end

      # 保険点数
      if totel_fm["120_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 658+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["120_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["120_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 658+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["120_sum"][1].to_s, 8)
        })
      end
    end

    # 再診 外来管理加算
    if totel_fm["122_point"] != 0 and !@hospital
      if @rosai
        fm_remove_x = 105
        fm_remove_y = -262
      else
        fm_remove_x = 0
        fm_remove_y = 0
      end
      # 回数
      if totel_fm["122_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [345+x+fm_remove_x, 683+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["122_int"].to_s, 2)
        })
      end

      # 保険点数
      if totel_fm["122_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 683+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["122_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["122_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 683+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["122_sum"][1].to_s, 8)
        })
      end
    end

    # 再診 時間外
    if totel_fm["123_point"] != 0 and !@hospital
      if @rosai
        fm_remove_x = 105
        fm_remove_y = -262
      else
        fm_remove_x = 0
        fm_remove_y = 0
      end
      # 回数
      if totel_fm["123_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [345+x+fm_remove_x, 708+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["123_int"].to_s, 2)
        })
      end

      # 保険点数
      if totel_fm["123_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 708+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["123_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["123_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 708+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["123_sum"][1].to_s, 8)
        })
      end
    end

    # 再診 休日
    if totel_fm["124_point"] != 0 and !@hospital
      if @rosai
        fm_remove_x = 105
        fm_remove_y = -262
      else
        fm_remove_x = 0
        fm_remove_y = 0
      end
      # 回数
      if totel_fm["124_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [345+x+fm_remove_x, 732+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["124_int"].to_s, 2)
        })
      end

      # 保険点数
      if totel_fm["124_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 732+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["124_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["124_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 732+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["124_sum"][1].to_s, 8)
        })
      end
    end

    # 再診 深夜
    if totel_fm["125_point"] != 0 and !@hospital
      if @rosai
        fm_remove_x = 105
        fm_remove_y = -262
      else
        fm_remove_x = 0
        fm_remove_y = 0
      end
      # 回数
      if totel_fm["125_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [345+x+fm_remove_x, 756+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["125_int"].to_s, 2)
        })
      end

      # 保険点数
      if totel_fm["125_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 756+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["125_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["125_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 756+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["125_sum"][1].to_s, 8)
        })
      end
    end

    # 再診 労災 金額
    if totel_fm_ex_money["12"] != 0 and !@hospital
      p_ten.push({
        "size" => 18,
        "move" => [800+x, 396+y],
        "text" => word2kotei2(int2kanma(totel_fm_ex_money["12"].to_s), 11)
      })
      p_ten.push({
        "size" => 18,
        "move" => [720+x, 396+y],
        "text" => word2kotei2(totel_fm_ex_freq["12"].to_s, 3)
      })
    end

    # 指導 労災 金額
    if totel_fm_ex_money["13"] != 0 and !@hospital
      p_ten.push({
        "size" => 18,
        "move" => [800+x, 421+y],
        "text" => word2kotei2(int2kanma(totel_fm_ex_money["13"].to_s), 11)
      })
      p_ten.push({
        "size" => 18,
        "move" => [720+x, 421+y],
        "text" => word2kotei2(totel_fm_ex_freq["13"].to_s, 3)
      })
    end

    # その他 労災 金額
    if totel_fm_ex_money["80"] != 0
      if @hospital
        p_ten.push({
          "size" => 18,
          "move" => [800+x, 222+y],
          "text" => word2kotei2(int2kanma(totel_fm_ex_money["80"].to_s), 11)
        })
      else
        p_ten.push({
          "size" => 18,
          "move" => [800+x, 445+y],
          "text" => word2kotei2(int2kanma(totel_fm_ex_money["80"].to_s), 11)
        })
      end
    end

    # 医学管理
    if totel_fm["130_point"] != 0
      if @rosai
        if @hospital
          fm_remove_x = 100
          fm_remove_y = -565
        else
          fm_remove_x = 105
          fm_remove_y = -268
        end
      else
        if @hospital
          fm_remove_x = 0
          fm_remove_y = -130
        else
          fm_remove_x = 0
          fm_remove_y = 0
        end
      end

      # 保険点数
      if totel_fm["130_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 790+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["130_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["130_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 790+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["130_sum"][1].to_s, 8)
        })
      end
    end

    # 在宅
    if totel_fm["140_int"] != 0
      if @rosai
        if @hospital
          fm_remove_x = 100
          fm_remove_y = -568
        else
          fm_remove_x = 105
          fm_remove_y = -271
        end
      else
        if @hospital
          fm_remove_x = 0
          fm_remove_y = -130
        else
          fm_remove_x = 0
          fm_remove_y = 0
        end
      end

      # 保険点数
      if totel_fm["140_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 819+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["140_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["140_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 819+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["140_sum"][1].to_s, 8)
        })
      end
    end

    # 在宅 区分区切り
=begin
    if totel_fm["141_point"] != 0
      p_ten.push({
        "size" => 20,
        "move" => [345+x, 770+y],
        "text" => word2kotei2(totel_fm["141_int"].to_s, 2)
      })

      p_ten.push({
        "size" => 20,
        "move" => [400+x, 770+y],
        "text" => word2kotei2(totel_fm["141_sum"].to_s, 8)
      })
    end

    if totel_fm["142_point"] != 0
      p_ten.push({
        "size" => 20,
        "move" => [345+x, 793+y],
        "text" => word2kotei2(totel_fm["142_int"].to_s, 2)
      })

      p_ten.push({
        "size" => 20,
        "move" => [400+x, 793+y],
        "text" => word2kotei2(totel_fm["142_sum"].to_s, 8)
      })
    end

    if totel_fm["143_point"] != 0
      p_ten.push({
        "size" => 20,
        "move" => [345+x, 816+y],
        "text" => word2kotei2(totel_fm["143_int"].to_s, 2)
      })

      p_ten.push({
        "size" => 20,
        "move" => [400+x, 816+y],
        "text" => word2kotei2(totel_fm["143_sum"].to_s, 8)
      })
    end

    if totel_fm["144_point"] != 0
      p_ten.push({
        "size" => 20,
        "move" => [345+x, 839+y],
        "text" => word2kotei2(totel_fm["144_int"].to_s, 2)
      })

      p_ten.push({
        "size" => 20,
        "move" => [400+x, 839+y],
        "text" => word2kotei2(totel_fm["144_sum"].to_s, 8)
      })
    end
=end

    # 内服薬剤
    if totel_fm["210_sum"][0] != 0 or totel_fm["210_sum"][1] != 0
      if @rosai
        if @hospital
          if @rosai_s
            fm_remove_x = 100
            fm_remove_y = -573
          else
            fm_remove_x = 100
            fm_remove_y = -575
          end
        else
          if @rosai_s
            fm_remove_x = 105
            fm_remove_y = -154
          else
            fm_remove_x = 105
            fm_remove_y = -149
          end
        end
      else
        if @hospital
          fm_remove_x = 0
          fm_remove_y = -132
        else
          fm_remove_x = 0
          fm_remove_y = 0
        end
      end

      # 剤回数
      if totel_fm["210_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [335+x+fm_remove_x, 848+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["210_int"].to_s, 3)
        })
      end

      # 保険点数
      if totel_fm["210_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 848+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["210_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["210_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 848+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["210_sum"][1].to_s, 8)
        })
      end
    end

    # 内服調剤
    if totel_fm["211_point"] != 0 and !@hospital
      if @rosai
        if @rosai_s
          fm_remove_x = 105
          fm_remove_y = -165
        else
          fm_remove_x = 105
          fm_remove_y = -161
        end
      else
        fm_remove_x = 0
        fm_remove_y = 0
      end

      # 剤回数
      if totel_fm["211_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [335+x+fm_remove_x, 885+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["211_int"].to_s, 3)
        })
      end

      # 保険点数
      if totel_fm["211_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 885+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["211_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["211_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 885+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["211_sum"][1].to_s, 8)
        })
      end
    end

    # 頓服薬剤
    if totel_fm["220_point"] != 0
      if @rosai
        if @hospital
          if @rosai_s
            fm_remove_x = 100
            fm_remove_y = -625
          else
            fm_remove_x = 100
            fm_remove_y = -627
          end
        else
          if @rosai_s
            fm_remove_x = 105
            fm_remove_y = -180
          else
            fm_remove_x = 105
            fm_remove_y = -175
          end
        end
      else
        if @hospital
          fm_remove_x = 0
          fm_remove_y = -167
        else
          fm_remove_x = 0
          fm_remove_y = 0
        end
      end

      # 剤回数
      if totel_fm["220_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [335+x+fm_remove_x, 924+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["220_int"].to_s, 3)
        })
      end

      # 保険点数
      if totel_fm["220_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 924+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["220_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["220_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 924+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["220_sum"][1].to_s, 8)
        })
      end
    end

    # 外用薬剤
    if totel_fm["230_point"] != 0
      if @rosai
        if @hospital
          if @rosai_s
            fm_remove_x = 100
            fm_remove_y = -634
          else
            fm_remove_x = 100
            fm_remove_y = -636
          end
        else
          if @rosai_s
            fm_remove_x = 105
            fm_remove_y = -188
          else
            fm_remove_x = 105
            fm_remove_y = -183
          end
        end
      else
        if @hospital
          fm_remove_x = 0
          fm_remove_y = -161
        else
          fm_remove_x = 0
          fm_remove_y = 0
        end
      end

      # 剤回数
      if totel_fm["230_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [335+x+fm_remove_x, 957+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["230_int"].to_s, 3)
        })
      end

      # 保険点数
      if totel_fm["230_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 957+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["230_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["230_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 957+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["230_sum"][1].to_s, 8)
        })
      end
    end

    # 外用調剤
    if totel_fm["231_point"] != 0 and !@hospital
      if @rosai
        if @rosai_s
          fm_remove_x = 105
          fm_remove_y = -194
        else
          fm_remove_x = 105
          fm_remove_y = -190
        end
      else
        fm_remove_x = 0
        fm_remove_y = 0
      end

      # 剤回数
      if totel_fm["231_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [335+x+fm_remove_x, 989+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["231_int"].to_s, 3)
        })
      end

      # 保険点数
      if totel_fm["231_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 989+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["231_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["231_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 989+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["231_sum"][1].to_s, 8)
        })
      end
    end

    # 調剤
    if totel_fm["240_point"] != 0 and @hospital
      if @rosai
        if @rosai_s
          fm_remove_x = 100
          fm_remove_y = -646
        else
          fm_remove_x = 100
          fm_remove_y = -648
        end
      else
        fm_remove_x = 0
        fm_remove_y = -161
      end

      # 回数
      if totel_fm["240_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [335+x+fm_remove_x, 995+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["240_int"].to_s, 3)
        })
      end

      # 保険点数
      if totel_fm["240_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 995+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["240_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["240_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 995+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["240_sum"][1].to_s, 8)
        })
      end
    end

    # 処方
    if totel_fm["250_point"] != 0 and !@hospital
      if @rosai
        if @rosai_s
          fm_remove_x = 105
          fm_remove_y = -205
        else
          fm_remove_x = 105
          fm_remove_y = -201
        end
      else
        fm_remove_x = 0
        fm_remove_y = 0
      end

      # 回数
      if totel_fm["250_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [335+x+fm_remove_x, 1025+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["250_int"].to_s, 3)
        })
      end

      # 保険点数
      if totel_fm["250_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 1025+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["250_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["250_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 1025+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["250_sum"][1].to_s, 8)
        })
      end
    end

    # 麻毒
    if totel_fm["260_point"] != 0
      if @rosai
        if @hospital
          if @rosai_s
            fm_remove_x = 100
            fm_remove_y = -687
          else
            fm_remove_x = 100
            fm_remove_y = -689
          end
        else
          if @rosai_s
            fm_remove_x = 105
            fm_remove_y = -217
          else
            fm_remove_x = 105
            fm_remove_y = -213
          end
        end
      else
        if @hospital
          fm_remove_x = 0
          fm_remove_y = -192
        else
          fm_remove_x = 0
          fm_remove_y = 0
        end
      end

      # 回数
      if totel_fm["260_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [335+x+fm_remove_x, 1062+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["260_int"].to_s, 3)
        })
      end

      # 保険点数
      if totel_fm["260_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 1062+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["260_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["260_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 1062+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["260_sum"][1].to_s, 8)
        })
      end
    end

    # 調基
    if totel_fm["270_point"] != 0
      if @rosai
        if @hospital
          if @rosai_s
            fm_remove_x = 100
            fm_remove_y = -697
          else
            fm_remove_x = 100
            fm_remove_y = -698
          end
        else
          if @rosai_s
            fm_remove_x = 105
            fm_remove_y = -226
          else
            fm_remove_x = 105
            fm_remove_y = -223
          end
        end
      else
        if @hospital
          fm_remove_x = 0
          fm_remove_y = -192
        else
          fm_remove_x = 0
          fm_remove_y = 0
        end
      end

      # 保険点数
      if totel_fm["270_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 1096+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["270_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["270_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 1096+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["270_sum"][1].to_s, 8)
        })
      end
    end

    # 注射 皮下筋肉内
    if totel_fm["310_point"] != 0
      if @rosai
        if @hospital
          if @rosai_s
            fm_remove_x = 100
            fm_remove_y = -699
          else
            fm_remove_x = 100
            fm_remove_y = -701
          end
        else
          if @rosai_s
            fm_remove_x = 105
            fm_remove_y = -230
          else
            fm_remove_x = 105
            fm_remove_y = -226
          end
        end
      else
        if @hospital
          fm_remove_x = 0
          fm_remove_y = -186
        else
          fm_remove_x = 0
          fm_remove_y = 0
        end
      end

      # 回数
      if totel_fm["310_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [335+x+fm_remove_x, 1126+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["310_int"].to_s, 3)
        })
      end

      # 保険点数
      if totel_fm["310_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 1126+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["310_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["310_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 1126+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["310_sum"][1].to_s, 8)
        })
      end
    end

    # 注射 静脈内
    if totel_fm["320_point"] != 0
      if @rosai
        if @hospital
          if @rosai_s
            fm_remove_x = 100
            fm_remove_y = -715
          else
            fm_remove_x = 100
            fm_remove_y = -717
          end
        else
          if @rosai_s
            fm_remove_x = 105
            fm_remove_y = -246
          else
            fm_remove_x = 105
            fm_remove_y = -242
          end
        end
      else
        if @hospital
          fm_remove_x = 0
          fm_remove_y = -187
        else
          fm_remove_x = 0
          fm_remove_y = 0
        end
      end

      # 回数
      if totel_fm["320_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [335+x+fm_remove_x, 1167+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["320_int"].to_s, 3)
        })
      end

      # 保険点数
      if totel_fm["320_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 1167+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["320_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["320_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 1167+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["320_sum"][1].to_s, 8)
        })
      end
    end

    # 注射 その他
    if totel_fm["330_point"] != 0
      if @rosai
        if @hospital
          if @rosai_s
            fm_remove_x = 100
            fm_remove_y = -730
          else
            fm_remove_x = 100
            fm_remove_y = -731
          end
        else
          if @rosai_s
            fm_remove_x = 105
            fm_remove_y = -260
          else
            fm_remove_x = 105
            fm_remove_y = -256
          end
        end
      else
        if @hospital
          fm_remove_x = 0
          fm_remove_y = -184
        else
          fm_remove_x = 0
          fm_remove_y = 0
        end
      end

      # 回数
      if totel_fm["330_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [335+x+fm_remove_x, 1205+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["330_int"].to_s, 3)
        })
      end

      # 保険点数
      if totel_fm["330_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 1205+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["330_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["320_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 1205+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["330_sum"][1].to_s, 8)
        })
      end
    end

    # 処置
    if totel_fm["400_point"] != 0
      if @rosai
        if @hospital
          if @rosai_s
            fm_remove_x = 100
            fm_remove_y = -746
          else
            fm_remove_x = 100
            fm_remove_y = -748
          end
        else
          if @rosai_s
            fm_remove_x = 105
            fm_remove_y = -278
          else
            fm_remove_x = 105
            fm_remove_y = -274
          end
        end
      else
        if @hospital
          fm_remove_x = 0
          fm_remove_y = -181
        else
          fm_remove_x = 0
          fm_remove_y = 0
        end
      end

      # 回数
      if totel_fm["400_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [335+x+fm_remove_x, 1247+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["400_int"].to_s, 3)
        })
      end

      # 保険点数
      if totel_fm["400_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 1247+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["400_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["400_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 1247+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["400_sum"][1].to_s, 8)
        })
      end
    end

    # 手術
    if totel_fm["500_point"] != 0
      if @rosai
        if @hospital
          if @rosai_s
            fm_remove_x = 100
            fm_remove_y = -733
          else
            fm_remove_x = 100
            fm_remove_y = -735
          end
        else
          if @rosai_s
            fm_remove_x = 105
            fm_remove_y = -265
          else
            fm_remove_x = 105
            fm_remove_y = -260
          end
        end
      else
        if @hospital
          fm_remove_x = 0
          fm_remove_y = -185
        else
          fm_remove_x = 0
          fm_remove_y = 0
        end
      end

      # 回数
      if totel_fm["500_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [335+x+fm_remove_x, 1284+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["500_int"].to_s, 3)
        })
      end

      # 保険点数
      if totel_fm["500_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 1284+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["500_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["500_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 1284+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["500_sum"][1].to_s, 8)
        })
      end
    end

    # 麻酔
    if totel_fm["540_point"] != 0
      if @rosai
        if @hospital
          if @rosai_s
            fm_remove_x = 100
            fm_remove_y = -739
          else
            fm_remove_x = 100
            fm_remove_y = -741
          end
        else
          if @rosai_s
            fm_remove_x = 105
            fm_remove_y = -272
          else
            fm_remove_x = 105
            fm_remove_y = -267
          end
        end
      else
        if @hospital
          fm_remove_x = 0
          fm_remove_y = -184
        else
          fm_remove_x = 0
          fm_remove_y = 0
        end
      end

      # 回数
      if totel_fm["540_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [335+x+fm_remove_x, 1315+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["540_int"].to_s, 3)
        })
      end

      # 保険点数
      if totel_fm["540_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 1315+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["540_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["540_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 1315+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["540_sum"][1].to_s, 8)
        })
      end
    end

    # 検査・病理
    if totel_fm["600_point"] != 0
      if @rosai
        if @hospital
          if @rosai_s
            fm_remove_x = 100
            fm_remove_y = -760
          else
            fm_remove_x = 100
            fm_remove_y = -762
          end
        else
          if @rosai_s
            fm_remove_x = 105
            fm_remove_y = -290
          else
            fm_remove_x = 105
            fm_remove_y = -287
          end
        end
      else
        if @hospital
          fm_remove_x = 0
          fm_remove_y = -187
        else
          fm_remove_x = 0
          fm_remove_y = 0
        end
      end

      # 回数
      if totel_fm["600_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [335+x+fm_remove_x, 1361+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["600_int"].to_s, 3)
        })
      end

      # 保険点数
      if totel_fm["600_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 1361+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["600_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["600_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 1361+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["600_sum"][1].to_s, 8)
        })
      end
    end

    # 画像診断
    if totel_fm["700_point"] != 0
      if @rosai
        if @hospital
          if @rosai_s
            fm_remove_x = 100
            fm_remove_y = -752
          else
            fm_remove_x = 100
            fm_remove_y = -754
          end
        else
          if @rosai_s
            fm_remove_x = 105
            fm_remove_y = -283
          else
            fm_remove_x = 105
            fm_remove_y = -279
          end
        end
      else
        if @hospital
          fm_remove_x = 0
          fm_remove_y = -184
        else
          fm_remove_x = 0
          fm_remove_y = 0
        end
      end

      # 回数
      if totel_fm["700_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [335+x+fm_remove_x, 1404+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["700_int"].to_s, 3)
        })
      end

      # 保険点数
      if totel_fm["700_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 1404+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["700_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["700_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 1404+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["700_sum"][1].to_s, 8)
        })
      end
    end

    # その他
    if totel_fm["800_point"] != 0
      if @rosai
        if @hospital
          if @rosai_s
            fm_remove_x = 100
            fm_remove_y = -744
          else
            fm_remove_x = 100
            fm_remove_y = -746
          end
        else
          if @rosai_s
            fm_remove_x = 105
            fm_remove_y = -275
          else
            fm_remove_x = 105
            fm_remove_y = -272
          end
        end
      else
        if @hospital
          fm_remove_x = 0
          fm_remove_y = -183
        else
          fm_remove_x = 0
          fm_remove_y = 0
        end
      end

      # 回数
      if totel_fm["800_int"] != 0
        p_ten.push({
          "size" => 20,
          "move" => [335+x+fm_remove_x, 1446+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["800_int"].to_s, 3)
        })
      end

      # 保険点数
      if totel_fm["800_sum"][0] != 0
        p_ten.push({
          "size" => 20,
          "move" => [400+x+fm_remove_x, 1446+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["800_sum"][0].to_s, 8)
        })
      end

      # 公費点数
      if totel_fm["800_sum"][1] != 0
        p_ten.push({
          "size" => 20,
          "move" => [513+x+fm_remove_x, 1446+y+fm_remove_y],
          "text" => word2kotei2(totel_fm["800_sum"][1].to_s, 8)
        })
      end
    end

    if @hospital
      if @rosai
        if !totel_fm["903_array"].nil?
          fm_remove_903_x = 0
          fm_remove_903_y = 0
          totel_fm["903_array"].each do |point, ten, freq|
            # 入院基本料 保険
            if ten != 0 and freq != 0
              p_ten.push({
                "size" => 20,
                "move" => [330+x+fm_remove_903_x, 800+y+fm_remove_903_y],
                "text" => word2kotei2(ten.to_s, 8)
              })
              p_ten.push({
                "size" => 20,
                "move" => [440+x+fm_remove_903_x, 800+y+fm_remove_903_y],
                "text" => word2kotei2(freq.to_s, 3)
              })
              p_ten.push({
                "size" => 20,
                "move" => [490+x+fm_remove_903_x, 800+y+fm_remove_903_y],
                "text" => word2kotei2(point.to_s, 9)
              })
              fm_remove_903_y += 25
            end
          end
        end
      else
        fm_remove_x = 0
        fm_remove_y = 0
        # 入院基本料 保険
        if totel_fm["903_sum"][0] != 0
          p_ten.push({
            "size" => 18,
            "move" => [320+x+fm_remove_x, 1343+y+fm_remove_y],
            "text" => sw2bw(word2kotei2(totel_fm["903_sum"][0].to_s, 9))
          })
        end

        # 入院基本料 公費
        if totel_fm["903_sum"][1] != 0
          p_ten.push({
            "size" => 18,
            "move" => [435+x+fm_remove_x, 1343+y+fm_remove_y],
            "text" => sw2bw(word2kotei2(totel_fm["903_sum"][1].to_s, 9))
          })
        end
      end

      # 特定入院料 保険
      if @rosai
        fm_remove_x = 180
        fm_remove_y = -410

        if totel_fm["920_sum"][0] != 0
          p_ten.push({
            "size" => 18,
            "move" => [320+x+fm_remove_x, 1382+y+fm_remove_y],
            "text" => word2kotei2(totel_fm["920_sum"][0].to_s, 9)
          })
        end
      else
        fm_remove_x = 0
        fm_remove_y = 0

        if totel_fm["920_sum"][0] != 0
          p_ten.push({
            "size" => 18,
            "move" => [320+x+fm_remove_x, 1382+y+fm_remove_y],
            "text" => sw2bw(word2kotei2(totel_fm["920_sum"][0].to_s, 9))
          })
        end

        # 特定入院料 公費
        if totel_fm["920_sum"][1] != 0
          p_ten.push({
            "size" => 18,
            "move" => [435+x+fm_remove_x, 1382+y+fm_remove_y],
            "text" => sw2bw(word2kotei2(totel_fm["920_sum"][1].to_s, 9))
          })
        end
      end

      # 食事・生活療養 食事回数 [再集計]
      if totel_fm["970_sum"] != 0 and !@rosai
        fm_remove_x = 0
        fm_remove_y = 0
        #
        # this Obsolete
        #
        # 食事回数
        #p_ten.push({
        #  "size" => 14,
        #  "move" => [710+x, 1525+y],
        #  "text" => sw2bw(word2kotei2(totel_fm["970_point"].to_s, 3))
        #})

        # 食事金額
        p_ten.push({
          "size" => 14,
          "move" => [715+x+fm_remove_x, 1353+y+fm_remove_y],
          "text" => sw2bw(word2kotei2(totel_fm["970_sum"].to_s, 7))
        })
      end

      # 970 食事
      if @rosai
        fm_remove_970_x = 0
        fm_remove_970_y = 0
        if !totel_fm["970_array"].nil?
          totel_fm["970_array"].each do |point, ten, freq, tani|
            if ten != 0 and freq != 0
              tani = 1 if tani.to_i <= 0
              rten = ten.to_i / tani.to_i
              rfreq = freq.to_i * tani.to_i
              p_ten.push({
                "size" => 18,
                "move" => [745+x+fm_remove_970_x, 423+y+fm_remove_970_y],
                "text" => word2kotei2(rten.to_s, 8)
              })
              p_ten.push({
                "size" => 18,
                "move" => [870+x+fm_remove_970_x, 423+y+fm_remove_970_y],
                "text" => word2kotei2(rfreq.to_s, 3)
              })
              fm_remove_970_y += 25
            end
          end
        end
      end

      if totel_fm["972_sum"] != 0
        fm_remove_x = 0
        fm_remove_y = 0
        p_ten.push({
          "size" => 14,
          "move" => [715+x+fm_remove_x, 1401+y+fm_remove_y],
          "text" => sw2bw(word2kotei2(totel_fm["972_sum"].to_s, 7))
        })
      end

      if totel_fm["974_sum"] != 0
        fm_remove_x = 0
        fm_remove_y = 0
        p_ten.push({
          "size" => 14,
          "move" => [715+x+fm_remove_x, 1446+y+fm_remove_y],
          "text" => sw2bw(word2kotei2(totel_fm["974_sum"].to_s, 7))
        })
      end

      # 食事・生活療養 食事回数[hospital] 保険
      if !@meal.to_s.empty?
        if @rosai
          p_total.push({
              "size" => 22,
              "move" => [830+x, 550+y],
              "text" => sw2bw(word2kotei2(@meal, 3))
          })
        else
          p_total.push({
              "size" => 14,
              "move" => [710+x, 1525+y],
              "text" => sw2bw(word2kotei2(@meal, 3))
          })
        end
      end

      # 食事,生活,環境 合計請求金額[hospital] 保険
      if !@meal_money.to_s.empty?
        fm_remove_x = 0
        fm_remove_y = 0
        money_97_sum = @meal_money
        p_total.push({
            "size" => 18,
            "move" => [805+x+fm_remove_x, 1525+y+fm_remove_y],
            "text" => sw2bw(word2kotei2(i2k_l(money_97_sum), 7))
        })
      end

      # 食事,生活,環境 合計金額[hospital]
      # 970,972,974の合計金額
      #if totel_fm["970_sum"]+totel_fm["972_sum"]+totel_fm["974_sum"] != 0
      #  money_97_sum = 0
      #  money_97_sum += totel_fm["970_sum"]
      #  money_97_sum += totel_fm["972_sum"]
      #  money_97_sum += totel_fm["974_sum"]
      #  p_total.push({
      #      "size" => 18,
      #      "move" => [805+x, 1525+y],
      #      "text" => sw2bw(word2kotei2(i2k_l(money_97_sum), 9))
      #  })
      #end

      totel_fm["97_futan_sum"] = ["","","","",""]
      futan_loop = 1
      futan_loop += @kouhi.size if @kouhi != []
      futan_loop.times do |dix|
        s97s = totel_fm["971_sum"][dix].to_i
        s97s += totel_fm["973_sum"][dix].to_i
        s97s += totel_fm["975_sum"][dix].to_i
        totel_fm["97_futan_sum"][dix] = s97s
      end

      # 標準負担額[hospital]
      # hoken
      if !totel_fm["97_futan_sum"][0].to_s.empty? and !@hoken.to_s.empty?
        fm_remove_x = 0
        fm_remove_y = 0
        p_ten.push({
          "size" => 18,
          "move" => [1065+x+fm_remove_x, 1525+y+fm_remove_y],
          "text" => sw2bw(word2kotei2(totel_fm["97_futan_sum"][0].to_s, 6))
        })
      end

      # kouhi 1^4
      if @kouhi.size <= 3
        if !totel_fm["97_futan_sum"][1].to_s.empty?
          p_ten.push({
            "size" => 18,
            "move" => [1065+x, 1575+y],
            "text" => sw2bw(word2kotei2(totel_fm["97_futan_sum"][1].to_s, 6))
          })
        end
        if @kouhi.size <= 2
          if !totel_fm["97_futan_sum"][2].to_s.empty?
            p_ten.push({
              "size" => 18,
              "move" => [1065+x, 1625+y],
              "text" => sw2bw(word2kotei2(totel_fm["97_futan_sum"][2].to_s, 6))
            })
          end
        else
          if !totel_fm["97_futan_sum"][2].to_s.empty?
            p_ten.push({
              "size" => 16,
              "move" => [1075+x, 1600+y],
              "text" => sw2bw(word2kotei2(totel_fm["97_futan_sum"][2].to_s, 6))
            })
          end
          if !totel_fm["97_futan_sum"][3].to_s.empty?
            p_ten.push({
              "size" => 16,
              "move" => [1075+x, 1625+y],
              "text" => sw2bw(word2kotei2(totel_fm["97_futan_sum"][3].to_s, 6))
            })
          end
        end
      elsif @kouhi.size == 4
        if !totel_fm["97_futan_sum"][1].to_s.empty?
          p_ten.push({
            "size" => 16,
            "move" => [1075+x, 1550+y],
            "text" => sw2bw(word2kotei2(totel_fm["97_futan_sum"][1].to_s, 6))
          })
        end
        if !totel_fm["97_futan_sum"][2].to_s.empty?
          p_ten.push({
            "size" => 16,
            "move" => [1075+x, 1575+y],
            "text" => sw2bw(word2kotei2(totel_fm["97_futan_sum"][2].to_s, 6))
          })
        end
        if !totel_fm["97_futan_sum"][3].to_s.empty?
          p_ten.push({
            "size" => 16,
            "move" => [1075+x, 1600+y],
            "text" => sw2bw(word2kotei2(totel_fm["97_futan_sum"][3].to_s, 6))
          })
        end
        if !totel_fm["97_futan_sum"][4].to_s.empty?
          p_ten.push({
            "size" => 16,
            "move" => [1075+x, 1625+y],
            "text" => sw2bw(word2kotei2(totel_fm["97_futan_sum"][4].to_s, 6))
          })
        end
      end
    end

    # page status
    if (all_page_count / page_line_max["first"]).to_i >= 1
      page = 1
    else
      page = 1
    end
    @page = page

    if (page <= 1 and npage == 0) or (page == 0 and npage == 0)
      if p_next_diag[0].empty?
        @npage = 0
      else
        @npage = npage + 1
      end
    else
      @npage = npage + 1
    end

=begin
    # ページ番号表示
    if @npage > 0
      (@npage+@page).times do |nlist|
        if nlist == 0
          p_diag.push({
            "size" => 18,
            "move" => [1000+x, 400+y],
            "text" => sw2bw(word2kotei2("#{nlist+1}/#{@page+@npage}", 5))
          })
        else
          p_next_diag[nlist-1].push({
            "size" => 18,
            "move" => [1000+x, 400+y],
            "text" => sw2bw(word2kotei2("#{nlist+1}/#{@page+@npage}", 5))
          })
        end
      end
    end
=end

    predata = {}
    predata["info"] = p_info
    predata["sick"] = p_sick
    predata["diag"] = p_diag
    predata["ten"] = p_ten
    predata["total"] = p_total
    predata["next_info"] = p_next_info
    predata["next_diag"] = p_next_diag

    return predata
  end

  def predata_pixbufs_exist?(pixbuf_hash)
    pixbuf_exist = false
    if pixbuf_hash.class == Hash
      pixbuf_hash.each do |pname, pixbuf|
        case pixbuf.class.to_s
        when 'Gdk::Pixbuf'
          pixbuf_exist = true
        when 'Poppler::Document'
          pixbuf_exist = true
        end
      end
    end
    return pixbuf_exist
  end

  def make_rece_predata_context(context, base_pixbuf, x, y,
                                max_x, max_y, sx, sy, predata, page=0)
    context.scale(sx, sy)
    context.translate(x, y)
    x = 0
    y = 0
    self.make_rece_predata_context_background(context, base_pixbuf, x, y, max_x, max_y, predata, page)

    context.set_source_rgb(0, 0, 0)
    if @background_reander_text == "PANGO"
      font = "#{@font} "
      # font = "#{@font} NORMAL "
    else
      context.select_font_face(@font, Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL)
      # context.select_font_face(@font, 0, 0)
    end

    predata.each do |dname, dhash|
      if page == 0
        if dname != "next_diag" and dname != "next_info"
          dhash.each do |view|
            if view["text"].class == Array
              mx,my = view["move"]
              if @background_reander_text == "PANGO"
                # context.move_to(mx, my)
                view["text"].each do |text|
                  playout = context.create_pango_layout
                  playout.font_description = Pango::FontDescription.new(font + view["size"].to_s)
                  playout.set_text(text)
                end
              else
                if !view["font"].to_s.empty?
                  font = view["font"].to_s
                else
                  font = @font
                end
                context.select_font_face(font, Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL)
                context.set_font_size(view["size"])
                context.move_to(mx, my)
                view["text"].each do |text|
                  context.show_text(text)
                end
              end
            elsif !view["text"] and !view["text"].nil?
              line_s1 = view["stat"][0]
              line_s2 = view["stat"][1]
              line_s3 = view["stat"][2]
              mx,my = view["move"]
              lx,ly = view["line"]

              context.move_to(mx, my)
              context.line_to(lx, ly)
              context.set_dash([line_s1, line_s2], line_s3)
              context.set_line_width(view["size"])
              context.stroke
            else
              if !view["text"].to_s.empty? and /^ +$/ !~ view["text"].to_s
                mx,my = view["move"]
                if @background_reander_text == "PANGO"
                  context.move_to(mx, my)
                  playout = context.create_pango_layout
                  pfont = Pango::FontDescription.new(font + (view["size"].to_i-6).to_s)
                  playout.font_description = pfont
                  playout.set_text(view["text"].to_s)
                  context.show_pango_layout(playout)
                else
                  if !view["font"].to_s.empty?
                    font = view["font"].to_s
                  else
                    font = @font
                  end
                  context.select_font_face(font, Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL)
                  context.set_font_size(view["size"])
                  context.move_to(mx, my)
                  context.show_text(view["text"].to_s)
                end
              end
            end
          end
        end
      else
        if dname == "next_diag"
          dhash[page-1].each do |view|
            if view["text"].class == Array
              mx,my = view["move"]
              if !view["font"].to_s.empty?
                font = view["font"].to_s
              else
                font = @font
              end
              context.select_font_face(font, Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL)
              context.set_font_size(view["size"])
              context.move_to(mx, my)
              view["text"].each do |text|
                if @background_reander_text == "PANGO"
                  playout = context.create_pango_layout
                  playout.font_description = Pango::FontDescription.new(font + view["size"])
                  playout.set_text(text)
                  context.show_pango_layout(playout)
                else
                  context.show_text(text)
                end
              end
            elsif !view["text"]
              line_s1 = view["stat"][0]
              line_s2 = view["stat"][1]
              line_s3 = view["stat"][2]
              mx,my = view["move"]
              lx,ly = view["line"]

              context.move_to(mx, my)
              context.line_to(lx, ly)
              context.set_dash([line_s1, line_s2], line_s3)
              context.set_line_width(view["size"])
              context.stroke
            else
              if !view["text"].to_s.empty? and /^ +$/ !~ view["text"].to_s
                mx,my = view["move"]
                if !view["font"].to_s.empty?
                  font = view["font"].to_s
                else
                  font = @font
                end
                context.select_font_face(font, Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL)
                context.set_font_size(view["size"])
                context.move_to(mx, my)
                if @background_reander_text == "PANGO"
                  playout = context.create_pango_layout
                  playout.font_description = Pango::FontDescription.new(font + view["size"])
                  playout.set_text(view["text"].to_s)
                  context.show_pango_layout(playout)
                else
                  context.show_text(view["text"].to_s)
                end
              end
            end
          end
        elsif dname == "next_info"
          dhash.each do |view|
            if view["text"].class == Array
              mx,my = view["move"]
              if !view["font"].to_s.empty?
                font = view["font"].to_s
              else
                font = @font
              end
              context.select_font_face(font, Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL)
              context.set_font_size(view["size"])
              context.move_to(mx, my)
              view["text"].each do |text|
                if @background_reander_text == "PANGO"
                  playout = context.create_pango_layout
                  playout.font_description = Pango::FontDescription.new(font + view["size"])
                  playout.set_text(text)
                  context.show_pango_layout(playout)
                else
                  context.show_text(text)
                end
              end
            else
              if !view["text"].to_s.empty? and /^ +$/ !~ view["text"].to_s
                mx,my = view["move"]
                if !view["font"].to_s.empty?
                  font = view["font"].to_s
                else
                  font = @font
                end
                context.select_font_face(font, Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL)
                context.set_font_size(view["size"])
                context.move_to(mx, my)
                if @background_reander_text == "PANGO"
                  playout = context.create_pango_layout
                  playout.font_description = Pango::FontDescription.new(font + view["size"])
                  playout.set_text(view["text"].to_s)
                  context.show_pango_layout(playout)
                else
                  context.show_text(view["text"].to_s)
                end
              end
            end
          end
        end
      end
    end
    if @background_reander == "PDF"
      unless @pdf_width.nil? and @pdf_height.nil?
        context.scale(@width_Pixel / @pdf_width, @height_Pixel / @pdf_height)
      end
    end
    context.show_page
  end

  def make_rece_predata_context_background(context, base_pixbuf, x, y, max_x, max_y, predata, page)
    if predata_pixbufs_exist?(base_pixbuf)
      case @background_reander
      when "CAIRO"
        if @rosai
          if page == 0
            case @rr_form.to_i
            when ReceModelData::ROSAI_34702
              data = @r2cairo.cairo_make_yaml(base_pixbuf["type7"])
            when ReceModelData::ROSAI_34703
              data = @r2cairo.cairo_make_yaml(base_pixbuf["type5"])
            when ReceModelData::ROSAI_34704
              data = @r2cairo.cairo_make_yaml(base_pixbuf["type9"])
            when ReceModelData::ROSAI_34705
              data = @r2cairo.cairo_make_yaml(base_pixbuf["type8"])
            else
              data = @r2cairo.cairo_make_yaml(base_pixbuf["type5"])
            end
          else
            data = @r2cairo.cairo_make_yaml(base_pixbuf["type6"])
          end
        else
          if @hospital
            if page == 0
              data = @r2cairo.cairo_make_yaml(base_pixbuf["type3"])
            else
              data = @r2cairo.cairo_make_yaml(base_pixbuf["type4"])
            end
          else
            if page == 0
              data = @r2cairo.cairo_make_yaml(base_pixbuf["type1"])
            else
              data = @r2cairo.cairo_make_yaml(base_pixbuf["type2"])
            end
          end
        end
        @r2cairo.set_safe_font_all(@font)
        @r2cairo.cairo_draw(context, data)
      when "PDF"
        context.fill do
          context.set_source_rgb(0.94, 0.93, 0.92)
          context.rectangle(max_x, 0, @width_Pixel, @height_Pixel)
          context.rectangle(0, max_y, max_x, @height_Pixel)
        end
        if @rosai
          if page == 0
            case @rr_form.to_i
            when ReceModelData::ROSAI_34702
              pdf_data = base_pixbuf["type7"][0]
            when ReceModelData::ROSAI_34703
              pdf_data = base_pixbuf["type5"][0]
            when ReceModelData::ROSAI_34704
              pdf_data = base_pixbuf["type9"][0]
            when ReceModelData::ROSAI_34705
              pdf_data = base_pixbuf["type8"][0]
            else
              pdf_data = base_pixbuf["type4"][0]
            end
          else
            pdf_data = base_pixbuf["type6"][0]
          end
        else
          if @hospital
            if page == 0
              pdf_data = base_pixbuf["type3"][0]
            else
              pdf_data = base_pixbuf["type4"][0]
            end
          else
            if page == 0
              pdf_data = base_pixbuf["type1"][0]
            else
              pdf_data = base_pixbuf["type2"][0]
            end
          end
        end
        unless pdf_data.nil?
          @pdf_width, @pdf_height = pdf_data.size
          context.render_poppler_page(pdf_data)
          context.scale(@pdf_width / @width_Pixel, @pdf_height / @height_Pixel)
        end
      else
        context.fill do
          context.set_source_rgb(1.0, 1.0, 1.0)
          context.rectangle(max_x, 0, @width_Pixel, @height_Pixel)
          context.rectangle(0, max_y, max_x, @height_Pixel)
        end
        if @rosai
          if page == 0
            case @rr_form.to_i
            when ReceModelData::ROSAI_34702
              context.set_source_pixbuf(base_pixbuf["type7"], x, y)
            when ReceModelData::ROSAI_34703
              context.set_source_pixbuf(base_pixbuf["type5"], x, y)
            when ReceModelData::ROSAI_34704
              context.set_source_pixbuf(base_pixbuf["type9"], x, y)
            when ReceModelData::ROSAI_34705
              context.set_source_pixbuf(base_pixbuf["type8"], x, y)
            else
              context.set_source_pixbuf(base_pixbuf["type5"], x, y)
            end
          else
            context.set_source_pixbuf(base_pixbuf["type6"], x, y)
          end
        else
          if @hospital
            if page == 0
              context.set_source_pixbuf(base_pixbuf["type3"], x, y)
            else
              context.set_source_pixbuf(base_pixbuf["type4"], x, y)
            end
          else
            if page == 0
              context.set_source_pixbuf(base_pixbuf["type1"], x, y)
            else
              context.set_source_pixbuf(base_pixbuf["type2"], x, y)
            end
          end
        end
        context.paint
      end
    end
  end

  def set_futan_group(futan_no, ex_array_point, point, mode="2way")
    case mode
    when "2way"
      case futan_no 
      when 0
        ex_array_point[0] += point
      when 1
        ex_array_point[1] += point
      when 2
        ex_array_point[0] += point
        ex_array_point[1] += point
      when 3
      else
      end
    when "5way"
      bnumber = futan_no.to_i.to_s(2).to_s
      while bnumber.size < 5
        bnumber = "0"+bnumber
      end
      bnumber.split(//).reverse.each_with_index do |p_bnum, p_index|
        if p_bnum.to_s == "1"
          if ex_array_point[p_index] == ""
            ex_array_point[p_index] = 0
          end
          ex_array_point[p_index] += point
        end
      end
    end
    return ex_array_point
  end

  def make_text_predata(text_data)
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      max_line_point = 70
      return_point = 98
    else
      max_line_point = 71
      return_point = 98
    end

    text_data_marge = []
    text_data.split(/\n/).each_with_index do |text, index|
      text_sp = text.split(//)
      line_char_size = array_char_size(text_sp)

      if line_char_size > return_point
        text_cs = ""
        text_size = 0
        text_sp.each_with_index do |t, pindex|
          text_cs << t
          text_size += string_char_size(t)

          if (text_size >= return_point)
            text_data_marge.push(text_cs)
            text_size = 0
            text_cs = ""
          end
        end
        if !text_cs.empty?
          text_data_marge.push(text_cs)
        end
      else
        text_data_marge.push(text)
      end
    end

    page = 0
    page_data = []
    text_data_marge.each_with_index do |text, index|
      if (index % max_line_point == 0)
        page_data.push([])
        page += 1 if index != 0
      end
      page_data[page].push(text)
    end
    page_data
  end

  def make_text_png(page_data, out_png)
    ret_name = []

    surface = Cairo::ImageSurface.new(@format, @width_Pixel, @height_Pixel)
    page_size = page_data.size

    page_size.times do |page|
      context = Cairo::Context.new(surface)
      context.scale(1.0, 1.0)
      self.make_text_context_png(context, page_data[page])
      context.show_page

      if page_size != 0
        out_png_plus = out_png.gsub(/\.png/, "#{(page+1).to_s}.png")
      else
        out_png_plus = out_png
      end

      surface.write_to_png(out_png_plus)
      ret_name.push(out_png_plus)
    end
    surface.finish
    return ret_name
  end

  def make_text_ps(page_data, out_ps)
    surface = Cairo::PSSurface.new(out_ps, @width_A4, @height_A4)
    context = Cairo::Context.new(surface)
    context.scale(@postscript_scale, @postscript_scale)

    page_data.size.times do |page|
      self.make_text_context_ps(context, page_data[page])
      context.show_page
    end
    surface.finish
    return out_ps
  end

  def make_text_pdf(page_data, out_pdf, file=true)
    surface = Cairo::PDFSurface.new(out_pdf, @width_Pixel, @height_Pixel)
    context = Cairo::Context.new(surface)
    context.scale(1.0, 1.0)

    page_data.size.times do |page|
      self.make_text_context(context, page_data[page])
      context.show_page
    end
    surface.finish
    if file
      return out_pdf
    else
      return context
    end
  end

  def make_text_context(context, page_data)
    context.translate(0, 0)
    context.move_to(0, 0)
    font_size = 24

    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      x = font_size*2
      y = font_size*2
    else
      x = font_size
      y = font_size
    end

    if @background_reander == "PDF"
      context.scale(@width_A4 / @width_Pixel, @height_A4 / @height_Pixel)
    end

    context.fill do
      context.set_source_rgb(1.0, 1.0, 1.0)
      context.rectangle(0, 0, @width_Pixel, @height_Pixel)
    end

    if @background_reander_text == "PANGO"
      font = "#{@font} "
    else
      context.select_font_face(@font,
                               Cairo::FONT_SLANT_NORMAL,
                               Cairo::FONT_WEIGHT_NORMAL)
    end

    context.set_source_rgb(0, 0, 0)

    if @background_reander_text == "PANGO"
      page_data.each do |text|
        y += font_size
        context.move_to(x, y)
        playout = context.create_pango_layout
        playout.font_description = Pango::FontDescription.new(font + font_size.to_s)
        playout.set_text(text)
      end
    else
      context.set_font_size(font_size)
      page_data.each do |text|
        y += font_size
        context.move_to(x, y)
        context.show_text(text.to_s)
      end
    end
    if @background_reander == "PDF"
      context.scale(@width_Pixel / @width_A4 , @height_Pixel / @height_A4)
    end
  end

  def make_text_context_ps(context, page_data)
    context.translate(0, 0)
    context.move_to(0, 0)
    font_size = 24

    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      x = font_size*2
      y = font_size*2
    else
      x = font_size
      y = font_size
    end

    context.fill do
      context.set_source_rgb(1.0, 1.0, 1.0)
      context.rectangle(0, 0, @width_Pixel, @height_Pixel)
    end

    if @background_reander_text == "PANGO"
      font = "#{@font} "
    else
      context.select_font_face(@font,
                               Cairo::FONT_SLANT_NORMAL,
                               Cairo::FONT_WEIGHT_NORMAL)
    end

    context.set_source_rgb(0, 0, 0)

    if @background_reander_text == "PANGO"
      page_data.each do |text|
        y += font_size
        context.move_to(x, y)
        playout = context.create_pango_layout
        playout.font_description = Pango::FontDescription.new(font + font_size.to_s)
        playout.set_text(text)
      end
    else
      context.set_font_size(font_size)
      page_data.each do |text|
        y += font_size
        context.move_to(x, y)
        context.show_text(text.to_s)
      end
    end
  end

  def make_text_context_png(context, page_data)
    self.make_text_context_ps(context, page_data)
  end
end

if __FILE__ == $0
end
