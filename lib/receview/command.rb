# -*- encoding: utf-8 -*-

require 'jma/receview/generation'

class ReceView_Command
  require 'pathname'
  require 'jma/receview/base'
  attr_accessor :mount_flg
  attr_accessor :mount_mode
  attr_accessor :file_point
  attr_accessor :mount_dev
  attr_accessor :native_dev
  attr_reader :win_dev
  attr_reader :win_dev_type

  MOUNT_LEVEL_COMPULSION = 0
  MOUNT_LEVEL_MODERATION = 1
  MOUNT_LEVEL_NOTWORK = 2

  def initialize(base=nil)
    if base.nil?
      @base = ReceView_Base.new
    else
      @base = base
    end
    @mount_flg = false
    @mount_mode = 0
    @file_point = "/floppy/RECEIPTC.UKE"
    @mount_command = "mount"
    @umount_command = "umount"
    @udisks_mount_command = "udisks --mount"
    @udisks_umount_command = "udisks --unmount"
    @mount_dev = "/floppy"
    @native_dev = "/dev/fd0"
    c = @base.path_char
    @win_dev = [
      "A:"+c,
      "B:"+c,
      "C:"+c,
      "D:"+c,
      "E:"+c,
      "F:"+c,
      "G:"+c,
      "H:"+c,
      "I:"+c,
      "J:"+c,
      "K:"+c,
      "L:"+c,
      "M:"+c,
      "N:"+c,
      "O:"+c,
      "P:"+c,
      "Q:"+c,
      "R:"+c,
      "S:"+c,
      "T:"+c,
      "U:"+c,
      "V:"+c,
      "W:"+c,
      "X:"+c,
      "Y:"+c,
      "Z:"+c,
    ]
    @win_dev_type = {
      "DRIVE_UNKNOWN" => "0",
      "DRIVE_NO_ROOT_DIR" => "1",
      "DRIVE_REMOVABLE" => "2",
      "DRIVE_FIXED" => "3",
      "DRIVE_REMOTE" => "4",
      "DRIVE_CDROM" => "5",
      "DRIVE_RAMDISK" => "6",

      "0" => "DRIVE_UNKNOWN",
      "1" => "DRIVE_NO_ROOT_DIR",
      "2" => "DRIVE_REMOVABLE",
      "3" => "DRIVE_FIXED",
      "4" => "DRIVE_REMOTE",
      "5" => "DRIVE_CDROM",
      "6" => "DRIVE_RAMDISK",
    }

    if File.exist?(@base.path_fstab)
      begin
        open(@base.path_fstab).read.split(/\n/).each do |fstab_data|
          if /floppy|cdrom/ =~ fstab_data and /^\s*#/ !~ fstab_data
            fdev = fstab_data.split(/\s+/)
            @native_dev = fdev[0].to_s
            @mount_dev = fdev[1].to_s
            break if File.exist?(@native_dev)
          end
        end
      rescue
        @native_dev = "/dev/fd0"
        @mount_dev = "/floppy"
      end
      @file_point = @file_point.sub(/\/floppy/, @mount_dev)
      if /linux/ =~ RUBY_PLATFORM.downcase
        ReceViewLog.save(@file_point)
      end
    else
      if /linux/ =~ RUBY_PLATFORM.downcase
        ReceViewLog.save("#{@base.path_fstab} error")
        ReceViewLog.save(@file_point)
      end
    end
  end

  def get_dev_name
    if /linux/ =~ RUBY_PLATFORM.downcase
      native_dev = ""
      if File.exist?(@base.path_fstab)
        begin
          open(@base.path_fstab).read.split(/\n/).each do |fstab_data|
            if /floppy|cdrom/ =~ fstab_data and /^\s*#/ !~ fstab_data
              fdev = fstab_data.split(/\s+/)
              native_dev = fdev[0].to_s
              if /#{@mount_dev}/ =~ fdev[1].to_s
                break if File.exist?(native_dev)
              end
            end
          end
        rescue
          native_dev = "/dev/fd0"
        end
      else
        ReceViewLog.save("#{@base.path_fstab} error")
        ReceViewLog.save("get dev type error")
      end
      return native_dev
    end
  end

  def get_mount_path
    if /linux/ =~ RUBY_PLATFORM.downcase
      mount_path = ""
      mount_path_next = []
      if File.exist?(@base.path_fstab)
        begin
          open(@base.path_fstab).read.split(/\n/).each do |fstab_data|
            if /^\s*#/ !~ fstab_data && fstab_data.size != 0
              fdev = fstab_data.gsub(/\s+/, " ").sub(/^\s+/, "").split(/\s+/)
              case self.get_dev_group(fdev[0].to_s)
              when "cdrom"
                mount_path = fdev[1].to_s
              when "floppy"
                mount_path = fdev[1].to_s
              when "disk"
                mount_path_next.push([fdev[0].to_s, fdev[1].to_s])
              end
              if File.exist?(mount_path) && mount_path != ""
                if File::ftype(mount_path).to_s == "link"
                  mount_path = Pathname.new(mount_path).realpath.to_s
                end
                mount_path_next.clear
                break
              end
            end
          end
        rescue
          mount_path = "/floppy"
        end
      end
      if !mount_path_next.empty?
        mount_path_next.each do |dev, directory|
          if /#{@base.dev_floppy}/ =~ directory
            if File::ftype(directory).to_s == "link"
              mount_path = Pathname.new(directory).realpath.to_s
            else
              mount_path = directory
            end
            break
          end
        end
      end
      return mount_path
    end
  end

  def device_group
    self.get_dev_group
  end

  def get_dev_group(native_dev=self.get_dev_name)
    gid_name = "none"
    if File.exist?(native_dev)
      nfile = File::stat(native_dev)
      group_id = nfile.gid.to_s

      file_group = open(@base.path_group)
      file_group.read.split(/\n/).each do |lgroup|
        lgroup_data = lgroup.split(/:/)
        if lgroup_data[2].to_s == group_id
          gid_name = lgroup_data[0].to_s
          break
        end
      end
      file_group.close
    end
    return gid_name
  end

  def get_dev_list 
    return ReceViewWin32::Command.new.get_dev_list
  end

  def make_dev_list
    return ReceViewWin32::Command.new.make_dev_list
  end

  def fs_add_devlist(list_model)
    return ReceViewWin32::Command.new.fs_add_devlist(list_model)
  end

  def get_temp_pathsize
    return ReceViewWin32::Command.new.get_temp_pathsize
  end

  def get_temp_path
    return ReceViewWin32::Command.new.get_temp_path
  end

  def set_mount_mode(mmode)
    if /\d+/ =~ mmode.to_s
      @mount_mode = mmode.to_i
    end
  end

  def mount_done?(mount_dev=@mount_dev)
    if /linux/ =~ RUBY_PLATFORM.downcase
      if `df -h | grep '#{mount_dev}'`.to_s.empty?
        return false
      else
        return true
      end
    else
      return false
    end
  end

  def mount_daemon?
    oldauto_file = "/etc/auto.misc"
    oldauto_cmd = "ps ax | grep /var/autofs/misc | grep -v grep"
    flg = 0

    if File.exist?(oldauto_file)
      open(oldauto_file) do |data|
        oldauto_data = data.read
        if /^floppy/ =~ oldauto_data
          if /\/dev\/fd/ =~ oldauto_data or /\/dev\/sd/ =~ oldauto_data
            flg+=1
          end
        end
      end
    end

    oldauto_ps =`#{oldauto_cmd}`.split(/\n/)
    if oldauto_ps.size != 0
      ReceViewLog.save("autofs: " + oldauto_ps.to_s)
      if /autofs/ =~ oldauto_ps.to_s
        flg+=1
      end
    end
    return flg
  end

  def mount(mount_command=@mount_command, mount_dev=@mount_dev)
    if /linux/ =~ RUBY_PLATFORM.downcase
      flg = mount_daemon?
      if flg != 2
        if $DEBUG
          ReceViewLog.save("mount_command: " + mount_command.to_s)
          ReceViewLog.save("mount_dev:" + mount_dev.to_s)
          ReceViewLog.save("mount_mode:" + @mount_mode.to_s)
        end
        case @mount_mode.to_i
        when MOUNT_LEVEL_COMPULSION
          if @base.os_type_udisks && /#{@base.dev_floppy}/ =~ mount_dev 
            mount_dev_udisks = @base.get_device_fstab(mount_dev, "dev")
            if @base.fdd_device_build_in?(mount_dev_udisks)
              system(mount_command+" "+mount_dev)
            else
              mount_command = @udisks_mount_command
              if !mount_dev_udisks.nil?
                system(mount_command+" "+mount_dev_udisks)
                system("sync")
              end
            end
          else
            system(mount_command+" "+mount_dev)
          end
        when MOUNT_LEVEL_MODERATION
          if !mount_done?(mount_dev)
            @mount_flg = true
            if @base.os_type_udisks && /#{@base.dev_floppy}/ =~ mount_dev 
              mount_dev_udisks = @base.get_device_fstab(mount_dev, "dev")
              if @base.fdd_device_build_in?(mount_dev_udisks)
                system(mount_command+" "+mount_dev)
              else
                mount_command = @udisks_mount_command
                if !mount_dev_udisks.nil?
                  system(mount_command+" "+mount_dev_udisks)
                  system("sync")
                end
              end
            else
              system(mount_command+" "+mount_dev)
            end
          else
            @mount_flg = false
            true
          end
        when MOUNT_LEVEL_NOTWORK
        else
          false
        end
      else
        return false
      end
    else
      return true
    end
  end

  def umount(mount_command=@umount_command, mount_dev=@mount_dev)
    if /linux/ =~ RUBY_PLATFORM.downcase
      flg = mount_daemon?
      if flg != 2
        if $DEBUG
          ReceViewLog.save("mount_command: " + mount_command.to_s)
          ReceViewLog.save("mount_dev:" + mount_dev.to_s)
          ReceViewLog.save("mount_mode:" + @mount_mode.to_s)
        end
        case @mount_mode.to_i
        when MOUNT_LEVEL_COMPULSION
          if @base.os_type_udisks && /#{@base.dev_floppy}/ =~ mount_dev 
            mount_dev_udisks = @base.get_device_fstab(mount_dev, "dev")
            if @base.fdd_device_build_in?(mount_dev_udisks)
              system(mount_command+" "+mount_dev)
            else
              if !mount_dev_udisks.nil?
                mount_command = @udisks_umount_command
                system("sync")
                system(mount_command+" "+mount_dev_udisks)
              end
            end
          else
            system(mount_command+" "+mount_dev)
          end
        when MOUNT_LEVEL_MODERATION
          if mount_done?(mount_dev) and @mount_flg
            @mount_flg = false
            if @base.os_type_udisks && /#{@base.dev_floppy}/ =~ mount_dev 
              mount_dev_udisks = @base.get_device_fstab(mount_dev, "dev")
              if @base.fdd_device_build_in?(mount_dev_udisks)
                system(mount_command+" "+mount_dev)
              else
                if !mount_dev_udisks.nil?
                  mount_command = @udisks_umount_command
                  system("sync")
                  system(mount_command+" "+mount_dev_udisks)
                end
              end
            else
              system(mount_command+" "+mount_dev)
            end
          else
            true
          end
        when MOUNT_LEVEL_NOTWORK
        else
          false
        end
      else
        return false
      end
    else
      return false
    end
  end
end

class ReceViewCommand < ReceView_Command
  def initialize
    super
  end
end

if __FILE__ == $0
  require 'jma/receview/base'
  require 'jma/receview/log'
  base = ReceView_Base.new
  command = ReceView_Command.new
  mount_dev = "/floppy"
  p base.get_device_fstab(mount_dev, "dev")
  p command.mount
  p command.umount
end
