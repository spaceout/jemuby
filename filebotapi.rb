require 'logger'
require 'xmlsimple'

class FileBotAPI
  def initialize(logger = nil)
    @log = logger || Logger.new(STDOUT)
  end

  def filebot_rename(base_path, tvshow_basepath, filebot_log)
    @log.info "Begin FileBot Rename"
    fb_result = `filebot -rename #{base_path} --db thetvdb --format \"#{tvshow_basepath}/{n}/{n} - s{s.pad(2)}e{es*.pad(2)join('e')} - {t}\" -non-strict 2>&1`
    if $? == 0
      @log.info "Filebot Rename Successful!"
      get_history(filebot_log)
    elsif $? != 0
      @log.error "ERROR WITH RENAME"
      puts fb_result
      abort
    end
  end

  def get_history(filebot_log)
    filebot_history = XmlSimple.xml_in(filebot_log)
    @log.info "FileBot History From: #{filebot_history['sequence'].last['date']}"
    filebot_history['sequence'].last['rename'].each do |rename_item|
      @log.info "FROM: " + rename_item['from'] + " TO: " + rename_item['to']
    end
    @log.info "End FileBot History"
  end

end

