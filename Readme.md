# ffmpeg-watch

## Overview

A Docker container designed to watch a directory and automatically encode video files using FFmpeg. The container monitors a specified directory for new files and processes them according to your configuration.

### Core Directories

- **WATCH**: Directory to monitor for new files (`/watch`)
- **OUTPUT**: Directory where encoded files are saved (`/output`)
- **STORAGE**: Directory where original files are moved after processing (`/storage`)
- **TEMP**: Temporary directory for processing files (`/temp`)

### Video Encoding Settings

- **EXTENSION**: Output file extension (default: `mp4`)
- **ENCODER**: Video encoder to use (default: `libx264`)
  - Options include: `libx265`, `hevc_videotoolbox`, etc.
- **PRESET**: Encoding speed preset (default: `fast`)
  - Options: `ultrafast`, `superfast`, `veryfast`, `faster`, `fast`, `medium`, `slow`, `slower`, `veryslow`
- **BITRATE**: Video bitrate (default: `10000k`)
- **THREADS**: Number of CPU threads to use (default: `8`)
- **TUNE**: Encoder tuning (default: `film`)
  - Options: `film`, `animation`, `grain`, `stillimage`, `fastdecode`, `zerolatency`
- **ANALYZEDURATION**: Duration in microseconds FFmpeg spends analyzing input (default: `100000000`)
- **PROBESIZE**: Size in bytes of data to analyze for input format detection (default: `100000000`)
- **FPS**: Target frames per second (default: `50`)
  - Options: `24`, `25`, `30`, `50`, `60`, `30/1001`

### Audio Settings

- **AUDIO_NORMALIZATION**: Audio normalization settings (default EBU R128: `loudnorm=I=-23:LRA=7:TP=-2.0`)
- **DISABLE_AUDIO**: Option to disable audio processing (default: `false`)
- **AUDIO_CODEC**: Audio codec (default: `aac`)
- **AUDIO_BITRATE**: Audio bitrate (default: `320k`)
- **AUDIO_SAMPLE_RATE**: Audio sample rate (default: `48000`)

### Output Settings

- **NAME**: Output filename suffix (default: `50fps`)
- **DELETE_ORIGINAL**: Option to delete original file after processing (default: `false`)

### Advanced Configuration

- **FFMPEG_ARGS**: Optional custom FFmpeg arguments
  - Allows passing custom FFmpeg parameters
  - Reference: [FFmpeg Main Options](https://ffmpeg.org/ffmpeg.html#Main-options)

### Docker Configuration

You can set these options either through environment variables or in your `docker-compose.yml` file. Here's an example configuration:

```yaml
services:
  ffmpeg-watch:
    container_name: ffmpeg-watch
    image: ghcr.io/behappiness/ffmpeg-watchfolder:latest
    restart: always
    environment:
      FPS: 50
      THREADS: 8
      DISABLE_AUDIO: "false"
      NAME: "50fps"
      DELETE_ORIGINAL: "false"
    volumes:
      - 'PATH_TO_WATCH:/watch'
      - 'PATH_TO_OUTPUT:/output'
      - 'PATH_TO_STORAGE:/storage'
      - 'PATH_TO_TEMP:/temp'
```

Replace `PATH_TO_*` with your actual directory paths.
