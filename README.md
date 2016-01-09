# Handbrake Batch Video Encoding

This is a Ruby script which converts MOV, MP4, and M4V files (e.g. shot with iOS devices) into smaller files with lower quality and resolution, making them suitable for uploading and archiving personal videos. It is intended for use in OS X and other Unix environments.

Typical 720p video files captured from an iPhone are reduced in file size by 8 times (e.g. 100MB -> 12.5MB) with the default settings (500p).

## Usage

	$ ./encode.rb <source_directory> [target_directory]
	
`target_directory` defaults to a sibling directory of `source_directory` with the "_encoded" suffix. `source_directory` is searched recursively for video files.

## Features

Constants in the script adjust the following features:

* `VIDEO_HEIGHT` - The height in pixels (e.g. 500 (default), 720, 1080).
* `CPU_RATIO` - CPU throttling to reduce overheating on very long encoding processes.
* `FILE_DATE_META` - Sets created and modified dates in the output metadata to match the input.
* `VIDEO_EXTENSIONS` - The file extensions on which to attempt conversion.

## Installation

Dependencies:

* Ruby
* HandBrakeCLI - for encoding the video files
* exiftool - for reading metadata
* cpulimit - for Limiting CPU

### Installing with HomeBrew

	brew install caskroom/cask/brew-cask
	brew cask install handbrakecli
	brew install exiftool
	brew install cpulimit

## License

Released under the MIT License.

This script is adapted from [ThomPatterson/Photos-Video-Archiver](https://github.com/ThomPatterson/Photos-Video-Archiver).
