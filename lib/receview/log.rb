# -*- encoding: utf-8 -*-

require 'jma/receview/generation'

class ReceViewLog
  RECEVIEW_DIR = ".receview"
  RECEVIEW_LOG = "receview.log"
  USER_ONLY_RWX = 0700
  USER_ONLY_RW  = 0600
  LOG_LEVEL_0 = 0
  LOG_LEVEL_1 = 1
  LOG_LEVEL_2 = 2
  UNIQ_STAMP = "[#{Time.now.strftime("%Y%m%d%H%M%S").to_s}]"
  TAG = "  "

  def ReceViewLog.make_save_directory
    savedir = Dir.pwd
    Dir.chdir
    begin
      if File.exist?(RECEVIEW_DIR)
        ReceViewLog.log_access_mode(RECEVIEW_DIR)
      else
        Dir.mkdir(RECEVIEW_DIR, USER_ONLY_RWX)
      end
      Dir.chdir(RECEVIEW_DIR)
    rescue
      p "log save error."
    end
    yield

    begin
      ReceViewLog.log_access_mode(RECEVIEW_LOG)
    rescue
      p "Change of file authority went wrong. #{RECEVIEW_LOG}"
    end
    Dir.chdir(savedir)
  end

  def ReceViewLog.log_access_mode(path)
    if !path.empty?
      if File.exist?(path)
        log_ac = File::Stat.new(path).mode.to_s(8)
        if File.directory?(path)
          log_ac_0700 = log_ac.split(//)[1..4].to_s
        else
          log_ac_0700 = log_ac.split(//)[2..5].to_s
        end
        File.chmod(USER_ONLY_RWX, path) if log_ac_0700 == USER_ONLY_RWX
      end
    end
  end

  def ReceViewLog.auto_save(level=0)
    ReceViewLog.make_save_directory do ||
      File.open(RECEVIEW_LOG, "a+") do |file|
        #$stdout = ReceViewLog_Stdout if level >= 0
        #$stderr = ReceViewLog_Stderr if level >= 1
        STDOUT.reopen(file) if level >= 0
        STDERR.reopen(file) if level >= 1
      end
    end
  end

  def ReceViewLog.save(text)
    ReceViewLog.make_save_directory do ||
      file = open(RECEVIEW_LOG, "a+")
      file << Time.now.strftime("%Y-%m-%d %H:%M:%S").to_s
      file << "#{UNIQ_STAMP+TAG+text}\n"
      file.close
    end
  end

  def ReceViewLog.stop
    ReceViewLog.make_save_directory do ||
      file = open(RECEVIEW_LOG, "a+")
      file << "\n"
      file.close
    end
  end

  def ReceViewLog.clear_log
    ReceViewLog.make_save_directory do ||
      file = open(RECEVIEW_LOG, "w+")
      file << Time.now.strftime("%Y-%m-%d %H:%M:%S").to_s
      file << "#{UNIQ_STAMP+TAG}\n"
      file << "ReceView LogFile. ALL Clear\n"
      file.close
    end
  end
end

ReceViewLog_Stdout = Object.new
class << ReceViewLog_Stdout
  STAMP = ReceViewLog::UNIQ_STAMP + ReceViewLog::TAG
  def write(text)
    ReceViewLog.make_save_directory do ||
      file = open(ReceViewLog::RECEVIEW_LOG, "a+")
      file << Time.now.strftime("%Y-%m-%d %H:%M:%S").to_s
      file << "#{STAMP+text.gsub(/\n/, "")}\n"
    end
  end
  public :puts,:print
end


ReceViewLog_Stderr = Object.new
class << ReceViewLog_Stderr
  STAMP = ReceViewLog::UNIQ_STAMP + ReceViewLog::TAG
  def write(text)
    ReceViewLog.make_save_directory do ||
      file = open(ReceViewLog::RECEVIEW_LOG, "a+")
      file << Time.now.strftime("%Y-%m-%d %H:%M:%S").to_s
      file << "#{STAMP+text.gsub(/\n/, "")}\n"
    end
  end
  public :puts,:print
end

# ReceView_Log -> ReceViewLog
class ReceView_Log < ReceViewLog
  def initialize
    super
  end
end
