FROM ubuntu:rolling
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update --fix-missing
RUN apt-get install -y libgstreamer1.0
RUN apt-get install -y libgstreamer1.0-dev
RUN apt-get install -y gstreamer1.0-plugins-base
RUN apt-get install -y libgstreamer-plugins-base1.0-dev
RUN apt-get install -y gstreamer1.0-plugins-good
RUN apt-get install -y libgstreamer-plugins-good1.0-dev
RUN apt-get install -y gstreamer1.0-plugins-bad
RUN apt-get install -y libgstreamer-plugins-bad1.0-dev
RUN apt-get install -y gstreamer1.0-plugins-ugly
RUN apt-get install -y gstreamer1.0-libav
RUN apt-get install -y gstreamer1.0-nice
RUN apt-get install -y gstreamer1.0-tools
RUN apt-get install -y ffmpeg
RUN apt-get install -y ubuntu-restricted-extras
RUN apt-get install -y v4l-utils
RUN apt-get install -y net-tools
RUN mkdir /app
WORKDIR /app
ENTRYPOINT [ "/bin/bash" ]