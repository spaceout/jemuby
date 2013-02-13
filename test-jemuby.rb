require "pathname"
require "fileutils"
require "net/telnet"
require "logger"
require 'rb-inotify'
require_relative 'filemanipulator'

BASE_PATH = '/home/jemily/renametest/test'
TVSHOW_BASEPATH = "/home/jemily/renametest/test2"
VIDEO_EXTENSIONS = [".mkv",".avi",".mp4",".mts",".m2ts"]
XBMC_HOSTNAME = "nuggetron"
XBMC_PORT = "9090"
MIN_VIDEOSIZE = 1000

def setup_logger()
  @log = Logger.new(STDOUT)
  @log.level = Logger::INFO
  @log.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime}] #{severity}: #{msg}\n"
  end
  @log.info "Logger Initialized"
end

setup_logger()
fm = FileManipulator.new(@log)
pp = PostProcessor.new(@log)
Dir.chdir(BASE_PATH)
Dir.glob("*").each do |dir_entry|
  if File.directory?(dir_entry)
    fm.process_rars(directory)
    fm.move_videos(directory, BASE_PATH, MIN_VIDEOSIZE)
    fm.delete_folder(directory, MIN_VIDEOSIZE)
  end
end
pp.filebot_rename(BASE_PATH, TVSHOW_BASEPATH)
#pp.update_xbmc(XMBC_HOSTNAME, XBMC_PORT)
@log.info "Script Completed successfully"
