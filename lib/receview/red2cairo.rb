# -*- encoding: utf-8 -*-

require 'jma/receview/generation'

# monpe red file 2 cairo
class RedCairo
  require 'gtk2'
  require 'cgi'
  require 'kconv'

  # layer <= object
  OBJECT_ALL_PAGE   = "main"

  # layer > object
  OBJECT_DICTIONARY = "dictionary"
  OBJECT_BAKGROUND  = "background"
  OBJECT_LINE       = "line"
  OBJECT_LINE_BOX   = "line_box"
  OBJECT_TEXT       = "text"
  OBJECT_TEXT_BOX   = "text_box"
  OBJECT_ORCA_TEXT  = "orca_text"
  OBJECT_EMBED_TEXT = "embed_text"
  OBJECT_ELLIPSE    = "ellipse"
  OBJECT_ARC        = "arc"

  # monpe v2
  XML_PREFIX = "dia:"

  PAPER = {
    "A4"   => {"width" =>"595",  "height" => "842" },
    "A5"   => {"width" =>"421",  "height" => "595" },
    "A6"   => {"width" =>"297",  "height" => "421" },
    "B4"   => {"width" =>"729",  "height" => "1032"},
    "B5"   => {"width" =>"516",  "height" => "729" },
    "B6"   => {"width" =>"363",  "height" => "516" },
    "FREE" => {"width" =>"1240", "height" => "1754"},
  }

  attr_accessor :scale
  attr_accessor :font_trans

  def initialize
    @draw_hash = {}
    @embed_struct = {}
    @embed_data = nil
    @layer_visible = false
    @scale = 100
    @font_trans = {
      "Gothic" => "Sans",
      "Mincho" => "Serif",
      "明朝" => "Serif",
      "OCRB" => "OCRB",
      "OCRROSAI" => "OCRROSAI",
      "Times-Roman" => "Times New Roman",
      "Courier" => "Sans",
      "Courier-Oblique" => "Sans",
      "Courier-Bold" => "Sans",
      "Courier-ObliqueBold" => "Sans",
    }
    @safe_font = {
      "Gothic" => "Sans",
      "Mincho" => "Serif",
      "明朝" => "Serif",
      "OCRB" => "Sans",
      "OCRROSAI" => "Sans",
      "Times-Roman" => "Sans",
      "Courier" => "Sans",
      "Courier-Oblique" => "Sans",
      "Courier-Bold" => "Sans",
      "Courier-ObliqueBold" => "Sans",
    }
  end

  def layer_visible
    return @layer_visible
  end

  def get_embed_struct
    return @embed_struct
  end

  def get_embed_data
    return @embed_data
  end

  def get_paper_size(page)
    return PAPER[page]
  end

  def set_layer_visible(q)
    @layer_visible = q
  end

  def set_embed_data(embed_data)
    @embed_data = embed_data
  end

  def set_safe_font(font_hash)
    @safe_font = font_hash
  end

  def set_safe_font_all(font_name="Sans")
    @safe_font.each do |vname, rname|
      @safe_font[vname] = font_name
    end
  end

  def clear
    @draw_hash = {}
    @draw_hash[OBJECT_DICTIONARY] = []
    @draw_hash[OBJECT_BAKGROUND] = []
    @draw_hash[OBJECT_LINE] = []
    @draw_hash[OBJECT_TEXT] = []
    @draw_hash[OBJECT_LINE_BOX] = []
    @draw_hash[OBJECT_TEXT_BOX] = []
    @draw_hash[OBJECT_ORCA_TEXT] = []
    @draw_hash[OBJECT_EMBED_TEXT] = []
    @draw_hash[OBJECT_ELLIPSE] = []
    @draw_hash[OBJECT_ARC] = []
    return @draw_hash
  end

  def font_tran(font, status=true)
    font_set = @font_trans[font].to_s 
    font_set = font_safe(font) if font_set == "" or !status
    return font_set
  end

  def font_safe(font)
    font = @safe_font[font]
    font = "Sans" if font == ""
    return font
  end

  def set_font_tran(link_font, replace_font)
    if !@font_trans[link_font].to_s.empty?
      @font_trans[link_font] = replace_font
    end
    return @font_trans[link_font].to_s
  end

  def safe_color_convert(color="#ffffff")
    if /^#([0-9|a-f]){6}$/ =~ color.to_s
      color10 = []
      color16 = color.to_s.downcase.sub(/^#/, "").scan(/\S{2}/)
      color16.each do |c|
        rgb = format("%d", c.to_i(16)).to_f / 256
        if rgb < 0.2
          color10.push(0.2)
        else
          color10.push(rgb)
        end
      end
    else
      color10 = [0.2, 0.2, 0.2]
    end
    return color10
  end

  def diagram_dictionary(doc, draw_hash)
    doc.elements.each("#{XML_PREFIX}diagram/#{XML_PREFIX}dictionarydata") do |e0|
      dictionary_element_recursive(e0, draw_hash).each do |d|
        draw_hash.push(d)
      end
    end
    return draw_hash
  end

  def dictionary_element_recursive(e0, draw_hash=[])
    draw_hash = []
    e0.elements.each("element") do |e1|
      line_hash = {}
      element_struct = true
      line_hash["name"] = e1.attribute("name").to_s
      line_hash["occurs"] = e1.attribute("occurs").to_s
      e1.elements.each("appinfo") do |e2|
        e2.elements.each("embed") do |e3|
          line_hash["object"] = e3.attribute("object").to_s
          line_hash["length"] = e3.attribute("length").to_s
          element_struct = false
        end
      end
      if element_struct
        line_hash["family"] = dictionary_element_recursive(e1)[0]
      end
      draw_hash.push(line_hash)
    end
    return draw_hash
  end

  def dictionary_family_pass(dic, status=true)
    fm_struct = {}
    if dic["family"].to_s.empty?
      fm_struct[dic["name"]] = {
        "size" => dic["length"],
        "struc" => dic["occurs"],
        "attr" => dic["object"],
      }
    else
      fm_struct[dic["name"]] = {
        "size" => dic["length"],
        "struc" => dic["occurs"],
        "attr" => dic["object"],
        "family" => dictionary_family_pass(dic["family"])
      }
    end
    return fm_struct
  end

  def diagram_main(doc, draw_hash)
    doc.elements.each("#{XML_PREFIX}diagram/#{XML_PREFIX}diagramdata") do |e0|
      line_hash = {}
      e0.elements.each("#{XML_PREFIX}attribute") do |e1|
        case e1.attribute("name").to_s
        when "background"
          e1.elements.each("#{XML_PREFIX}color") do |e2|
            point = e2.attribute("val").to_s
            line_hash["background"] = point
          end
        when "paper"
          e1.elements.each("#{XML_PREFIX}composite") do |e2|
            e2.elements.each("#{XML_PREFIX}attribute") do |e3|
              case e3.attribute("name").to_s
              when "name"
                e3.elements.each("#{XML_PREFIX}string") do |e4|
                  paper = e4.get_text.to_s.gsub(/^\#|\#$/,"")
                  line_hash["paper"] = paper
                end
              when "pswidth"
                e3.elements.each("#{XML_PREFIX}real") do |e4|
                  pswidth = e4.attribute("val").to_s
                  line_hash["pswidth"] = pswidth.to_f
                end
              when "psheight"
                e3.elements.each("#{XML_PREFIX}real") do |e4|
                  psheight = e4.attribute("val").to_s
                  line_hash["psheight"] = psheight.to_f
                end
              when "scaling"
                e3.elements.each("#{XML_PREFIX}real") do |e4|
                  scaling = e4.attribute("val").to_s
                  line_hash["scaling"] = scaling.to_f
                end
              end
            end
          end
        end
      end
      draw_hash.push(line_hash)
    end
    return draw_hash
  end

  # 実線,鎖線,一線鎖線,二線鎖線,点線
  # "0" => 0,  "1" => 1, "2" => 2, "3" => 4
  def diagram_line(e1, draw_hash)
    line_hash = {}
    e1.elements.each("#{XML_PREFIX}attribute") do |e2|
      case e2.attribute("name").to_s
      when "obj_pos"
        e2.elements.each("#{XML_PREFIX}point") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos"] = point.split(/,|;/)
        end
      when "obj_bb"
        e2.elements.each("#{XML_PREFIX}rectangle") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos_bb"] = point.split(/,|;/)
        end
      when "conn_endpoints"
        e2.elements.each("#{XML_PREFIX}point") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos_end"] = point.split(/,|;/)
        end
      when "numcp"
        e2.elements.each("#{XML_PREFIX}int") do |e3|
          point = e3.attribute("val").to_s
          line_hash["numcp"] = point
        end
      when "line_width"
        e2.elements.each("#{XML_PREFIX}real") do |e3|
          point = e3.attribute("val").to_s
          line_hash["size"] = point
        end
      when "line_style"
        e2.elements.each("#{XML_PREFIX}enum") do |e3|
          point = e3.attribute("val").to_s
          line_hash["line_style"] = point
        end
      end
    end
    draw_hash.push(line_hash)
  end

  def diagram_box(e1, draw_hash)
    line_hash = {}
    e1.elements.each("#{XML_PREFIX}attribute") do |e2|
      case e2.attribute("name").to_s
      when "obj_pos"
        e2.elements.each("#{XML_PREFIX}point") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos"] = point.split(/,|;/)
        end
      when "obj_bb"
        e2.elements.each("#{XML_PREFIX}rectangle") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos_bb"] = point.split(/,|;/)
        end
      when "border_width"
        e2.elements.each("#{XML_PREFIX}real") do |e3|
          point = e3.attribute("val").to_s
          line_hash["size"] = point
        end
      when "elem_corner"
        e2.elements.each("#{XML_PREFIX}point") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos_corner"] = point.split(/,|;/)
        end
      when "elem_width"
        e2.elements.each("#{XML_PREFIX}real") do |e3|
          point = e3.attribute("val").to_s
          line_hash["width"] = point
        end
      when "elem_height"
        e2.elements.each("#{XML_PREFIX}real") do |e3|
          point = e3.attribute("val").to_s
          line_hash["height"] = point
        end
      end
    end
    draw_hash.push(line_hash)
  end

  def diagram_text(e1, draw_hash)
    line_hash = {}
    e1.elements.each("#{XML_PREFIX}attribute") do |e2|
      case e2.attribute("name").to_s
      when "obj_pos"
        e2.elements.each("#{XML_PREFIX}point") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos"] = point.split(/,|;/)
        end
      when "obj_bb"
        e2.elements.each("#{XML_PREFIX}rectangle") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos_bb"] = point.split(/,|;/)
        end
      when "elem_corner"
        e2.elements.each("#{XML_PREFIX}point") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos_corner"] = point.split(/,|;/)
        end
      when "elem_width"
        e2.elements.each("#{XML_PREFIX}real") do |e3|
          point = e3.attribute("val").to_s
          line_hash["width"] = point
        end
      when "elem_height"
        e2.elements.each("#{XML_PREFIX}real") do |e3|
          point = e3.attribute("val").to_s
          line_hash["height"] = point
        end
      when "text"
        e2.elements.each("#{XML_PREFIX}composite") do |e3|
          e3.elements.each("#{XML_PREFIX}attribute") do |e4|
            case e4.attribute("name").to_s
            when "string"
              e4.elements.each("#{XML_PREFIX}string") do |e5|
                text = e5.get_text.to_s.gsub(/^\#|\#$/,"")
                line_hash["text"] = CGI.unescapeHTML(text).toutf8
              end
            when "font"
              e4.elements.each("#{XML_PREFIX}font") do |e5|
                font = e5.attribute("name").to_s.gsub(/^\"|\"$/,"")
                font = CGI.unescapeHTML(font)
                line_hash["font"] = CGI.unescapeHTML(font).toutf8
              end
            when "height"
              e4.elements.each("#{XML_PREFIX}real") do |e5|
                point = e5.attribute("val").to_s
                line_hash["height"] = point
              end
            when "pos"
              e4.elements.each("#{XML_PREFIX}point") do |e5|
                point = e5.attribute("val").to_s
                line_hash["pos_text"] = point.split(/,|;/)
              end
            when "color"
              e4.elements.each("#{XML_PREFIX}color") do |e5|
                color= e5.attribute("val").to_s
                line_hash["color"] = color.split(/,|;/)
              end
            when "alignment"
              e4.elements.each("#{XML_PREFIX}enum") do |e5|
                alignment = e5.attribute("val").to_s
                line_hash["alignment"] = alignment
              end
            end
          end
        end
      end
    end
    draw_hash.push(line_hash)
  end

  def diagram_textbox(e1, draw_hash)
    line_hash = {}
    e1.elements.each("#{XML_PREFIX}attribute") do |e2|
      case e2.attribute("name").to_s
      when "obj_pos"
        e2.elements.each("#{XML_PREFIX}point") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos"] = point.split(/,|;/)
        end
      when "obj_bb"
        e2.elements.each("#{XML_PREFIX}rectangle") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos_bb"] = point.split(/,|;/)
        end
      when "elem_corner"
        e2.elements.each("#{XML_PREFIX}point") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos_corner"] = point.split(/,|;/)
        end
      when "elem_width"
        e2.elements.each("#{XML_PREFIX}real") do |e3|
          point = e3.attribute("val").to_s
          line_hash["width"] = point
        end
      when "elem_height"
        e2.elements.each("#{XML_PREFIX}real") do |e3|
          point = e3.attribute("val").to_s
          line_hash["height"] = point
        end
      when "text"
        e2.elements.each("#{XML_PREFIX}composite") do |e3|
          e3.elements.each("#{XML_PREFIX}attribute") do |e4|
            case e4.attribute("name").to_s
            when "string"
              e4.elements.each("#{XML_PREFIX}string") do |e5|
                text = e5.get_text.to_s.gsub(/^\#|\#$/,"")
                line_hash["text"] = CGI.unescapeHTML(text).toutf8
              end
            when "font"
              e4.elements.each("#{XML_PREFIX}font") do |e5|
                font = e5.attribute("name").to_s.gsub(/^\"|\"$/,"")
                font = CGI.unescapeHTML(font)
                line_hash["font"] = CGI.unescapeHTML(font).toutf8
              end
            when "height"
              e4.elements.each("#{XML_PREFIX}real") do |e5|
                point = e5.attribute("val").to_s
                line_hash["height"] = point
              end
            when "pos"
              e4.elements.each("#{XML_PREFIX}point") do |e5|
                point = e5.attribute("val").to_s
                line_hash["pos_text"] = point.split(/,|;/)
              end
            when "color"
              e4.elements.each("#{XML_PREFIX}color") do |e5|
                color= e5.attribute("val").to_s
                line_hash["color"] = color.split(/,|;/)
              end
            end
          end
        end
      end
    end
    draw_hash.push(line_hash)
  end

  def diagram_OrcaTextCircle(e1, draw_hash)
    line_hash = {}
    e1.elements.each("#{XML_PREFIX}attribute") do |e2|
      case e2.attribute("name").to_s
      when "obj_pos"
        e2.elements.each("#{XML_PREFIX}point") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos"] = point.split(/,|;/)
        end
      when "obj_bb"
        e2.elements.each("#{XML_PREFIX}rectangle") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos_bb"] = point.split(/,|;/)
        end
      when "elem_corner"
        e2.elements.each("#{XML_PREFIX}point") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos_corner"] = point.split(/,|;/)
        end
      when "elem_width"
        e2.elements.each("#{XML_PREFIX}real") do |e3|
          point = e3.attribute("val").to_s
          line_hash["width"] = point
        end
      when "elem_height"
        e2.elements.each("#{XML_PREFIX}real") do |e3|
          point = e3.attribute("val").to_s
          line_hash["height"] = point
        end
      when "text"
        e2.elements.each("#{XML_PREFIX}composite") do |e3|
          e3.elements.each("#{XML_PREFIX}attribute") do |e4|
            case e4.attribute("name").to_s
            when "string"
              e4.elements.each("#{XML_PREFIX}string") do |e5|
                text = e5.get_text.to_s.gsub(/^\#|\#$/,"")
                line_hash["text"] = CGI.unescapeHTML(text).toutf8
              end
            when "font"
              e4.elements.each("#{XML_PREFIX}font") do |e5|
                font = e5.attribute("name").to_s.gsub(/^\"|\"$/,"")
                font = CGI.unescapeHTML(font)
                line_hash["font"] = CGI.unescapeHTML(font).toutf8
              end
            when "height"
              e4.elements.each("#{XML_PREFIX}real") do |e5|
                height = e5.attribute("val").to_s
                line_hash["height"] = height
              end
            when "pos"
              e4.elements.each("#{XML_PREFIX}point") do |e5|
                point = e5.attribute("val").to_s
                line_hash["pos_text"] = point.split(/,|;/)
              end
            when "color"
              e4.elements.each("#{XML_PREFIX}color") do |e5|
                color= e5.attribute("val").to_s
                line_hash["color"] = color.split(/,|;/)
              end
            end
          end
        end
      end
    end
    draw_hash.push(line_hash)
  end

  def diagram_ellipse(e1, draw_hash)
    line_hash = {}
    e1.elements.each("#{XML_PREFIX}attribute") do |e2|
      case e2.attribute("name").to_s
      when "obj_pos"
        e2.elements.each("#{XML_PREFIX}point") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos"] = point.split(/,|;/)
        end
      when "obj_bb"
        e2.elements.each("#{XML_PREFIX}rectangle") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos_end"] = point.split(/,|;/)
        end
      when "elem_corner"
        e2.elements.each("#{XML_PREFIX}point") do |e3|
          point = e3.attribute("val").to_s
          line_hash["elem_corner"] = point.split(/,|;/)
        end
      when "elem_width"
        e2.elements.each("#{XML_PREFIX}real") do |e3|
          width = e3.attribute("val").to_s
          line_hash["width"] = width
        end
      when "elem_height"
        e2.elements.each("#{XML_PREFIX}real") do |e3|
          height = e3.attribute("val").to_s
          line_hash["height"] = height
        end
      when "border_width"
        e2.elements.each("#{XML_PREFIX}real") do |e3|
          size = e3.attribute("val").to_s
          line_hash["size"] = size
        end
      when "border_color"
        e2.elements.each("#{XML_PREFIX}color") do |e3|
          color = e3.attribute("val").to_s
          line_hash["color"] = color
        end
      end
    end
    draw_hash.push(line_hash)
  end

  def diagram_arc(e1, draw_hash)
    line_hash = {}
    e1.elements.each("#{XML_PREFIX}attribute") do |e2|
      case e2.attribute("name").to_s
      when "obj_pos"
        e2.elements.each("#{XML_PREFIX}point") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos"] = point.split(/,|;/)
        end
      when "obj_bb"
        e2.elements.each("#{XML_PREFIX}rectangle") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos_end"] = point.split(/,|;/)
        end
      when "conn_endpoints"
        e2.elements.each("#{XML_PREFIX}point") do |e3|
          point = e3.attribute("val").to_s
          line_hash["endpoints"] = point.split(/,|;/)
        end
      when "curve_distance"
        e2.elements.each("#{XML_PREFIX}real") do |e3|
          curve = e3.attribute("val").to_s
          line_hash["curve"] = curve
        end
      end
    end
    draw_hash.push(line_hash)
  end

  def diagram_embed_text(e1, draw_hash)
    line_hash = {}
    e1.elements.each("#{XML_PREFIX}attribute") do |e2|
      case e2.attribute("name").to_s
      when "dnode_path"
        e2.elements.each("#{XML_PREFIX}string") do |e3|
          line_hash["key"] = e3.get_text.to_s.gsub(/^\#|\#$/,"")
        end
      when "obj_pos"
        e2.elements.each("#{XML_PREFIX}point") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos"] = point.split(/,|;/)
        end
      when "obj_bb"
        e2.elements.each("#{XML_PREFIX}rectangle") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos_bb"] = point.split(/,|;/)
        end
      when "elem_corner"
        e2.elements.each("#{XML_PREFIX}point") do |e3|
          point = e3.attribute("val").to_s
          line_hash["pos_corner"] = point.split(/,|;/)
        end
      when "elem_width"
        e2.elements.each("#{XML_PREFIX}real") do |e3|
          point = e3.attribute("val").to_s
          line_hash["width"] = point
        end
      when "elem_height"
        e2.elements.each("#{XML_PREFIX}real") do |e3|
          point = e3.attribute("val").to_s
          line_hash["height"] = point
        end
      when "text"
        e2.elements.each("#{XML_PREFIX}composite") do |e3|
          e3.elements.each("#{XML_PREFIX}attribute") do |e4|
            case e4.attribute("name").to_s
            when "string"
              e4.elements.each("#{XML_PREFIX}string") do |e5|
                text = e5.get_text.to_s.gsub(/^\#|\#$/,"")
                line_hash["text"] = CGI.unescapeHTML(text).toutf8
              end
            when "font"
              e4.elements.each("#{XML_PREFIX}font") do |e5|
                font = e5.attribute("name").to_s.gsub(/^\"|\"$/,"")
                font = CGI.unescapeHTML(font)
                line_hash["font"] = CGI.unescapeHTML(font).toutf8
              end
            when "height"
              e4.elements.each("#{XML_PREFIX}real") do |e5|
                point = e5.attribute("val").to_s
                line_hash["height"] = point
              end
            when "pos"
              e4.elements.each("#{XML_PREFIX}point") do |e5|
                point = e5.attribute("val").to_s
                line_hash["pos_text"] = point.split(/,|;/)
              end
            when "color"
              e4.elements.each("#{XML_PREFIX}color") do |e5|
                color= e5.attribute("val").to_s
                line_hash["color"] = color.split(/,|;/)
              end
            when "alignment"
              e4.elements.each("#{XML_PREFIX}enum") do |e5|
                alignment = e5.attribute("val").to_s
                line_hash["alignment"] = alignment
              end
            end
          end
        end
      end
    end
    draw_hash.push(line_hash)
  end

  def cairo_layer_sort(layer_level)
    ll_sort = layer_level.to_a.sort do |a, b|
      a[1].to_i <=> b[1].to_i
    end
    return ll_sort
  end

  def cairo_make_object(doc, draw_hash)
    case doc.attribute("type").to_s
    when "Standard - Line"
      diagram_line(doc, draw_hash[OBJECT_LINE])
    when "Standard - Box"
      diagram_box(doc, draw_hash[OBJECT_LINE_BOX])
    when "Standard - Text"
      diagram_text(doc, draw_hash[OBJECT_TEXT])
    when "Standard - TextBox"
      diagram_textbox(doc, draw_hash[OBJECT_TEXT_BOX])
    when "Standard - Ellipse"
      diagram_ellipse(doc, draw_hash[OBJECT_ELLIPSE])
    when "Standard - Arc"
      diagram_arc(doc, draw_hash[OBJECT_ARC])
    when "ORCA - TextCircle"
      diagram_OrcaTextCircle(doc, draw_hash[OBJECT_ORCA_TEXT])
    when "Embed - Text"
      diagram_embed_text(doc, draw_hash[OBJECT_EMBED_TEXT])
    end
  end

  def cairo_make(doc)
    make_data = {}
    layer_level = {}
    layer = {}
    draw_hash = self.clear
    level = 0

    diagram_dictionary(doc, draw_hash[OBJECT_DICTIONARY])
    draw_hash[OBJECT_DICTIONARY].each do |dic|
      dictionary_family_pass(dic, false).each do |key, data|
        @embed_struct[key] = data
      end
    end

    diagram_main(doc, draw_hash[OBJECT_BAKGROUND])
    layer[OBJECT_ALL_PAGE] = draw_hash
    layer_level[OBJECT_ALL_PAGE] = level
    draw_hash = self.clear

    doc.elements.each("#{XML_PREFIX}diagram/#{XML_PREFIX}layer") do |e0|
      level += 1
      url_name = e0.attribute("name").to_s.gsub(/^\#|\#$/,"")
      layer_name = CGI.unescapeHTML(url_name)
      layer[layer_name] = self.clear
      layer_level[layer_name] = level

      if e0.attribute("visible").to_s == "true" || @layer_visible
        e0.elements.each("#{XML_PREFIX}group") do |e1|
          e1.elements.each("#{XML_PREFIX}object") do |e2|
            cairo_make_object(e2, draw_hash)
          end
        end
        e0.elements.each("#{XML_PREFIX}object") do |e1|
          cairo_make_object(e1, draw_hash)
        end
      end
      layer[layer_name] = draw_hash
    end
    layer_level_key = cairo_layer_sort(layer_level)
    make_data["draw"] = layer
    make_data["draw_level"] = layer_level_key
    return make_data
  end

  def cairo_draw_background(context, val)
    val.each do |data|
      data.each do |name, v|
        case name
        when "background"
          context.set_source_rgb(safe_color_convert(v))
          context.paint
        when "paper"
        when "scaling"
        when "pswidth"
        when "psheight"
        else
        end
      end
    end
  end

  def cairo_draw_line(context, val)
    val.each do |tmp|
      x = tmp["pos"][0].to_f
      y = tmp["pos"][1].to_f
      xe = tmp["pos_end"][0].to_f
      ye = tmp["pos_end"][1].to_f
      size = tmp["size"].to_f
      
      size = 0.2 if size == 0.0

      context.set_source_rgb(0, 0, 0)
      context.set_line_width(size*scale)
      context.move_to(x*scale, y*scale)
      context.line_to(xe*scale, ye*scale)
      if tmp["line_style"] == "4"
        context.set_dash([12, 6], 0)
      else
        context.set_dash([], 0)
      end
      context.stroke
    end
  end

  def cairo_draw_linebox(context, val)
    context.set_dash([], 0)
    val.each do |tmp|
      x = tmp["pos_bb"][0].to_f
      y = tmp["pos_bb"][1].to_f
      xe = tmp["pos_bb"][2].to_f - tmp["pos_corner"][0].to_f
      ye = tmp["pos_bb"][3].to_f - tmp["pos_corner"][1].to_f
      size = tmp["size"].to_f
      
      size = 0.2 if size == 0.0

      context.set_source_rgb(0, 0, 0)
      context.set_line_width(size)
      context.move_to(0,0)
      context.rectangle(x*scale, y*scale, xe*scale, ye*scale)
      context.stroke
    end
  end

  def cairo_draw_textbox(context, val)
    context.set_dash([], 0)
    val.each do |tmp|
      # x = tmp["pos_bb"][0].to_f
      y = tmp["pos_bb"][1].to_f
      # xe = tmp["pos_bb"][2].to_f
      ye = tmp["pos_bb"][3].to_f
      size = tmp["height"].to_f
      xt = tmp["pos_text"][0].to_f
      yt = tmp["pos_text"][1].to_f
      font = tmp["font"].to_s
      color = tmp["color"]

      yt = (y+ye)/2
      
      context.set_source_rgb(safe_color_convert(color))
      context.set_font_size(size * scale)
      context.select_font_face(font_tran(font, false), 0, 0)

      tmp["text"].split(/\n/).each_with_index do |t, index|
        context.move_to(xt*scale, yt*scale + (size*scale*index))
        context.show_text(t) if !t.to_s.empty?
      end
    end
  end

  def cairo_draw_text(context, val)
    context.set_dash([], 0)
    val.each do |tmp|
      x = tmp["pos_bb"][0].to_f
      #y = tmp["pos_bb"][1].to_f
      #xe = tmp["pos_bb"][2].to_f
      #ye = tmp["pos_bb"][3].to_f
      size = tmp["height"].to_f
      xt = tmp["pos_text"][0].to_f
      yt = tmp["pos_text"][1].to_f
      font = tmp["font"].to_s
      color = tmp["color"]
      alignment = tmp["alignment"].to_i

      xt = x
      yt = yt
      
      context.set_source_rgb(safe_color_convert(color))
      context.set_font_size(size * scale)
      context.select_font_face(font_tran(font, false),
                               Cairo::FONT_SLANT_NORMAL,
                               Cairo::FONT_WEIGHT_NORMAL)

      #playout = context.create_pango_layout
      #playout.set_text(text)
      #context.show_pango_layout(playout)

      case alignment
      when 0
        tmp["text"].split(/\n/).each_with_index do |t, index|
          context.move_to(xt*scale, yt*scale + (size*scale*index))
          context.show_text(t) if !t.to_s.empty?
        end
      when 1
        tmp["text"].split(/\n/).each_with_index do |t, index|
          context.move_to(xt*scale, yt*scale + (size*scale*index))
          context.show_text(t) if !t.to_s.empty?
        end
      when 2
        tmp["text"].split(/\n/).each_with_index do |t, index|
          context.move_to(xt*scale, yt*scale + (size*scale*index))
          context.show_text(t) if !t.to_s.empty?
        end
      else
        tmp["text"].split(/\n/).each_with_index do |t, index|
          context.move_to(xt*scale, yt*scale + (size*scale*index))
          context.show_text(t) if !t.to_s.empty?
        end
      end
    end
  end

  def cairo_draw_orcatext(context, val)
    context.set_dash([], 0)
    val.each do |tmp|
      x = tmp["pos_bb"][0].to_f
      y = tmp["pos_bb"][1].to_f
      #xe = tmp["pos_bb"][2].to_f
      #ye = tmp["pos_bb"][3].to_f
      size = tmp["height"].to_f
      xt = tmp["pos_text"][0].to_f
      yt = tmp["pos_text"][1].to_f
      text = tmp["text"]
      font = tmp["font"]
      color = tmp["color"]

      if !text.to_s.empty?
        text_vol = []
        text.split(/\n/).each_with_index do |chars, index|
          text_vol.push(0.0)
          chars.split(//).each do |char|
            case char.size
            when 1
              text_vol[index] += 0.5
            when 2
              text_vol[index] += 1.0
            when 3
              text_vol[index] += 1.0
            when 4
              text_vol[index] += 1.0
            else
              text_vol[index] += 0.5
            end
          end
        end

        text_vol_max = text_vol.sort.last

        center_x = x * scale + size - 0.5
        center_y = y * scale + size - 2.0
        width = size * scale * text_vol_max + 1.0
        height = size * scale * text_vol.size + 4.0
        radius_x = 15.0
        radius_y = 15.0

        context.set_source_rgb(safe_color_convert(color))
        context.set_line_width(1.0)
        context.rounded_rectangle(center_x, center_y,
                                  width, height, radius_x, radius_y)
        context.stroke

        # Box Draw
        #context.move_to(xt*scale, yt*scale)
        #extents = context.text_extents(text+" ")
        #context.rectangle(x*scale, y*scale,extents.width,
        #                  extents.height)
        #context.stroke

        context.set_source_rgb(safe_color_convert(color))
        context.set_font_size(size * scale)
        context.select_font_face(font_tran(font, false), 0, 0)

        text.split(/\n/).each_with_index do |t, index|
          context.move_to(xt*scale, yt*scale + (size*scale*index))
          context.show_text(t) if !t.to_s.empty?
        end
      end
    end
  end

  def cairo_draw_ellipse(context, val)
    # bugs
    val.each do |tmp|
      x = tmp["elem_corner"][0].to_f
      y = tmp["elem_corner"][1].to_f
      width_size = tmp["width"].to_f
      height_size = tmp["height"].to_f
      line_size = tmp["size"].to_f
      color = tmp["color"]

      line_size = 0.01 if line_size == 0.0

      center_x = x * scale
      center_y = y * scale
      width  = width_size * scale
      height = height_size * scale
      radius = width

      context.set_source_rgb(safe_color_convert(color))
      context.set_line_width(line_size*scale)
      context.rounded_rectangle(center_x, center_y,
                                width, height, radius)
      context.stroke
    end
  end

  def cairo_draw_arc(context, val)
    val.each do |tmp|
      #x = tmp["pos"][0].to_f
      #y = tmp["pos"][1].to_f
      #xe = tmp["pos_end"][0].to_f
      #ye = tmp["pos_end"][1].to_f
      #corner_x = tmp["endpoints"][0].to_f
      #corner_y = tmp["endpoints"][1].to_f
      #curve = tmp["curve"].to_f
      #context.circle(x*scale, y*scale, curve*scale)
    end
  end

  def cairo_draw_embed_text(context, val)
    context.set_dash([], 0)
    val.each do |tmp|
      embed_key = tmp["key"].to_s
      x = tmp["pos_bb"][0].to_f
      #y = tmp["pos_bb"][1].to_f
      #xe = tmp["pos_bb"][2].to_f
      #ye = tmp["pos_bb"][3].to_f
      size = tmp["height"].to_f
      xt = tmp["pos_text"][0].to_f
      yt = tmp["pos_text"][1].to_f
      font = tmp["font"].to_s
      color = tmp["color"]
      alignment = tmp["alignment"].to_i

      xt = x
      yt = yt
      
      context.set_source_rgb(safe_color_convert(color))
      context.set_font_size(size * scale)
      context.select_font_face(font_tran(font, false),
                               Cairo::FONT_SLANT_NORMAL,
                               Cairo::FONT_WEIGHT_NORMAL)

      #playout = context.create_pango_layout
      #playout.set_text(text)
      #context.show_pango_layout(playout)

      if !@embed_data[embed_key].to_s.empty?
        tmp["text"] = @embed_data[embed_key].to_s
      end

      case alignment
      when 0
        tmp["text"].split(/\n/).each_with_index do |t, index|
          context.move_to(xt*scale, yt*scale + (size*scale*index))
          context.show_text(t) if !t.to_s.empty?
        end
      when 1
        tmp["text"].split(/\n/).each_with_index do |t, index|
          context.move_to(xt*scale, yt*scale + (size*scale*index))
          context.show_text(t) if !t.to_s.empty?
        end
      when 2
        tmp["text"].split(/\n/).each_with_index do |t, index|
          context.move_to(xt*scale, yt*scale + (size*scale*index))
          context.show_text(t) if !t.to_s.empty?
        end
      else
        tmp["text"].split(/\n/).each_with_index do |t, index|
          context.move_to(xt*scale, yt*scale + (size*scale*index))
          context.show_text(t) if !t.to_s.empty?
        end
      end
    end
  end

  def cairo_draw(context=nil, page_data={})
    if context != nil
      page_data["draw_level"].each do |layer_name, level|
        page_data["draw"][layer_name].each do |name,val|
          # draw ohter style and background
          case name
          when "background"
            cairo_draw_background(context, val)
          when "line"
            cairo_draw_line(context, val)
          when "line_box"
            cairo_draw_linebox(context, val)
          when "text"
            cairo_draw_text(context, val)
          when "text_box"
            cairo_draw_textbox(context, val)
          when "ellipse"
            cairo_draw_ellipse(context, val)
          when "arc"
            cairo_draw_arc(context, val)
          when "orca_text"
            cairo_draw_orcatext(context, val)
          when "embed_text"
            cairo_draw_embed_text(context, val)
          end
        end
      end
    end
  end

  def cairo_make_png(data, width, height, out_png)
    surface = Cairo::ImageSurface.new(Cairo::FORMAT_RGB24, width, height)
    context = Cairo::Context.new(surface)
    context.scale(1.0, 1.0)
    cairo_draw(context, data)
    context.show_page
    surface.write_to_png(out_png)
    surface.finish
  end

  def cairo_make_pdf(data, width, height, out_pdf)
    surface = Cairo::PDFSurface.new(out_pdf, width, height)
    context = Cairo::Context.new(surface)
    context.scale(1.0, 1.0)
    cairo_draw(context, data)
    context.show_page
    surface.finish
  end

  def cairo_make_pdfs(context, data)
    context.scale(1.0, 1.0)
    cairo_draw(context, data)
    context.show_page
  end

  def cairo_make_yaml(doc)
    data = nil
    if doc.class == String
      data = YAML.load(doc)
    end
    return data
  end
end

if __FILE__ == $0
  require 'benchmark' if $DEBUG
  require 'jma/receview/gtk2_fix'
  require 'jma/receview/preview_widget'
  require 'zlib'
  require 'rexml/document'
  require 'optparse'
  require "yaml"

  include REXML

  @outfile = nil

  opts = OptionParser.new
  RVConfig = Hash.new
  RVConfig[:help] = false
  RVConfig[:in_red] = false
  RVConfig[:out_pdf] = false
  RVConfig[:out_png] = false
  RVConfig[:out_draw_yaml] = false
  RVConfig[:yaml] = false
  RVConfig[:embed] = false
  RVConfig[:layer_visible] = false

  opts.on("-o val", "--outfile val", "--outpdf val") do |v|
    @outfile = v
    RVConfig[:out_pdf] = true
  end

  opts.on("--yaml") do |v|
    @outfile = true
    RVConfig[:out_draw_yaml] = true
    RVConfig[:out_pdf] = true
  end

  opts.on("--outyaml val") do |v|
    @outfile = v
    RVConfig[:out_draw_yaml] = true
    RVConfig[:out_pdf] = true
  end

  opts.on("--embed-yaml val") do |v|
    RVConfig[:embed] = v
  end

  opts.on("--layer-visible") do |v|
    RVConfig[:layer_visible] = true
  end

  opts.on("--out-struct") do |v|
    RVConfig[:out_struct] = true
    RVConfig[:out_pdf] = false
    RVConfig[:out_draw_yaml] = false
  end

  opts.on("-h", "--h", "--help") do |v|
    RVConfig[:help] = true
    RVConfig[:in_red] = false
    RVConfig[:out_pdf] = false
    RVConfig[:out_draw_yaml] = false
    RVConfig[:out_struct] = false
  end

  begin
    opts.parse!(ARGV)
  rescue
    RVConfig[:help] = true
    RVConfig[:in_red] = false
    RVConfig[:out_pdf] = false
    RVConfig[:out_draw_yaml] = false
    RVConfig[:out_struct] = false
    print "option error.\n"
  end

  if !RVConfig[:help]
    if ARGV.size >= 2 and @outfile == nil
      puts "not output file."
      exit 0
    end

    ARGV.each do |files|
      if !File.exist?(files)
        puts "input file not found."
        puts files
        exit 0
      end
    end
  end

  if ARGV[0].to_s.empty? or RVConfig[:help]
    puts ""
    puts "red2cairo.rb help"
    puts ""
    puts "sorry. Depends: zlib,X11,Ruby,rcairo,Cairo,jma-receview"
    puts ""
    puts "ex: red2cairo.rb input.red "
    puts "ex: red2cairo.rb input.red -o output.pdf"
    puts "ex: red2cairo.rb input.red -outfile output.pdf"
    puts "ex: red2cairo.rb --layer-visible input.red "
    puts "ex: red2cairo.rb --embed-yaml embed.yaml --layer-visible input.red"
    puts "ex: red2cairo.rb --out-struct input.red"
    puts ""
    puts "YAML Format stdout"
    puts "  ex: red2cairo.rb input.red --yaml"
    puts ""
    puts "YAML Format fileout"
    puts "  ex: red2cairo.rb input.red --outyaml output.yaml"
    puts ""
    puts "RED Struct output"
    puts "  ex: red2cairo.rb --out-struct input.red"
    exit 0
  end

  raw_xml = ""
  doc = nil
  r2cairo = nil
  data = nil

  # Alternative font
  # r2cairo.font_trans["Courier"] = "Meiryo"
  # r2cairo.set_font_tran("Mincho", "AAA")
  
  if @outfile.class != TrueClass and @outfile.class != FalseClass
    if /\.png$/ =~ @outfile 
      RVConfig[:out_png] = true
    end
  end

  if RVConfig[:embed] != false
    embed_data = YAML.load(File.open(RVConfig[:embed]).read)
  else
    embed_data = {}
  end

  if RVConfig[:out_pdf]
    infile = []
    ARGV.each { |name| infile.push(name) }
    outfile = @outfile

    width = 1240
    height = 1754
    r2cairo = RedCairo.new
    r2cairo.scale = 60
    r2cairo.set_embed_data(embed_data)
    r2cairo.set_layer_visible(true) if RVConfig[:layer_visible]
    reconf_safe_font = {
      "Gothic" => "Sans",
      "Mincho" => "Sans",
      "明朝" => "Sans",
      "OCRB" => "Sans",
      "OCRROSAI" => "Sans",
      "Times-Roman" => "Sans",
      "Courier" => "Sans",
      "Courier-Oblique" => "Sans",
      "Courier-Bold" => "Sans",
      "Courier-ObliqueBold" => "Sans",
    }
    r2cairo.set_safe_font(reconf_safe_font)

    if infile.size == 1
      RVConfig[:yaml] = true if /.yaml$/ =~ infile.first

      begin
        Zlib::GzipReader.open(infile.first) do |gz|
          raw_xml = gz.read
        end
      rescue Zlib::GzipFile::Error
        open(infile.first) do |red|
          raw_xml = red.read
        end
      end

      if RVConfig[:yaml]
        data = r2cairo.cairo_make_yaml(raw_xml)
      else
        doc = REXML::Document.new(raw_xml)
        data = r2cairo.cairo_make(doc)
      end

      if RVConfig[:out_draw_yaml]
        if @outfile
          puts YAML.dump_stream(data)
          exit 0
        else
          file = open(outfile, "w+", 0666)
          file << YAML.dump_stream(data)
          file.close

          puts "YAML data output."
          puts outfile
          exit 0
        end
      else
        if RVConfig[:out_png]
          r2cairo.cairo_make_png(data, width, height, outfile)
        else
          r2cairo.cairo_make_pdf(data, width, height, outfile)
        end
      end
    else
      surface = Cairo::PDFSurface.new(outfile, width, height)
      context = Cairo::Context.new(surface)
      infile.each do |files|
        RVConfig[:yaml] = true if /.yaml$/ =~ files
        begin
          Zlib::GzipReader.open(files) do |gz|
            raw_xml = gz.read
          end
        rescue Zlib::GzipFile::Error
          open(files) do |red|
            raw_xml = red.read
          end
        end
        if RVConfig[:yaml]
          data = r2cairo.cairo_make_yaml(raw_xml)
        else
          doc = REXML::Document.new(raw_xml)
          data = r2cairo.cairo_make(doc)
        end
        r2cairo.cairo_make_pdfs(context, data)
        RVConfig[:yaml] = false
      end
      surface.finish
    end
    if RVConfig[:out_png]
      puts "create output PNG."
    else
      puts "create output PDF."
    end
    puts outfile
    exit 0
  else
    file = ARGV[0].to_s
    RVConfig[:yaml] = true if /(.yaml|.yaml.gz)$/ =~ file

    puts "in red file."
    puts file.to_s

    begin
      Zlib::GzipReader.open(file) do |gz|
        raw_xml = gz.read
      end
    rescue Zlib::GzipFile::Error
      open(file) do |red|
        raw_xml = red.read
      end
    end

    if $DEBUG
      Benchmark.bm do |x|
        x.report("XML Parse Time") do
          r2cairo = RedCairo.new
          r2cairo.scale = 70
          r2cairo.set_embed_data(embed_data)
          r2cairo.set_layer_visible(true) if RVConfig[:layer_visible]
          if RVConfig[:yaml]
            data = r2cairo.cairo_make_yaml(raw_xml)
          else
            doc = REXML::Document.new(raw_xml)
            data = r2cairo.cairo_make(doc)
          end
        end
      end
    else
      r2cairo = RedCairo.new
      r2cairo.scale = 70
      r2cairo.set_embed_data(embed_data)
      r2cairo.set_layer_visible(true) if RVConfig[:layer_visible]
      if RVConfig[:yaml]
        data = r2cairo.cairo_make_yaml(raw_xml)
      else
        doc = REXML::Document.new(raw_xml)
        data = r2cairo.cairo_make(doc)
      end
    end
    if RVConfig[:out_struct]
      r2cairo.get_embed_struct.each do |key, name|
        p key
        p name
      end
      exit 0
    end
  end

  window = Gtk::Window.new("Red2Cairo Widget sample")
  window.signal_connect("destroy"){Gtk.main_quit}
  window.set_default_size(640, 480)
  layout = Gtk::Layout.new
  p_widget = PreView_Widget.new
  p_widget.set_size_request(1240, 1754)
  layout.put(p_widget, 0, 0)

  box = Gtk::VBox.new
  box.add(layout)

  p_widget.move_max_x = -1000
  p_widget.move_max_y = -1000

  p_widget.signal_connect("expose_event") do |widget, event|
    context = widget.window.create_cairo_context
    xywh_array = widget.allocation.to_a
    x, y = xywh_array[0], xywh_array[1]
    # bx, by, bw, bh = box.allocation.to_a

    context.translate(x, y)
    context.scale(0.7, 0.7)
    r2cairo.cairo_draw(context, data)
    true
  end

  window.add(box)
  window.show_all
  Gtk.main_with_queue(100)
  #Gtk.main
end
