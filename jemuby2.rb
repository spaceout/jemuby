require "pathname"
require "fileutils"
require "net/telnet"

BASE_PATH = '/home/jemily/renametest/test'
TVSHOW_BASEPATH = "/home/jemily/renametest/test2"
VIDEO_EXTENSIONS = [".mkv",".avi",".mp4",".mts",".m2ts"]
XBMC_HOSTNAME = "nuggetron"
XBMC_USERNAME = "xbmc"
XBMC_PASSWORD = "xbmc"
XBMC_PORT = "9090"
MIN_VIDEOSIZE = 1000

def process_rars(incoming_folder)
  puts "Searching #{incoming_folder} for rar files"
  Dir.glob("#{escape_glob(incoming_folder)}/**/*.rar").each do |rar_file|
    puts "Extracting RAR File: #{incoming_file}"
    `unrar e \"#{incoming_file}\" \"#{File.dirname(rar_file)}\"`
    if $? == 0
      puts "UNRAR of #{rar_file} Successful!"
    elsif $? != 0
      puts "UNRAR of #{rar_file} Failed"
      abort("FATAL Error unrarring #{rar_file}")
    end
  end
  puts "Completed rar processing on #{incoming_folder}"
end

def move_videos(incoming_folder)
  puts "Begin processing #{incoming_folder} for video files"
  Dir.glob("#{escape_glob(incoming_folder)}/**/*{#{VIDEO_EXTENSIONS.join(",")}}").each do |video_file|
    if File.size(video_file) > MIN_VIDEOSIZE
      puts "Moving #{video_file} to #{BASE_PATH}"
      FileUtils.mv(video_file, BASE_PATH)
    end
  end
end

def delete_folder(incoming_folder)
  puts "Double Checking to make sure #{incoming_folder} is clean"
  Dir.glob("#{escape_glob(incoming_folder)}/**/*{#{VIDEO_EXTENSIONS.join(",")}}").each do |video_file|
    if File.size(video_file) > MIN_VIDEOSIZE
      abort("FATAL ERROR #{incoming_folder} IS NOT EMPTY")
    end
  end
  puts "Deleting #{incoming_folder}"
  FileUtils.rm_rf(incoming_folder)
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
Dir.glob("*").each do |dir_entry|
  if File.directory?(dir_entry)
    process_rars(dir_entry)
    move_videos(dir_entry)
    delete_folder(dir_entry)
  end
end
# added
