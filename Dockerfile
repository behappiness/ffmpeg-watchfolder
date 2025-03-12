FROM lscr.io/linuxserver/ffmpeg:7.1.1
WORKDIR /usr/src/ffmpeg-watch
VOLUME [ "/watch", "/output", "/storage", "/temp" ]
COPY run.sh .
RUN chmod +x run.sh
ENTRYPOINT [ "./run.sh" ]
