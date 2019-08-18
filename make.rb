require 'open-uri'
require 'fileutils'

out_dir = ARGV[0]
unless File.directory?(out_dir)
  raise "usage: #$0 OUT_DIR"
end

AUTHOR = 'Yukihiro Matsumoto <matz@ruby-lang.org>'

FILES = <<EOD
ruby-0.49.tar.gz 214390 2015-07-25T01:35:23.000Z
ruby-0.50.tar.gz 219673 2015-07-25T01:35:23.000Z
ruby-0.51.tar.gz 236604 2015-07-25T01:35:23.000Z
ruby-0.51-0.52.diff.gz 6334 2018-01-25T04:29:11.000Z
ruby-0.54.tar.gz 241736 2015-07-25T01:35:24.000Z
ruby-0.55.tar.gz 242261 2015-07-25T01:35:24.000Z
ruby-0.55-0.56.diff.gz 5644 2018-01-25T04:29:11.000Z
ruby-0.60.tar.gz 223532 2015-07-25T01:35:24.000Z
ruby-0.62.tar.gz 224325 2018-06-13T06:51:19.000Z
ruby-0.62.tar.gz.broken 238311 2018-06-13T06:51:19.000Z
ruby-0.63.tar.gz 224525 2018-06-13T06:51:19.000Z
ruby-0.63.tar.gz.broken 238511 2018-06-13T06:51:19.000Z
ruby-0.64.tar.gz 227088 2015-07-25T01:35:28.000Z
ruby-0.65.tar.gz 237040 2015-07-25T01:35:27.000Z
ruby-0.65-0.66.diff.gz 5020 2018-01-25T04:29:11.000Z
ruby-0.66-0.67.diff.gz 17897 2018-01-25T04:29:10.000Z
ruby-0.67-0.68.diff.gz 17074 2018-01-25T04:29:11.000Z
ruby-0.69.tar.gz 228241 2015-07-25T01:35:28.000Z
ruby-0.70-patch 2442 2018-01-25T04:29:11.000Z
ruby-0.71.tar.gz 226276 2015-07-25T01:35:28.000Z
ruby-0.71-0.72.diff.gz 4785 2018-01-25T04:29:11.000Z
ruby-0.73.tar.gz 228960 2015-07-25T01:35:28.000Z
ruby-0.73-950413.tar.gz 237953 2015-07-25T01:35:28.000Z
ruby-0.76.tar.gz 243351 2015-07-25T01:35:28.000Z
ruby-0.95.tar.gz 311119 2015-07-25T01:35:29.000Z
ruby-0.99.4-961224.tar.gz 352090 2015-07-25T01:35:29.000Z
ruby-1.0-961225.tar.gz 351918 2015-07-25T01:35:29.000Z
ruby-1.0-971002.tar.gz 424955 2015-07-25T01:35:29.000Z
ruby-1.0-971003.tar.gz 428993 2015-07-25T01:35:30.000Z
ruby-1.0-971015.tar.gz 430315 2015-07-25T01:35:30.000Z
ruby-1.0-971021.tar.gz 430549 2015-07-25T01:35:30.000Z
ruby-1.0-971118.tar.gz 431303 2015-07-25T01:35:30.000Z
ruby-1.0-971125.tar.gz 431375 2015-07-25T01:35:30.000Z
ruby-1.0-971204.tar.gz 431643 2015-07-25T01:35:30.000Z
ruby-1.0-971209.tar.gz 432426 2015-07-25T01:35:30.000Z
ruby-1.0-971225.tar.gz 432518 2015-07-25T01:35:30.000Z
EOD

files = FILES.lines.reject{|line|
  line =~ /broken/
}.map{|line|
  line.split.first
}

Dir.chdir(out_dir) do
  %w[repo archives].each do |dir|
    begin
      Dir.mkdir(dir)
    rescue Errno::EEXIST
    end
  end
  system(*%W"git -C repo init")
end

BASE_URI = URI("http://ftp.ruby-lang.org/pub/ruby/1.0/")
# Download
Dir.chdir("#{out_dir}/archives") do
  files.each do |filename|
    next if File.exist?(filename)
    puts "Download #{filename}"
    (BASE_URI + filename).open {|f| IO.copy_stream(f, filename)}
  end
end

DATE_REGEXP = /^\+{3} \S+\t\K\w{3} .*/
# Make
Dir.chdir("#{out_dir}") do
  files.each do |filename|
    tar_path = "archives/#{filename}"
    puts tar_path
    case filename
    when /\Aruby-[\d.]+(-[\d.]+)\.diff\.gz\z/
      message = "ruby#{$1}"
      diff = IO.popen(%W[gzcat #{tar_path}], "rb", &:read)
      date = diff[DATE_REGEXP]
      IO.popen([*%W"patch -d repo -p1"], "w") do |f|
        f.write(diff)
      end
      $?.success? or raise "Command failed with exit #{$?.exitstatus}: path"
    when /-patch\z/
      message = $`
      date = File.open(tar_path, "rb") do |f|
        f.gets
        f.gets
        f.gets[DATE_REGEXP]
      end
      system *%W"patch -d repo -p1", in: tar_path, exception: true
    when /\.tar\./
      message = $`
      system *%W"tar -xpzf #{tar_path}", exception: true
      FileUtils.rm_rf(Dir.glob("repo/*"))
      Dir.glob(%w"ruby/* ruby-*/*") do |n|
        File.rename(n, "repo/#{File.basename(n)}")
      end
      FileUtils.rmdir(Dir.glob(%w"ruby ruby-*"))
      date = File.mtime("repo/ChangeLog")
    end
    puts "Date: #{date}"
    system *%W"git -C repo add .", exception: true
    system *%W"git -C repo commit --date=#{date} --author=#{AUTHOR} -m #{message}", exception: true
  end
end
