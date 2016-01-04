#!/bin/bash

encodeVideo () 
{
    # $1 is input file
    # $2 is output file, should end with .m4v
    # $3 is the width of the output
    # https://trac.handbrake.fr/wiki/CLIGuide
    width=$3  #height will be scaled to preserve aspect ratio
    audioBitrate=128 #AAC kbps
    constantQualityRF=28 #https://trac.handbrake.fr/wiki/ConstantQuality  22 looks good for iPhone
    start="started at `date`"
    # advanced options from HandBrake preset
    # x264Advanced="level=4.0:ref=4:bframes=4:b-adapt=2:direct=auto:analyse=all:8x8dct=0:me=umh:merange=24:subme=2:trellis=0:vbv-bufsize=25000:vbv-maxrate=20000:rc-lookahead=10"
    x264Advanced="level=4.0:ref=1:8x8dct=0:weightp=1:subme=2:mixed-refs=0:trellis=0:vbv-bufsize=25000:vbv-maxrate=20000:rc-lookahead=10"
    # rotate, 1 flips on x, 2 flips on y, 3 flips on both (equivalent of 180 degree rotation)
    HandBrakeCLI -i "$1" -o "$2" -e x264 -O -B $audioBitrate -q $constantQualityRF -w $width -x $x264Advanced
    echo $start
    echo "finished at " `date`
}

isLandscape()
{
    #returns true if video is landscape, false if it is portrait
    width=`mdls -name kMDItemPixelWidth "$1" | grep -o '\d\{3,\}'`
    height=`mdls -name kMDItemPixelHeight "$1" | grep -o '\d\{3,\}'`
    #echo "$width x $height"
    #if test $width -gt $height
    if [ $width -gt $height ]
    then
        echo "true"
    fi
}

sourceDir=$1
targetDir="$1/converted"

if [ ! -d "$sourceDir" ]; then
    echo "Invalid source directory"
    exit
fi

mkdir -p $targetDir

#for f in `ls -1 "$sourceDir"`
#for f in $sourceDir
#do
ls $sourceDir | while read -r f; do

    #example filename
    #12,25,14 4'25'35 PM IMG_4419.m4v
    # regex='^[^ ]+ [^ ]+ [^ ]+'
    # datetime=`echo $f | grep -Eo $regex | tr "," "/" | tr "'" ":"`

    # newFileName=`echo $f | sed -E "s/$regex //"`

    # echo "looking at file $f with datetime $datetime"

    #rename the file to drop the ugly timestamp from the filename
    # mv "$sourceDir/$f" "$sourceDir/$newFileName"

    # 405p
    # if [ "`isLandscape "$sourceDir/$f"`" = "true" ]; then
    #    encodeVideo "$sourceDir/$f" "$targetDir/$f" 720
    # else
    #    encodeVideo "$sourceDir/$f" "$targetDir/$f" 405
    # fi

    #detect orientation and encode with proper width
    if [ "`isLandscape "$sourceDir/$f"`" = "true" ]; then
       encodeVideo "$sourceDir/$f" "$targetDir/$f" 1280
    else
       encodeVideo "$sourceDir/$f" "$targetDir/$f" 720
    fi

    # #change the created date on the newly encoded file to match the original
    # SetFile -d "$datetime" "$targetDir/$f"

    # touch -t "$(mediainfo "$f" | grep -m 1 'Tagged date' | sed -r 's/.*([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2}).*/\1\2\3\4\5.\6/')" "$targetDir/$f"

done