#!/usr/bin/env ruby

require 'fileutils'

VIDEO_EXTENSIONS = ['mov', 'mp4']

source_dir = ARGV[0]
target_dir = ARGV[1]

unless source_dir and File.directory?(source_dir)
  abort "Invalid source directory"
end

unless target_dir
  target_dir = "#{ARGV[0]}/converted"
  FileUtils.mkdir_p(target_dir)
end

puts "source_dir: #{source_dir}"
puts "target_dir: #{target_dir}"

def encode_video(source_file, dest_file, width, audio_bitrate=128, quality=28)
  # advanced options from HandBrake preset
  x264Advanced = "level=4.0:ref=1:8x8dct=0:weightp=1:subme=2:mixed-refs=0:trellis=0:vbv-bufsize=25000:vbv-maxrate=20000:rc-lookahead=10"
  # rotate, 1 flips on x, 2 flips on y, 3 flips on both (equivalent of 180 degree rotation)
  `HandBrakeCLI -i "#{source_file}" -o "#{dest_file}" -e x264 -O -B #{audio_bitrate} -q #{quality} -w #{width} -x #{x264Advanced}`
end

def is_landscape(source_file)
  width = `mdls -name kMDItemPixelWidth "#{source_file}" | grep -o '\d\{3,\}'`
  height = `mdls -name kMDItemPixelHeight "#{source_file}" | grep -o '\d\{3,\}'`
  width > height
end

Dir.foreach(source_dir) do |name|
  next if name == '.' or name == '..'
  next if VIDEO_EXTENSIONS.include? File.extname(name).downcase.gsub(/^./, '')
  source_file = File.join(source_dir, name)
  dest_file = File.join(target_dir, name)
  width = is_landscape(source_file) ? 1280 : 720
  encode_video(source_file, dest_file, width)
end
