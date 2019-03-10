# -*- encoding: utf-8 -*-

if __FILE__ == $0
  sleep 2.0
  if /linux/ =~ RUBY_PLATFORM.downcase
    system("/usr/bin/jma-receview")
  else
    require 'jma/receview/base'
    base = ReceView_Base.new
    exec_url = [base.get_path, "jrv-run.exe"].join(base.path_char)
    system(exec_url)
  end
end
