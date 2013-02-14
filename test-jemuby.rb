require "pathname"
require "fileutils"
require "logger"
require_relative 'filemanipulator'

#BASE_PATH = '/home/jemily/renametest/test'
#TVSHOW_BASEPATH = "/home/jemily/renametest/test2"
BASE_PATH = '/home/jemily/finished'
TVSHOW_BASEPATH = '/mnt/tvshows'
XBMC_HOSTNAME = "nuggetron"
XBMC_PORT = "9090"
MIN_VIDEOSIZE = 50000000

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
    fm.process_rars(dir_entry)
    fm.move_videos(dir_entry, BASE_PATH, MIN_VIDEOSIZE)
    fm.delete_folder(dir_entry, MIN_VIDEOSIZE)
  end
end
pp.filebot_rename(BASE_PATH, TVSHOW_BASEPATH)
pp.update_xbmc(XBMC_HOSTNAME, XBMC_PORT)
@log.info "Script Completed successfully"
