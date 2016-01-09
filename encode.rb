#!/usr/bin/env ruby

require 'find'
require 'fileutils'
require 'mini_exiftool'

VIDEO_EXTENSIONS = ['mov', 'mp4', 'm4v']
# e.g. Set to 720 or 1080 for better quality.
VIDEO_HEIGHT = 500
VIDEO_RATIO = 16.0/9

# Ratio of CPU to use. Set to 1 to utilize full CPU capacity.
CPU_RATIO = 0.5
CPU_CORES = 4
CPU_LIMIT = CPU_RATIO * 100 * CPU_CORES

FILE_DATE_META = ['FileModifyDate', 'CreationDate']

TARGET_DIR_SUFFIX = '_encoded'

source_dir = ARGV[0]
target_dir = ARGV[1]

unless source_dir and File.directory?(source_dir)
  abort "Invalid source directory"
end

unless target_dir
  target_dir = File.expand_path "#{ARGV[0]}/../#{File.basename(ARGV[0])}#{TARGET_DIR_SUFFIX}"
  FileUtils.mkdir_p(target_dir)
end

puts "source_dir: #{source_dir}"
puts "target_dir: #{target_dir}"

def encode_video(source_file, dest_file, width, rotation=0, audio_bitrate=128, quality=28)
  # Advanced options from HandBrake preset.
  x264Advanced = "level=4.0:ref=1:8x8dct=0:weightp=1:subme=2:mixed-refs=0:trellis=0:vbv-bufsize=25000:vbv-maxrate=20000:rc-lookahead=10"
  # Rotate, 1 flips on x, 2 flips on y, 3 flips on both (equivalent of 180 degree rotation).
  if rotation == 90
    rotate_mode = 4
    # Output width is now the source height.
    width *= VIDEO_RATIO
  elsif rotation == 180
    rotate_mode = 3
  end
  if rotate_mode
    rotate_str = " --rotate=\"#{rotate_mode}\""
  end
  pid = spawn "HandBrakeCLI -i '#{source_file}' -o '#{dest_file}' -e x264 -O -B #{audio_bitrate} -q #{quality} -X #{width} -x #{x264Advanced} #{rotate_str}"
  # Limit the CPU during the conversion to reduce impact.
  `cpulimit -p #{pid} -l #{CPU_LIMIT}`
end

def is_landscape(file)
  movie = MiniExiftool.new(file)
  rotation = get_rotation(file)
  if rotation == 90
    width = movie.imageheight
    height = movie.imagewidth
  else
    width = movie.imagewidth
    height = movie.imageheight
  end
  width > height
end

def get_rotation(file)
  movie = MiniExiftool.new(file)
  movie.rotation
end

def set_date(source_file, dest_file)
  source = MiniExiftool.new(source_file)
  dest = MiniExiftool.new(dest_file)
  FILE_DATE_META.each do |property|
    dest.copy_tags_from(source_file, property)
  end
  dest.save
end

Find.find(source_dir) do |name|
  next unless VIDEO_EXTENSIONS.include? File.extname(name).downcase.gsub(/^./, '')
  source_file = name
  dest_file = File.join target_dir, File.basename(name)
  width = is_landscape(source_file) ? VIDEO_RATIO * VIDEO_HEIGHT : VIDEO_HEIGHT
  rotation = get_rotation(source_file)
  encode_video(source_file, dest_file, width, rotation)
  set_date(source_file, dest_file)
end
