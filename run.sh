#!/bin/bash
set -e

## Environment variables with defaults
EXTENSION=${EXTENSION:-mp4} # REQUIRED; mp4, mov, m4v, etc.
ENCODER=${ENCODER:-libx264} # libx265, libx264, hevc_videotoolbox, etc.
PRESET=${PRESET:-fast} # ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
BITRATE=${BITRATE:-10000k} # 1000-50000k
THREADS=${THREADS:-8} # 1-64
TUNE=${TUNE:-film} # film, animation, grain, stillimage, fastdecode, zerolatency
ANALYZEDURATION=${ANALYZEDURATION:-100000000} # 0-10000000000
PROBESIZE=${PROBESIZE:-100000000} # 0-10000000000
FPS=${FPS:-50} # 24, 25, 30, 50, 60
NAME=${NAME:-50fps} # A name suffix
DELETE_ORIGINAL=${DELETE_ORIGINAL:-false} # Delete original file after processing

# Audio
DISABLE_AUDIO=${DISABLE_AUDIO:-false} # Disable audio
AUDIO_NORMALIZATION=${AUDIO_NORMALIZATION:-loudnorm=I=-23:LRA=7:TP=-2.0} # Audio normalization; EBU R128: loudnorm=I=-23:LRA=7:TP=-2.0
AUDIO_CODEC=${AUDIO_CODEC:-aac} # Audio codec; aac, ac3, flac, opus
AUDIO_BITRATE=${AUDIO_BITRATE:-320k} # Audio bitrate; 64k, 128k, 192k, etc.
AUDIO_SAMPLE_RATE=${AUDIO_SAMPLE_RATE:-48000} # Audio sample rate; 44100, 48000, 96000, etc.

# Custom FFmpeg arguments (optional) - https://ffmpeg.org/ffmpeg.html#Main-options
FFMPEG_ARGS=${FFMPEG_ARGS:-""}


# Directories
WATCH=${WATCH:-./watch} # REQUIRED; Watch directory
STORAGE=${STORAGE:-./storage} # REQUIRED if not using DELETE_ORIGINAL; Storage directory
OUTPUT=${OUTPUT:-./output} # REQUIRED; Output directory
TEMP=${TEMP:-./temp} # Temporary directory

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
    local initial_size
    local final_size
    
    # More robust file completion check
    echo "$(date +"%Y-%m-%d-%T") Checking if $input is completely copied..."
    if [ ! -f "$input" ]; then
        echo "$(date +"%Y-%m-%d-%T") File $input no longer exists. Skipping."
        return 0
    fi
    
    # Try both stat syntaxes with error handling
    initial_size=$(stat -f %z "$input" 2>/dev/null || stat -c %s "$input" 2>/dev/null || echo "error")
    if [ "$initial_size" = "error" ]; then
        echo "$(date +"%Y-%m-%d-%T") ERROR: Could not read file size for $input"
        return 1
    fi
    
    sleep 5  # Wait 5 seconds
    
    if [ ! -f "$input" ]; then
        echo "$(date +"%Y-%m-%d-%T") File $input disappeared during size check. Skipping."
        return 0
    fi
    
    final_size=$(stat -f %z "$input" 2>/dev/null || stat -c %s "$input" 2>/dev/null || echo "error")
    if [ "$final_size" = "error" ]; then
        echo "$(date +"%Y-%m-%d-%T") ERROR: Could not read final file size for $input"
        return 1
    fi

    # Add size comparison check
    if [ "$initial_size" != "$final_size" ]; then
        echo "$(date +"%Y-%m-%d-%T") File $input is still being copied. Skipping."
        return 0
    fi

    local storage="$STORAGE"/"$filepath"
    local temp_output="$TEMP"/"${filepath%.*}"_"${NAME}"_"$(date +%Y%m%d_%H%M%S)"."$EXTENSION"
    local destination="$OUTPUT"/"${filepath%.*}"_"${NAME}"_"$(date +%Y%m%d_%H%M%S)"."$EXTENSION"

    # Move input file to storage without preserving permissions
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
        # Single pass with custom arguments
        if ! ffmpeg \
            -hide_banner \
            -y \
            -loglevel warning \
            -i "$storage" \
            $FFMPEG_ARGS \
            "$temp_output"; then
            echo "$(date +"%Y-%m-%d-%T") ERROR: FFmpeg processing with custom arguments failed. Cleaning up..."
            rm -f "$temp_output" 2>/dev/null
            return 1
        fi
    else
        # Two-pass encoding
        local passlogfile="$TEMP"/"${filepath%.*}"_"${NAME}"_"$(date +%Y%m%d_%H%M%S)_log"

        # First pass
        if ! ffmpeg \
            -hide_banner \
            -y \
            -loglevel warning \
            -i "$storage" \
            -analyzeduration $ANALYZEDURATION \
            -probesize $PROBESIZE \
            -c:v $ENCODER \
            -preset $PRESET \
            -tune $TUNE \
            -b:v $BITRATE \
            -threads $THREADS \
            -pass 1 \
            -passlogfile "$passlogfile" \
            -an \
            -f null /dev/null; then
            echo "$(date +"%Y-%m-%d-%T") ERROR: FFmpeg first pass failed. Cleaning up..."
            rm -f "$temp_output" 2>/dev/null
            rm -f "${passlogfile}"* 2>/dev/null
            return 1
        fi

        # Second pass
        if ! ffmpeg \
            -hide_banner \
            -y \
            -loglevel warning \
            -i "$storage" \
            -analyzeduration $ANALYZEDURATION \
            -probesize $PROBESIZE \
            -c:v $ENCODER \
            -preset $PRESET \
            -tune $TUNE \
            -b:v $BITRATE \
            -threads $THREADS \
            -pass 2 \
            -passlogfile "$passlogfile" \
            -r $FPS \
            $([ "$(echo "$DISABLE_AUDIO" | tr '[:upper:]' '[:lower:]')" = "true" ] && echo "-an" || echo "-c:a $AUDIO_CODEC -b:a $AUDIO_BITRATE -ar $AUDIO_SAMPLE_RATE -af $AUDIO_NORMALIZATION") \
            "$temp_output"; then
            echo "$(date +"%Y-%m-%d-%T") ERROR: FFmpeg second pass failed. Cleaning up..."
            rm -f "$temp_output" 2>/dev/null
            rm -f "${passlogfile}"* 2>/dev/null
            return 1
        fi

        # Cleanup pass log files after successful encoding
        rm -f "${passlogfile}"* 2>/dev/null

        echo "$(date +"%Y-%m-%d-%T") Finished encoding $temp_output"
    fi

    # Move processed file to destination without preserving permissions
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
