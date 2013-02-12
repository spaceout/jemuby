require "pathname"
require "fileutils"
require "net/telnet"
require "logger"
require 'rb-inotify'

BASE_PATH = '/home/jemily/renametest/test'
TVSHOW_BASEPATH = "/home/jemily/renametest/test2"
VIDEO_EXTENSIONS = [".mkv",".avi",".mp4",".mts",".m2ts"]
XBMC_HOSTNAME = "nuggetron"
XBMC_USERNAME = "xbmc"
XBMC_PASSWORD = "xbmc"
XBMC_PORT = "9090"
MIN_VIDEOSIZE = 1000
WATCHER_ENABLED = true

def process_rars(incoming_folder)
  @log.info "Searching #{incoming_folder} for rar files"
  Dir.glob("#{escape_glob(incoming_folder)}/**/*.rar").each do |rar_file|
    @log.info "Extracting RAR File: #{rar_file}"
    `unrar e \"#{rar_file}\" \"#{File.dirname(rar_file)}\"`
    if $? == 0
      @log.info "UNRAR of #{rar_file} Successful!"
    elsif $? != 0
      @log.error "UNRAR of #{rar_file} Failed"
      abort("FATAL Error unrarring #{rar_file}")
    end
  end
  @log.info "Completed rar processing on #{incoming_folder}"
end

def move_videos(incoming_folder)
  @log.info "Begin processing #{incoming_folder} for video files"
  Dir.glob("#{escape_glob(incoming_folder)}/**/*{#{VIDEO_EXTENSIONS.join(",")}}").each do |video_file|
    if File.size(video_file) > MIN_VIDEOSIZE
      @log.warn "Moving #{video_file} to #{BASE_PATH}"
      FileUtils.mv(video_file, BASE_PATH)
    end
  end
end

def delete_folder(incoming_folder)
  @log.info "Double Checking to make sure #{incoming_folder} is clean"
  Dir.glob("#{escape_glob(incoming_folder)}/**/*{#{VIDEO_EXTENSIONS.join(",")}}").each do |video_file|
    if File.size(video_file) > MIN_VIDEOSIZE
      abort("FATAL ERROR #{incoming_folder} IS NOT EMPTY")
    end
  end
  @log.warn "Deleting #{incoming_folder}"
  FileUtils.rm_rf(incoming_folder)
end

def filebot_rename()
  @log.info "Begin FileBot Rename"
  `filebot -rename #{BASE_PATH} --db thetvdb --format \"#{TVSHOW_BASEPATH}/{n}/{n} - s{s.pad(2)}e{es*.pad(2)join('e')} - {t}\" -non-strict`
  if $? == 0
    @log.info "Filebot Rename Successful!"
  elsif $? != 0
    @log.error "ERROR WITH RENAME"
    abort("FATAL ERROR WITH RENAME")
  end
end

def update_xbmc(hostname, port)
  @log.info "Begin Updating XBMC"
  telnethost = Net::Telnet::new("Host" => "#{hostname}","Port" => "#{port}", "Timeout" => 10,"Prompt" => /.*/, "Waittime" => 3)
  telnethost.cmd(%{{"jsonrpc":"2.0","method":"VideoLibrary.Scan","id":1}}) { |c| puts c}
  telnethost.close
  @log.info "XBMC Update is probably complete?"
end

def escape_glob(s)
  s.gsub(/[\\\{\}\[\]\*\?]/) { |x| "\\"+x }
end

def setup_logger()
  @log = Logger.new(STDOUT)
  @log.level = Logger::INFO
  @log.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime}] #{severity}: #{msg}\n"
  end
  @log.info "Logger Initialized"
end

def post_process()
  filebot_rename()
  #update_xbmc(XBMC_HOSTNAME, XBMC_PORT)
  @log.info "Script Completed successfully"
end

def process_dir(directory)
  process_rars(directory)
  move_videos(directory)
  delete_folder(directory)
end

setup_logger()
Dir.chdir(BASE_PATH)

if WATCHER_ENABLED == false
  Dir.glob("*").each do |dir_entry|
    if File.directory?(dir_entry)
      process_dir(dir_entry)
    end
  end
  post_process()
elsif WATCHER_ENABLED == true
  @log.info "initializing Watcher on #{BASE_PATH}"
  notifier = INotify::Notifier.new
  notifier.watch("#{BASE_PATH}", :move) do |dir_entry|
    @log.info "Notifier Fired! Pausing Notifier"
    notifier.stop
    if File.directory?("#{dir_entry.name}")
      @log.info "New Directory Seen #{dir_entry.name}"
      process_dir(dir_entry.name)
    else
      @log.info "New File Seen #{dir_entry.name}"
    end
    post_process()
    @log.info "Restarting Notifier"
    notifier.run
  end
  @log.info "Launching Daemon"
  notifier.run
end
