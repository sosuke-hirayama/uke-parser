# -*- encoding: utf-8 -*-

# Ruby1.8, 1.9
require 'jma/receview/generation'
require 'jma/receview/env'

# use Gtk.queue return Dummy Thread.
class ThreadDummy
  def initialize(&block)
    if block.class == Proc
      block.call
    end
  end
  def start; true; end
  def run; true; end
  def join; true; end
  def kill; true; end
  def status; false; end
  def exit; true; end
end

if defined?(Thread)
class Thread
  def Thread::platform_support_thread
    pf_thread = false
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      if RUBY_VERSION.to_s >= "1.9.0"
        pf_thread = false
      else
        pf_thread = true
      end
    else
      pf_thread = true
    end
    pf_thread
  end

  def Thread::os
    if @@platform_thread
      th_do = Thread.start do
        yield
      end
    else
      #th_do = Gtk.queue do 
      th_do = ThreadDummy.new do 
        yield
      end
    end
    return th_do
  end

  @@platform_thread = Thread::platform_support_thread
end

class ThreadReceView
  def initialize(max_thread=2)
    @max_thread = max_thread
    @mutex = []
    @entry = []
    @max_thread.times do |i|
      @entry.push([])
      @mutex.push(false)
      Thread.new do self.thread_pool(i) end
    end
  end

  def add(proc_data, thread_no=0)
    @entry[thread_no].push(proc_data)
  end

  def thread_pool(i)
    while true
      if @entry[i].size != 0
        @mutex[i] = true
        t = @entry[i].shift
        t.call
        @mutex[i] = false
      end
      sleep 0.1
    end
  end
end
end
