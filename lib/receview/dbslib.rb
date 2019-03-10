# -*- encoding: utf-8 -*-

require 'jma/receview/generation'

class DBSclient
  attr_accessor :timeout_size
  attr_reader :ex_error
  attr_reader :ex_status
  attr_reader :version
  require 'nkf'
  require 'uri'
  require 'socket'
  require 'timeout'

  TCPSocket.do_not_reverse_lookup = true

  def self.open (a,b,c,d,e)
    return self.new(a,b,c,d,e)
  end

  def initialize (version="1.4.3",feature=true, mode="dbs")
    @socket_try = 0
    @timeout_size = 5.0
    @ex_error  = ""
    @ex_status = "new"
    @version = version
    @feature = feature
    $DEBUG = false
    @s = nil
  end

  def set_timeout(time=5)
    if time > 30.0
      time = 30.0
    elsif time < 2.0
      time = 2.0
    end
    @timeout_size = time
  end

  def con(server="localhost", user="ormaster", pass="ormaster")
    @server = server
    @user = user
    @pass = pass

    # IPv6 Addr Support
    if /(^\[)([a-zA-Z0-9._:-]*)(\])/ =~ server
      if /(^\[)([a-zA-Z0-9._:-]*)(\])(:*)(\d*)/ =~ server
        server = $2
        port   = $5.to_i
      end
    else
      if /([a-zA-Z0-9._-]*)(:*)(\d*)/ =~ server
        server = $1
        port   = $3.to_i
      end
    end
    port = 9301 if port == 0

    begin
      timeout(@timeout_size) {
        @s = TCPSocket.new(server, port)
      }

      puts("#{@version} #{user} #{pass} stringe")
      msg = @s.gets
      if /^Error\: (.*?)$/ =~ msg
        @code = $1
        @s.close
        return @code
      else
        @socket_try+=1
        @ex_status = "connection:#{@socket_try.to_s}"
        dbctrl("DBOPEN")
      end
    rescue Timeout::Error
      error("timeout")
    rescue
      error("connection")
    end
  end


  def transaction
    begin 
      dbctrl("DBSTART")
      @ex_status = "dbstat"
      yield
      dbctrl("DBCOMMIT")
      @ex_status = "commit"
      @s.close if @s.class == TCPSocket
      @s = nil
      con(@server, @user, @pass)
      @ex_status = "connection:#{@socket_try.to_s}"
    rescue
      @ex_status = ""
      dbctrl("DBCOMMIT") if @s.class == TCPSocket
      error("transaction")
    end
  end

  def commit
    return dbctrl("DBCOMMIT")
  end

  def close(mode="")
    if mode.to_s.empty?
      dbctrl("DBDISCONNECT")
      puts("End\n")
      recv(:close)
    end
    begin 
      @s.close if @s.class == TCPSocket
      # @socket_try = 0
      @ex_status = "socket close"
    rescue
      @ex_status = "closed stream (IOError)"
    end
  end

  def dbctrl (type)
    begin
      puts("Exec: #{type}\n\n")
      result = recv(:dbctrl)
      puts("\n")
      return result
    rescue
      error "dbctrl failed #{type}"
    end
  end

  def select (st, num=nil)
    return dbfunc("DBSELECT", st, :select)
  end

  def fetch (st, num=nil)
    return dbfunc("DBFETCH",  st, :fetch)
  end

  def dbfunc(type, st, sender)
    begin
      puts "Exec: #{type}:#{st[:record]}:#{st[:key]}:#{st[:count]}\n"
      st[:query].each do |key, value|
        if sender == :fetch
          # puts "\n"
          break
        end
        value = value.map{|x| "\'#{x}\'"}.join(',') if value.class == Array
        puts "#{st[:record]}.#{key}: #{v_encode(value)}\n"
      end
      puts "\n"
      recv(:dbfunc, st)
      if @limit == 1
        puts("#{st[:record]};1\n")
      else
        puts("#{st[:record]};\n")
      end
      result = recv(:dbfunc, st)
      puts("\n")
      return result
    rescue
      error("dbfunc failed #{type}")
    end
  end

  def recv(sender, st=nil)
    ret = []
    @s.flush
    while (buf = @s.gets)
      p "< " + buf if $DEBUG
      break if lookmsg(buf) == :stop
      next if st == nil
      a = buf.chomp.gsub(/ /,"").split(":").map{|x|
        x.split(".").map{|y| y.split(";")}}.flatten

      a[3] = "DBERROR" if a[3].to_s == "%01"

      elm = a[0] =~ /\[(.*)\]/ ? $1.to_i : 0
      (ret[elm] ||= {})[a[1]] ||= {
        :type  => a[2],
        :value => v_decode(a[3]),
      }
    end
    return ret
  end

  def lookmsg(mes)
    return status(mes) if mes =~ /^Exec: .*$/
    return :stop if mes =~ /^\n$/
    return :incoming
  end

  def v_decode(string)
    ver = @version.gsub(/\./, "0").to_s
    if ver.to_i >= 10405
      url_decode(string.to_s).encode!("EUC-JP")
    else
      url_decode(string.to_s)
    end
  end

  def v_encode(string)
    ver = @version.gsub(/\./, "0").to_s
    if ver.to_i >= 10405
      url_encode(string.encode!("UTF-8"))
    else
      url_encode(string.to_s)
    end
  end

  def url_decode_pre(string)
    if string
      URI.decode(string.tr('+', ' '))
    end
  end

  def url_encode_pre(string)
    if string
      URI.encode(string.tr('+', ' '))
    end
  end

  def url_decode(string)
    if string
      string.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
        [$1.delete('%')].pack('H*')
      end
    end
  end
  
  def url_encode(string)
    if string
      string.gsub(/([^ a-zA-Z0-9_.-]+)/) do
        '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
      end.tr(' ', '+')
    end
  end

  def status(mes)
    buf = mes.gsub(/ /,'').split(':')
    @limit = buf[2].to_i
    error(buf[1].to_i) if buf[1].to_i < 0
    return :stop
  end

  def error(comment)
    @ex_error = comment
    if @ex_error.class != Fixnum
      raise "DBS Error: #{comment}"
    end
  end

  def puts(str)
    p "> " + str if $DEBUG
    @s.puts(str) if @s.class == TCPSocket
  end

  def DBSclient::URLdecode(string)
    if string
      string.gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
        [$1.delete('%')].pack('H*')
      end
    end
  end

  def DBSclient::URLencode(string)
    if string
      string.gsub(/([^ a-zA-Z0-9_.-]+)/n) do
        '%' + $1.unpack('H2' * $1.size).join('%').upcase
      end.tr(' ', '+')
    end
  end
end

if __FILE__ == $0
end
