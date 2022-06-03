#!/bin/bash
#set -o xtrace

unset FILEPATH
RESOLUTION=1
VIDEO_LENGTH=1
unset DESIRED_RESOLUTION
DESIRED_SIZE=8
unset OUTPUT_FILEPATH
SPEED=1

function usage() {
    echo "Usage: $0 [ -i PATH_TO_INPUT_FILE ] [ -u DESIRED_RESOLUTION ] [ -s DESIRED_SIZE (default 8) ] [ -o OUTPUT_FILEPATH ]" 1>&2 
}

function exit_abnormal() {
    usage
    exit 1
}

function exit_interrupted() {
    trap SIGINT
    echo "Interrupted"
    exit 1
}

function getVideoHeight() {
    local height
    height="$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=s=x:p=0 "$FILEPATH")"
    if [[ $height =~ ^[0-9]+$ ]]; then
        echo "$height"
        return 0
    else
        exit_abnormal
    fi
}

function getVideoLength () {
    local length
    length="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$FILEPATH")"
    echo "${length%.*}"
}


function calculateBitrate() {
    local bitrate
    bitrate=$((DESIRED_SIZE*8192/VIDEO_LENGTH))
    echo "${bitrate}"
    return 0
}

function main() {
    trap "exit_interrupted" INT
    while getopts ':i:u:s:o:' options; do
        case "$options" in
            i)
                FILEPATH=$OPTARG
                if [[ ! -f "$FILEPATH" ]]; then
                    echo "Not a valid filepath"
                    exit_abnormal
                fi
                ;;
            u)
                DESIRED_RESOLUTION=$OPTARG
                if [[ $DESIRED_RESOLUTION -le 0 ]]; then
                    echo "Desired resolution has to be greater than 0"
                    exit_abnormal
                fi
                ;;
            s)
                DESIRED_SIZE=$OPTARG
                if [[ -z "$DESIRED_SIZE" ]]; then
                    exit_abnormal
                fi
                
                if [[ $(echo "$DESIRED_SIZE <= 0" |bc -l) == 1 ]]; then
                    echo "Desired size has to be greater than 0"
                    exit_abnormal
                fi
                ;;
            o)
                OUTPUT_FILEPATH=$OPTARG
                ;;
            :)
                echo "Error: -${OPTARG} requires an argument."
                exit_abnormal
                ;;
            *)
                exit_abnormal
                ;;
        esac
    done

    shift "$(( OPTIND - 1 ))"

    if [[ -z "$FILEPATH" ]]; then
        echo "Please provide a filepath"
        exit_abnormal
    fi

    if [[ -z "$OUTPUT_FILEPATH" ]]; then
        OUTPUT_FILEPATH="out.webm"
    fi

    if [ -f "$OUTPUT_FILEPATH" ]; then
        echo "File \"$OUTPUT_FILEPATH\" already exists"
        exit_abnormal
    fi

    RESOLUTION=$(getVideoHeight)
    VIDEO_LENGTH=$(getVideoLength)
    OVERALL_BITRATE=$(calculateBitrate)
    AUDIO_BITRATE=64
    VIDEO_BITRATE=$((OVERALL_BITRATE-AUDIO_BITRATE))

    if [[ -z $DESIRED_RESOLUTION ]]; then
        DESIRED_RESOLUTION=$RESOLUTION
    fi

    if [[ DESIRED_RESOLUTION -ge 720 ]]; then
        SPEED=2
    fi

    ffmpeg -i "$FILEPATH" -c:v libvpx-vp9 -b:v $VIDEO_BITRATE"k" -vf scale=-1:"$DESIRED_RESOLUTION" -pix_fmt yuv420p10le -quality good -threads 4 -profile:v 2 -lag-in-frames 25 -cpu-used 4 -auto-alt-ref 1 -arnr-maxframes 7 -arnr-strength 4 -aq-mode 0 -tile-rows 0 -tile-columns 1 -enable-tpl 1 -row-mt 1 -speed 4 -pass 1 -an -f null /dev/null
    trap SIGINT
    ffmpeg -i "$FILEPATH" -c:v libvpx-vp9 -b:v $VIDEO_BITRATE"k" -vf scale=-1:"$DESIRED_RESOLUTION" -pix_fmt yuv420p10le -quality good -threads 4 -profile:v 2 -lag-in-frames 25 -cpu-used 4 -auto-alt-ref 1 -arnr-maxframes 7 -arnr-strength 4 -aq-mode 0 -tile-rows 0 -tile-columns 1 -enable-tpl 1 -row-mt 1  -speed $SPEED -c:a libopus -b:a $AUDIO_BITRATE"k" -pass 2 -f webm "$OUTPUT_FILEPATH"
    trap SIGINT
    rm ffmpeg2pass-0.log
    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
