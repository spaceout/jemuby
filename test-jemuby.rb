require "pathname"
require "fileutils"
require "logger"
require_relative 'filemanipulator'
require_relative 'xmissionapi'
require_relative 'xbmcapi'
require_relative 'filebotapi'

#BASE_PATH = '/home/jemily/renametest/test'
#TVSHOW_BASEPATH = "/home/jemily/renametest/test2"
#MIN_VIDEOSIZE = 50
BASE_PATH = '/home/jemily/finished/tvshows'
TVSHOW_BASEPATH = '/mnt/tvshows'
MIN_VIDEOSIZE = 50000000
XBMC_HOSTNAME = "nuggetron"
XBMC_PORT = "9090"
TRANSMISSION_URL = "http://192.168.1.8:9091/transmission/rpc"
TRANSMISSION_USER = "transmission"
TRANSMISSION_PASSWORD = "transmission"
FILEBOT_LOG = '/home/jemily/.filebot/history.xml'
RUNFROM_CLI = true
LOGTOFILE = true
LOGFILE = '/home/jemily/jemuby/jemuby_log.txt'

if LOGTOFILE == false
  log = Logger.new(STDOUT)
elsif LOGTOFILE == true
  log = Logger.new(LOGFILE, 'weekly')
end
log.level = Logger::INFO
log.datetime_format = "%Y-%m-%d %H:%M:%S"
log.formatter = proc do |severity, datetime, progname, msg|
  "[#{datetime.strftime(log.datetime_format)}] #{severity}: #{msg}\n"
end
log.info "Script Initialized"

processGo = false
log.info "Transmission processing Started"
xmission = XmissionApi.new(:username => TRANSMISSION_USER,:password => TRANSMISSION_PASSWORD,:url => TRANSMISSION_URL,:logger => log)
xmission.all.each do |download|
  if download["isFinished"] == true && download["downloadDir"] == BASE_PATH + "/"
    log.warn "Removing #{download["name"]} from Transmission"
    xmission.remove(download["id"])
    processGo = true
  end
end
log.info "Transmission processing Complete"

if processGo == true || RUNFROM_CLI == true
  fm = FileManipulator.new(log)
  Dir.chdir(BASE_PATH)
  Dir.glob("*").each do |dir_entry|
    if File.directory?(dir_entry)
      fm.process_rars(dir_entry)
      fm.move_videos(dir_entry, BASE_PATH, MIN_VIDEOSIZE)
      fm.delete_folder(dir_entry, MIN_VIDEOSIZE)
    end
  end
  fb = FileBotAPI.new(log)
  fb.filebot_rename(BASE_PATH, TVSHOW_BASEPATH, FILEBOT_LOG)
  xb = XbmcApi.new(log)
  xb.update_xbmc(XBMC_HOSTNAME, XBMC_PORT)
  log.info "Script Completed successfully"
end
