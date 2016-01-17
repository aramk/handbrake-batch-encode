#!/usr/bin/env ruby

require 'find'
require 'fileutils'
require 'mini_exiftool'
require 'slop'

# Constants

VIDEO_EXTENSIONS = ['mov', 'mp4', 'm4v']
# e.g. Set to 720 or 1080 for better quality.
VIDEO_HEIGHT = 500
VIDEO_RATIO = 16.0/9

# Ratio of CPU to use. Set to 1 to utilize full CPU capacity.
CPU_RATIO = 0.5
CPU_CORES = 4
CPU_LIMIT = CPU_RATIO * 100 * CPU_CORES

FILE_DATE_META = ['FileModifyDate', 'CreationDate']

TARGET_SUFFIX = '_encoded'
ORIG_SUFFIX = '_original'

# Parse arguments

opts = Slop.parse do |o|
  o.bool '-d', '--same-directory', 'Place the encoded files in the same directory as their originals.'
  o.bool '-r', '--replace', 'Replace all original files with their encoded counterparts, if any. If an encoded file exists in the destination, it is not re-encoded.'
end

opts_hash = opts.to_hash
p opts_hash
p opts.arguments

source_dir = opts.arguments[0]
target_dir = opts.arguments[1]

unless source_dir and File.directory?(source_dir)
  abort "Invalid source directory"
end

if !target_dir and !opts_hash[:same_directory]
  target_dir = File.expand_path "#{source_dir}/../#{File.basename(source_dir)}#{TARGET_SUFFIX}"
  FileUtils.mkdir_p(target_dir)
end

puts "source_dir: #{source_dir}"
puts "target_dir: #{target_dir}"
if opts_hash[:replace]
  puts 'Replacing original files'
end

# AUXILIARY

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

def get_dest_file(source_file, target_dir, opts_hash)
  source_file = source_file.gsub(ORIG_SUFFIX, '')
  if opts_hash[:same_directory]
    dest_file = add_filename_suffix(source_file, TARGET_SUFFIX)
  else
    dest_file = File.join target_dir, File.basename(source_file)
  end
end

def add_filename_suffix(filename, suffix)
  filename.gsub(/\.\w+$/, suffix + '\0')
end

# END AUXILIARY

Find.find(source_dir) do |name|
  next unless VIDEO_EXTENSIONS.include? File.extname(name).downcase.gsub(/^./, '')
  next if name.include? TARGET_SUFFIX
  next if name.include? ORIG_SUFFIX

  source_file = name
  dest_file = get_dest_file(source_file, target_dir, opts_hash)
  orig_file = add_filename_suffix(source_file, ORIG_SUFFIX)

  puts "source_file: #{source_file}"
  puts "dest_file: #{dest_file}"
  puts "orig_file: #{orig_file}"
  puts ""

  # If an original file exists, then encoding and/or replacing was already completed.
  next if File.exists?(orig_file)

  # If the destination file doesn't exist or we are not replacing files, run the encoding. 
  if !opts_hash[:replace] or !File.exists?(dest_file)
    width = is_landscape(source_file) ? VIDEO_RATIO * VIDEO_HEIGHT : VIDEO_HEIGHT
    rotation = get_rotation(source_file)
    encode_video(source_file, dest_file, width, rotation)
    set_date(source_file, dest_file)
  end

  if opts_hash[:replace]
    FileUtils.mv source_file, orig_file
    # TODO(aramk) For some reason, immediately renaming causes an issue in Finder where the
    # dest_file renamed to the source_file isn't visible. This appears to help.
    sleep(0.5)
    FileUtils.mv dest_file, source_file
  end

end
