#!/bin/bash
set -e

## Environment variables with defaults
EXTENSION=${EXTENSION:-mp4} # REQUIRED; mp4, mov, m4v, etc.
ENCODER=${ENCODER:-libx264} # libx265, libx264, hevc_videotoolbox, etc.
PRESET=${PRESET:-veryfast} # ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
CRF=${CRF:-28} # 0-51
THREADS=${THREADS:-2} # 1-64
ANALYZEDURATION=${ANALYZEDURATION:-100000000} # 0-10000000000
PROBESIZE=${PROBESIZE:-100000000} # 0-10000000000
FPS=${FPS:-50} # 24, 25, 30, 50, 60
NAME=${NAME:-${FPS}fps} # A name suffix
AUDIO_NORMALIZATION=${AUDIO_NORMALIZATION:-loudnorm=I=-23:LRA=7:TP=-2.0} # Audio normalization; EBU R128: loudnorm=I=-23:LRA=7:TP=-2.0
DISABLE_AUDIO=${DISABLE_AUDIO:-true} # Disable audio
DELETE_ORIGINAL=${DELETE_ORIGINAL:-false} # Delete original file after processing
# Custom FFmpeg arguments (optional) - https://ffmpeg.org/ffmpeg.html#Main-options
FFMPEG_ARGS=${FFMPEG_ARGS:-""}


# Directories
WATCH=${WATCH:-/watch} # REQUIRED; Watch directory
STORAGE=${STORAGE:-/storage} # REQUIRED if not using DELETE_ORIGINAL; Storage directory
OUTPUT=${OUTPUT:-/output} # REQUIRED; Output directory
TEMP=${TEMP:-/temp} # Temporary directory

# Check if a directory exists and is writable
check_directory() {
    local dir=$1
    if [[ ! -d "$dir" ]]; then
        echo "$(date +"%Y-%m-%d-%T") ERROR: Directory $dir does not exist"
        return 1
    elif [[ ! -w "$dir" ]]; then
        echo "$(date +"%Y-%m-%d-%T") ERROR: Directory $dir is not writable"
        return 1
    fi
    return 0
}

run() {
    # Initial directory checks
    for dir in "$WATCH" "$STORAGE" "$OUTPUT" "$TEMP"; do
        if ! check_directory "$dir"; then
            echo "$(date +"%Y-%m-%d-%T") FATAL: Required directory check failed"
            exit 1
        fi
    done

    while true; do
        cd "$WATCH" || exit
        FILES=$(find . -maxdepth 1 -type f -not -path '*/\.*' | egrep '.*' || true)
        cd ..
        if [ -n "$FILES" ]; then
            echo "$FILES" | while read -r FILE
            do
                process "$FILE"
            done
        else
            echo "$(date +"%Y-%m-%d-%T") No files to process, waiting..."
            sleep 10
        fi
    done
}

process() {
    local file=$1
    local filepath=${file:2}
    local input="$WATCH"/"$filepath"
    
    # Add file completion check
    echo "$(date +"%Y-%m-%d-%T") Checking if $input is completely copied..."
    local initial_size=$(stat -f %z "$input" 2>/dev/null || stat -c %s "$input")
    sleep 5  # Wait 5 seconds
    local final_size=$(stat -f %z "$input" 2>/dev/null || stat -c %s "$input")
    
    if [ "$initial_size" != "$final_size" ]; then
        echo "$(date +"%Y-%m-%d-%T") File $input is still being copied. Skipping for now."
        return 0  # Return 0 to allow the file to be processed in the next iteration
    fi

    local storage="$STORAGE"/"$filepath"
    local temp_output="$TEMP"/"${filepath%.*}"_"${NAME}"_"$(date +%Y%m%d_%H%M%S)"."$EXTENSION"
    local destination="$OUTPUT"/"${filepath%.*}"_"${NAME}"_"$(date +%Y%m%d_%H%M%S)"."$EXTENSION"

    # Move input file to storage (simplified)
    echo "$(date +"%Y-%m-%d-%T") Moving $input to $storage"
    if ! mv "$input" "$storage"; then
        echo "$(date +"%Y-%m-%d-%T") ERROR: Failed to move input file to storage. Skipping processing."
        return 1
    fi

    echo "$(date +"%Y-%m-%d-%T") Processing $storage -> $temp_output"

    # Set up trap for cleanup on interrupt
    trap 'echo "Interrupted, cleaning up..."; rm -f "$temp_output" 2>/dev/null; exit' INT

    # Run ffmpeg with error handling
    if [ -n "$FFMPEG_ARGS" ]; then
        if ! ffmpeg \
            -hide_banner \
            -y \
            -loglevel warning \
            -i "$storage" \
            $FFMPEG_ARGS \
            "$temp_output"; then
            echo "$(date +"%Y-%m-%d-%T") ERROR: FFmpeg processing failed. Cleaning up..."
            rm -f "$temp_output" 2>/dev/null
            return 1
        fi
    else
        if ! ffmpeg \
            -hide_banner \
            -y \
            -loglevel warning \
            -i "$storage" \
            -analyzeduration $ANALYZEDURATION \
            -probesize $PROBESIZE \
            -c:v $ENCODER \
            -preset $PRESET \
            -crf $CRF \
            -threads $THREADS \
            -r $FPS \
            $([ "$(echo "$DISABLE_AUDIO" | tr '[:upper:]' '[:lower:]')" = "true" ] && echo "-an" || echo "-af $AUDIO_NORMALIZATION") \
            "$temp_output"; then
            echo "$(date +"%Y-%m-%d-%T") ERROR: FFmpeg processing failed. Cleaning up..."
            rm -f "$temp_output" 2>/dev/null
            return 1
        fi
    fi

    echo "$(date +"%Y-%m-%d-%T") Finished encoding $temp_output"

    # Move processed file to destination
    echo "$(date +"%Y-%m-%d-%T") Moving $temp_output to $destination"
    if ! mv "$temp_output" "$destination"; then
        echo "$(date +"%Y-%m-%d-%T") ERROR: Failed to move processed file to destination. Cleaning up..."
        rm -f "$temp_output" 2>/dev/null
        return 1
    fi

    # Delete original file if DELETE_ORIGINAL is true
    if [ "$(echo "$DELETE_ORIGINAL" | tr '[:upper:]' '[:lower:]')" = "true" ]; then
        echo "$(date +"%Y-%m-%d-%T") Deleting original file: $storage"
        if ! rm "$storage"; then
            echo "$(date +"%Y-%m-%d-%T") WARNING: Failed to delete original file: $storage"
        fi
    fi
}

# Start the main process
run
