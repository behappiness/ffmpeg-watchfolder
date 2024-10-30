FROM lscr.io/linuxserver/ffmpeg:latest
WORKDIR /usr/src/ffmpeg-watch
VOLUME [ "/watch", "/output", "/storage"]
COPY run.sh .
RUN chmod +x run.sh
ENTRYPOINT [ "./run.sh" ]
