# -*- encoding: utf-8 -*-

require 'jma/receview/generation'
require 'jma/receview/exception'

class ISOCDImage
  def initialize
  end

  def ISOCDImage.open(isofile, pattern='receiptc.uke')
    require "cdio"
    require "iso9660"

    iso = ISO9660::IFS::new(isofile)

    size = 0
    length = 0
    filename = ""

    begin
      iso.readdir("/").each do |buf|
        if Rubyiso9660.name_translate(buf["filename"]) == pattern and buf["type"] = 1
          size = buf["size"].to_i
          length = buf["lsn"].to_i
          filename = Rubyiso9660.name_translate(buf["filename"])
          break
        end
      end
      raise ReceISOFileRead if filename.empty?
      addr_sp = Rubycdio::ISO_BLOCKSIZE * length
      addr_ep = Rubycdio::ISO_BLOCKSIZE * length + size-1
      iso.close
      File.open(isofile).read[addr_sp..addr_ep].toutf8.encode!("UTF-8").rstrip
    rescue ReceISOFileRead
      false
    rescue
      fileio = File.open(isofile)
      file = fileio.read
      fileio.close
      file
    end
  end

  def ISOCDImage.list(isofile)
    require "cdio"
    require "iso9660"

    iso = ISO9660::IFS::new(isofile)
    filename = []

    begin
      iso.readdir("/").each do |buf|
        file = Rubyiso9660.name_translate(buf["filename"])
        if /^\.+$/ != file && buf["type"] == 1
          filename.push(file)
        end
      end
      raise ReceISOFileRead if filename.empty?
      iso.close
    rescue
    end
    filename
  end

  def ISOCDImage.libtest
    require "cdio"
    require "iso9660"
  end
end

if __FILE__ == $0
end
