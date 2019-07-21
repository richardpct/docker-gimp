FROM ubuntu:latest
LABEL maintainer="richardpct"

RUN apt-get update && apt-get install -y --no-install-recommends \
    gimp && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /root/Share

VOLUME /root/Share

CMD ["/usr/bin/gimp"]
