require "pathname"
require "fileutils"
require "net/telnet"

BASE_PATH = '/home/jemily/finished'
TVSHOW_BASEPATH = "/mnt/tvshows"
VIDEO_EXTENSIONS = [".mkv",".avi",".mp4",".mts",".m2ts"]
XBMC_HOSTNAME = "nuggetron"
XBMC_USERNAME = "xbmc"
XBMC_PASSWORD = "xbmc"
XBMC_PORT = "9090"

def process_rars(incoming_file)
  if File.extname(incoming_file) == ".rar"
    puts "Extracting RAR File: #{incoming_file}"
    `unrar e \"#{incoming_file}\" \"#{File.dirname(incoming_file)}\"`
    if $? == 0
      puts "UNRAR Successful!"
      Dir.glob("#{escape_glob(File.dirname(incoming_file))}/**/*.*").each do |incoming_file_rar|
        next if File.directory?(incoming_file_rar)
        move_videos(incoming_file_rar)
      end
    elsif $? != 0
      puts "UNRAR FAILED"
    end
  end
end

def move_videos(incoming_file)
  return if !File.exists?(incoming_file)
  if VIDEO_EXTENSIONS.include?(File.extname(incoming_file)) && File.dirname(incoming_file) != "." && File.size(incoming_file) > 50000000
    puts "Moving video file #{incoming_file}"
    FileUtils.mv(incoming_file, BASE_PATH)
    puts "Deleting Folder #{File.dirname(incoming_file)}"
    FileUtils.rm_rf(File.dirname(incoming_file))
  end
end

def filebot_rename()
  puts "Begin FileBot Rename"
  `filebot -rename #{BASE_PATH} --db thetvdb --format \"#{TVSHOW_BASEPATH}/{n}/{n} - s{s.pad(2)}e{es*.pad(2)join('e')} - {t}\" -non-strict`
  if $? == 0
    puts "Filebot Rename Successful!"
  elsif $? != 0
    puts "ERROR WITH RENAME"
  end
end

def process_exceptions()
  puts "Begin Processing Exceptions"
  tvshowregexp = /^((?<series_name>.+?)[. _-]+)s*(?<season_num>\d+)[. _-]*[eExX](?<ep_num>\d+)/
  Dir.glob("*.*").each do |files|
    next if File.directory?(files)
    results = tvshowregexp.match(files)
    next if results == nil
    show_name = results[tvshowregexp.named_captures["series_name"]]
    if show_name == /american.dad/i
      # files.gsub()
    elsif show_name == /tron/i
      # files.gsub()
    end
  end
end

def update_xbmc(hostname, port)
  puts "Begin Updating XBMC"
  telnethost = Net::Telnet::new("Host" => "#{hostname}","Port" => "#{port}", "Timeout" => 10,"Prompt" => /.*/, "Waittime" => 3)
  telnethost.cmd(%{{"jsonrpc":"2.0","method":"VideoLibrary.Scan","id":1}}) { |c| puts c}
  telnethost.close
  puts "XBMC Update is probably complete?"
end

def escape_glob(s)
  s.gsub(/[\\\{\}\[\]\*\?]/) { |x| "\\"+x }
end

Dir.chdir(BASE_PATH)
Dir.glob("**/*.*").each do |some_file|
  next if File.directory?(some_file)
  process_rars(some_file)
  move_videos(some_file)
end

filebot_rename()
update_xbmc(XBMC_HOSTNAME, XBMC_PORT)
