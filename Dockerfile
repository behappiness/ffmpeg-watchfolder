FROM lscr.io/linuxserver/ffmpeg:latest
WORKDIR /usr/src/ffmpeg-watch
VOLUME [ "/watch", "/output", "/storage", "/temp" ]
COPY run.sh .
RUN chmod +x run.sh
ENTRYPOINT [ "./run.sh" ]
