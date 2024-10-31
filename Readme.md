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
- **PRESET**: Encoding speed preset (default: `veryfast`)
  - Options: `ultrafast`, `superfast`, `veryfast`, `faster`, `fast`, `medium`, `slow`, `slower`, `veryslow`
  - Note: Slower presets provide better quality but take longer to encode
- **CRF**: Constant Rate Factor (default: `28`)
  - Range: `0-51`, where lower values mean better quality
- **FPS**: Target frames per second (default: `50`)
  - Common values: `24`, `25`, `30`, `50`, `60`

### Performance Settings

- **THREADS**: Number of CPU threads to use (default: `2`)
  - Range: `1-64`
- **ANALYZEDURATION**: Duration in microseconds FFmpeg spends analyzing input (default: `100000000`)
  - Range: `0-10000000000`
- **PROBESIZE**: Size in bytes of data to analyze for input format detection (default: `100000000`)
  - Range: `0-10000000000`

### Audio Settings

- **AUDIO_NORMALIZATION**: Audio normalization settings (default EBU R128: `loudnorm=I=-23:LRA=7:TP=-2.0`)
- **DISABLE_AUDIO**: Option to disable audio processing (default: `false`)

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
      ENCODER: libx264
      PRESET: veryfast
      CRF: 28
      EXTENSION: mp4
      FPS: 50
      THREADS: 2
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
