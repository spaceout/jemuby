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
  CONFIG = YAML.load_file("/home/#{USER}/.jemuby/config.yml")["config"]
else
  FileUtils.mkdir("/home/#{USER}/.jemuby/") unless File.exists?("/home/#{USER}/.jemuby/")
  FileUtils.mv("#{CURRENTSCRIPTDIR}/config.yml.sample", "/home/#{USER}/.jemuby/config.yml")
  CONFIG = YAML.load_file("/home/#{USER}/.jemuby/config.yml")["config"]
end

#Initialize Logger
if CONFIG["logtofile"] == false
  log = Logger.new(STDOUT)
elsif CONFIG["logtofile"] == true
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
xmission = XmissionApi.new(:username => CONFIG["transmission_user"],:password => CONFIG["transmission_password"],:url => CONFIG["transmission_url"],:logger => log)
xmission.all.each do |download|
  if download["isFinished"] == true && download["downloadDir"] == CONFIG["base_path"] + "/"
    log.warn "Removing #{download["name"]} from Transmission"
    xmission.remove(download["id"])
    processGo = true
  end
end
log.info "Transmission processing Complete"

#File Processing
if processGo == true || CONFIG["runfrom_cli"] == true
  fm = FileManipulator.new(log)
  Dir.chdir(CONFIG["base_path"])
  Dir.glob("*").each do |dir_entry|
    if File.directory?(dir_entry)
      fm.process_rars(dir_entry)
      fm.move_videos(dir_entry, CONFIG["base_path"], CONFIG["min_videosize"])
      fm.delete_folder(dir_entry, CONFIG["min_videosize"])
    end
  end
  fb = FileBotAPI.new(log)
  fb.filebot_rename(CONFIG["base_path"], CONFIG["tvshow_basepath"], CONFIG["filebot_log"])
  xb = XbmcApi.new(log)
  xb.update_xbmc(CONFIG["xbmc_hostname"], CONFIG["xbmc_port"])
  log.info "Script Completed successfully"
end
