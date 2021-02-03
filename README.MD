# GStreamer

## installation:

### ubuntu:

```
$ sudo apt-get update --fix-missing
$ sudo apt-get install libgstreamer1.0 libgstreamer1.0-dev gstreamer1.0-plugins-base libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good libgstreamer-plugins-good1.0-dev gstreamer1.0-plugins-bad libgstreamer-plugins-bad1.0-dev gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-nice gstreamer1.0-tools ffmpeg ubuntu-restricted-extras v4l-utils
```

### window:

follow installation guide on GStreamer Website: [here](https://gstreamer.freedesktop.org/documentation/installing/on-windows.html?gi-language=c)

### dockerfile:
```
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
```

To use the dockerfile, save the content as a `Dockerfile` is a directory of your choosing, and run:
```
$ docker build -t "gst" .
$ xhost +
$ docker run --rm -it --network="host" -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY gst
```
this will allow display passthrough from the docker to the host environment (this assumes you are running on ubuntu).

# fundamentals

## first pipeline:

```
$ gst-launch-1.0 videotestsrc ! autovideosink
```

This command links two gstreamer elements: `videotestsrc` and `autovideosink`.

`videotestsrc` provides raw video in realtime, and `autovideosink` displays the video on the screen.

## attributes:

each element can has readable/writable attributes, attributes can be added an element like this:

```
$ gst-launch-1.0 videotestsrc num-buffers=100 ! autovideosink
```

Now instead or running till infinity, `videotestsrc` will provide 100 buffer, after which it will send **EOS** signaling the end of the pipeline.

To view possible attributes of an element, you can use the following:

```
$ gst-inspect-1.0 videotestsrc
```

or visit the online documentation on the GStreamer website.

## linking

The linking is done using the `!` character, but linking is not done directly on elements:

The `!` character connected videotestsrc's src pad to autovideosink's sinkpad, this was possible because there was no ambiguity as to which pad to connect where.

If we'd like to be more descriptive, we due the same pipeline as such:

```
$ gst-launch-1.0 videotestsrc .src ! .sink autovideosink
```

Or we can provide a name attribute to each element and do as such:

```
$ gst-launch-1.0 videotestsrc name=a a.src ! b.sink autovideosink name=b
```

### capabilities

Another issue regarding linking is **capabilities** - **CAPS**:  
CAPS provide information about the data being sent or received, an example for that could be the resolution of a video, allowing a videosink to decide on a window size.

Capabilities are often decided automatically, but in cases where the caps is ambiguous, you can use a fundamental plugin called `capsfilter`, with caps written inside the `caps` attribute as a caps string.

For example:

```
$ gst-launch-1.0 videotestsrc ! capsfilter caps="video/x-raw, width=1920, height=1080" ! autovideosink
```

`capsfilter` is a special plugin, and one of the only plugins to be abbreviated. The same pipeline can be written as such:

```
$ gst-launch-1.0 videotestsrc ! "video/x-raw, width=1920, height=1080" ! autovideosink
```

Or even without the quotations `"`

```
$ gst-launch-1.0 videotestsrc ! video/x-raw, width=1920, height=1080 ! autovideosink
```

## multiple pathways:

Using a fundamental plugin called `tee`, (like a `T` junction) an output of a plugin can be sent to multiple receivers.

An example:

```
$ gst-launch-1.0 videotestsrc ! tee name=t ! queue ! autovideosink t. ! queue ! fakesink dump=true
```

### overview:

```
                            /-> queue   ->  autovideosink
videotestsrc    ->  tee  -<
                            \-> queue   ->  fakesink
```

This pipeline splits `videotestsrc`'s output to both `autovideosink` and `fakesink`.

`fakesink` has a `dump=true` attribute, which means every buffer will be displayed to STDOUT, much like a hex dump.

Each output of the tee is connected to a `queue` element. the `queue` element creates a new thread the tee's sinkpad, this is to allow both outputs to operate at the same time, without overtaking resources.

If you notice, without providing a name, linking the `tee` element with `fakesink`'s queue, would have been impossible without providing a name field. (using the command-line-interface that is).

# play file:

## completely abstracted:

```
$ gst-launch-1.0 playbin uri=file://`pwd`/Big_Buck_Bunny_360_10s_5MB.mp4
```

This command constructs a file protocol uri, like this: `file:///home/user/Big_Buck_Bunny_360_10s_5MB.mp4`, and lets the `playbin` plugin decide how to play the pipeline.

Similar to `ffplay Big_Buck_Bunny_360_10s_5MB.mp4`

## slightly less abstracted:

```
$ gst-launch-1.0 filesrc location=Big_Buck_Bunny_360_10s_5MB.mp4 ! decodebin ! autovideosink
```

In this command we let `decodebin` plugin decide how to open the file and with which decoder to do the decoding, main difference between this command and the previous command is this one is deciding the video sink manually - using the `playbin` plugin.

In fact `playbin` is an abstraction as-well, which will replace the contents based on the underlying os, for linux this will most likely be `xvimagesink`, but thats as deep as we'll go for now.

## actual pipeline:

```
$ gst-launch-1.0 filesrc location=Big_Buck_Bunny_360_10s_5MB.mp4 ! qtdemux ! h264parse ! avdec_h264 ! autovideosink
```

In this command we're providing most (if not all) the major component used to play the video, without relying on `bins` to do the work for us.

for other file types you can use different demux plugins.  
for mkv and webm file use: **matroskademux**

# sending as rtp:

This commands sends the rtp packets to a multicast address, for any client in the local network to utilize.

```
$ gst-launch-1.0 filesrc location=Big_Buck_Bunny_360_10s_5MB.mp4 ! qtdemux ! h264parse ! rtph264pay config-interval=-1 ! udpsink host="239.3.0.1" port=6001
```

The reason for using rtp is two fold:

-  splits the h264 stream into sizeable chunks to be sent on the network
-  provides time-stamping and error detection.

To demonstrate, if we were to try sending the h264 stream as-is, like so:

```
$ gst-launch-1.0 filesrc location=Big_Buck_Bunny_360_10s_5MB.mp4 ! qtdemux ! h264parse ! udpsink host="239.3.0.1" port=6001
```

we will receive warnings like so:

`WARNING: from element /GstPipeline:pipeline0/GstUDPSink:udpsink0: Attempting to send a UDP packets larger than maximum size (68769 > 65507)`

# playing the rtp stream

```
$ gst-launch-1.0 udpsrc address="239.3.0.1" port=6001 ! "application/x-rtp" ! rtph264depay ! h264parse ! avdec_h264 ! autovideosink
```

This command will receive the rtp packets and display then in the same manner as previously seen. But if you notice the pipeline _screams_ at us `"Not enough buffering available for the processing deadline"`

This is due to the way rtp behaves - packets wrapped in rtp are not mandated to be complete frames, and if a complete frame is not present, the packet will be dropped.

To combat this we can use the `rtpjitterbuffer` plugin as follows:

```
$ gst-launch-1.0 udpsrc address="239.3.0.1" port=6001 ! "application/x-rtp" ! rtpjitterbuffer ! rtph264depay ! h264parse ! avdec_h264 ! autovideosink
```

# playing camera

This pipeline uses v4l - Video 4 Linux, as such is available on linux devices only only

```
$ gst-launch-1.0 v4l2src ! autovideosink
```
device can be selected using the `"device"` attribute:

```
$ gst-launch-1.0 v4l2src device=/dev/video0 ! autovideosink
```
```
```