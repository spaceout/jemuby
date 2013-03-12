require "pathname"
require "fileutils"
require "logger"
require "yaml"
require_relative 'filemanipulator'
require_relative 'xmissionapi'
require_relative 'xbmcapi'
require_relative 'filebotapi'

USER = ENV['USER']
CURRENTSCRIPTDIR = File.dirname(__FILE__)

#Process Configuration file an create it if it does not exist
if File.exist?("/home/#{USER}/.jemuby/config.yml")
  config = YAML.load_file("/home/#{USER}/.jemuby/config.yml")
else
  fileutils.mkdir("/home/#{USER}/.jemuby/") unless File.exists?("/home/#{USER}/.jemuby/")
  fileutils.mv("#{CURRENTSCRIPTDIR}/config.yml.sample", "/home/#{USER}/.jemuby/config.yml")
  config = YAML.load_file("/home/#{USER}/.jemuby/config.yml")
end
config["config"].each { |key, value| instance_variable_set("@#{key}", value) }

#Initialize Logger
if @LOGTOFILE == false
  log = Logger.new(STDOUT)
elsif @LOGTOFILE == true
  log = Logger.new(@LOGFILE, 'weekly')
end
log.level = Logger::INFO
log.datetime_format = "%Y-%m-%d %H:%M:%S"
log.formatter = proc do |severity, datetime, progname, msg|
  "[#{datetime.strftime(log.datetime_format)}] #{severity}: #{msg}\n"
end
log.info "Script Initialized"

#Transmission Processing
processGo = false
log.info "Transmission processing Started"
xmission = XmissionApi.new(:username => @TRANSMISSION_USER,:password => @TRANSMISSION_PASSWORD,:url => @TRANSMISSION_URL,:logger => log)
xmission.all.each do |download|
  if download["isFinished"] == true && download["downloadDir"] == @BASE_PATH + "/"
    log.warn "Removing #{download["name"]} from Transmission"
    xmission.remove(download["id"])
    processGo = true
  end
end
log.info "Transmission processing Complete"

#File Processing
if processGo == true || @RUNFROM_CLI == true
  fm = FileManipulator.new(log)
  Dir.chdir(@BASE_PATH)
  Dir.glob("*").each do |dir_entry|
    if File.directory?(dir_entry)
      fm.process_rars(dir_entry)
      fm.move_videos(dir_entry, @BASE_PATH, @MIN_VIDEOSIZE)
      fm.delete_folder(dir_entry, @MIN_VIDEOSIZE)
    end
  end
  fb = FileBotAPI.new(log)
  fb.filebot_rename(@BASE_PATH, @TVSHOW_BASEPATH, @FILEBOT_LOG)
  xb = XbmcApi.new(log)
  xb.update_xbmc(@XBMC_HOSTNAME, @XBMC_PORT)
  log.info "Script Completed successfully"
end
