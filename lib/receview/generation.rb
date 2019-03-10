# -*- encoding: utf-8 -*-
# Ruby1.8 -> Ruby1.9

$KCODE = "u" if RUBY_VERSION.to_s <= "1.8.7"

unless String.public_method_defined?(:encoding)
  class String
    def encoding
      self
    end
  end
end

unless String.public_method_defined?(:encode)
  class String
    def encode(enc)
      self
    end
  end
end

unless String.public_method_defined?(:encode!)
  class String
    def encode!(enc)
      case enc
      when 'UTF-8'
        NKF.nkf("-w", self)
      when 'EUC-JP'
        NKF.nkf("-e", self)
      when 'SHIFT-JIS'
        NKF.nkf("-s", self)
      else
        self
      end
    end
  end
end

unless String.public_method_defined?(:force_encoding)
  class String
    def force_encoding(enc)
      self
    end
  end
end

unless String.public_method_defined?(:bytesize)
  class String
    def bytesize
      self.length
    end
  end
end

if __FILE__ == $0
  a = "String\nPtring"
  p a.encoding
  p a.encode("UTF-8")
  p a.encode!("UTF-8")
  p a.force_encoding("UTF-8")
  p a.length
  p a.bytesize
end
