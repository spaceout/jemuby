require "pathname"
require "fileutils"
require "logger"
require "net/telnet"

VIDEO_EXTENSIONS = [".mkv",".avi",".mp4",".mts",".m2ts"]

class FileManipulator
  def initialize(logger = nil)
    @log = logger || Logger.new(STDOUT)
  end

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

  def move_videos(incoming_folder, base_path, min_videosize)
    @log.info "Begin processing #{incoming_folder} for video files"
    Dir.glob("#{escape_glob(incoming_folder)}/**/*{#{VIDEO_EXTENSIONS.join(",")}}").each do |video_file|
      if File.size(video_file) > min_videosize
        @log.warn "Moving #{video_file} to #{base_path}"
        FileUtils.mv(video_file, base_path)
      end
    end
  end

  def delete_folder(incoming_folder, min_videosize)
    @log.info "Double Checking to make sure #{incoming_folder} is clean"
    Dir.glob("#{escape_glob(incoming_folder)}/**/*{#{VIDEO_EXTENSIONS.join(",")}}").each do |video_file|
      if File.size(video_file) > min_videosize
        abort("FATAL ERROR #{incoming_folder} IS NOT EMPTY")
      end
    end
    @log.warn "Deleting #{incoming_folder}"
    FileUtils.rm_rf(incoming_folder)
  end

  def escape_glob(s)
    s.gsub(/[\\\{\}\[\]\*\?]/) { |x| "\\"+x }
  end
end

class PostProcessor
  def initialize(logger = nil)
    @log = logger || Logger.new(STDOUT)
  end

  def filebot_rename(base_path, tvshow_basepath)
    @log.info "Begin FileBot Rename"
    `filebot -rename #{base_path} --db thetvdb --format \"#{tvshow_basepath}/{n}/{n} - s{s.pad(2)}e{es*.pad(2)join('e')} - {t}\" -non-strict`
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
end
