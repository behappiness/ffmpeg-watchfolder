# ffmpeg-watch

A Docker container designed to watch a directory and encode any file automatically.

You need to set your watch and output folders either as ENVIRONMENT variables or map volumes in docker-compose:
```docker-compose 
services:
  ffmpeg-watch:
    container_name: ffmpeg-watch
    image: 
    restart: always
    environment:
      ENCODER: libx264
      PRESET: veryfast
      CRF: 28
      EXTENSION: mp4
      FPS: 50
      THREADS: 2
      ANALYZEDURATION: 100000000
      PROBESIZE: 100000000
      AUDIO_NORMALIZATION: "loudnorm=I=-23:LRA=7:TP=-2.0"
      DISABLE_AUDIO: "false"
      PASS: 2
      NAME: "${FPS}fps"
    volumes:
      - 'PATH_TO_WATCH:/watch'
      - 'PATH_TO_OUTPUT:/output'
      - 'PATH_TO_STORAGE:/storage'
      - 'PATH_TO_TEMP:/temp'
```

## Options

|Variables|Default|Description|
|:---|:---|:---|
| WATCH | /watch | Location of files to encode |
| OUTPUT | /output | Where encoded files are saved |
| STORAGE | /storage | Where original files are moved to after processing |
| TEMP | /temp | Temporary directory for processing files |
| EXTENSION | mp4 | Output file extension |
| ENCODER | libx264 | Video encoder to use (see: https://trac.ffmpeg.org/wiki/Encode/H.265) |
| PRESET | veryfast | Encoding preset - slower = better quality (see: https://x265.readthedocs.io/en/default/presets.html) |
| CRF | 28 | Constant Rate Factor (0-51, lower = better quality) |
| FPS | 50 | Target frames per second |
| THREADS | 2 | Number of CPU threads to use |
| ANALYZEDURATION | 100000000 | Duration (in microseconds) that ffmpeg will spend analyzing input |
| PROBESIZE | 100000000 | Size (in bytes) of data to analyze for input format detection |
| AUDIO_NORMALIZATION | loudnorm=I=-23:LRA=7:TP=-2.0 | EBU R128 audio normalization settings |
| DISABLE_AUDIO | false | Disable audio |
| PASS | 2 | Number of encoding passes |
| NAME | {FPS}fps | Output filename suffix |