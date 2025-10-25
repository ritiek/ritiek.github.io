+++
title = "Capturing and piping audio output from a process in Linux"
date = 2023-06-12
path = "2023/06/12/capturing-and-piping-audio-output-from-a-process-in-linux"
template = "page.html"
[taxonomies]
tags = []
+++

I've been looking to intercept audio data from specific processes so I can tinker with this audio
data in real time. Vaguely `capture` audio output from a process, tinker with it, and `play`
this tinkered audio through my hardware, something similar to this pseudocode:
```bash
# Resample music from my Spotify desktop app to a higher sample rate (nightcore) in near real-time.
$ capture --sample-rate 48000 spotify | play --buffer-time-in-secs 5 --sample-rate 52000 -
```
I think I got something pretty close to this figured here.

A little while ago, I moved to [PipeWire](https://pipewire.org/) from [PulseAudio](https://www.freedesktop.org/wiki/Software/PulseAudio/).
The stuff below will only work if you're using PipeWire yourself. It might also be possible to
adjust this to work with PulseAudio but it isn't something I'm looking to explore at the moment.


## Setup

The plan is to create a new virtual audio output device. We'll be redirecting the audio
output from our target process to this virtual audio output device, so that we're able to isolate
this process's audio output from all other processes. We'll then capture all audio data being
sent to this virtual output device. Once captured, we can tinker with the audio data and then
redirect this tinkered audio output to our actual audio output device(s).

We'll begin by inserting a kernel module to create a virtual audio loopback device:
```bash
$ sudo modprobe snd-aloop
```

We should now see two new virtual audio devices: `Analog Output` and `Analog Input`.
<p align="center">
  <img src="/assets/ByNqPIR.png">
  <i>Audio Devices</i>
</p>


Launch some application, say Spotify desktop, put some music on, and have Spotify send the audio data
to this new virtual audio output `Analog Output`.
In Manjaro, I got it working as in the screenshot below, but it should be similar
on other distros (try looking for it under Settings -> Audio), or install and use `pavucontrol` gui.

Haven't looked around for a CLI alternative for this purpose yet.
<p align="center">
  <img src="/assets/jbgu6C2.png">
  <i>Switching playback device to virtual output device</i>
</p>

Once you switch the audio output device for Spotify to the dummy output device, you'll no longer
hear your music from your actual speakers.

Now let's see the node names given by PipeWire to our currently existing audio devices.
```bash
$ pw-cli list-objects | grep node.name
node.name = "Dummy-Driver"
node.name = "Freewheel-Driver"
node.name = "Midi-Bridge"
node.name = "v4l2_input.pci-0000_00_14.0-usb-0_5_1.0"
node.name = "v4l2_input.pci-0000_00_14.0-usb-0_5_1.2"
node.name = "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp_5__sink"
node.name = "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp_4__sink"
node.name = "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp_3__sink"
node.name = "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp__sink"
node.name = "alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp__source"
node.name = "alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp_6__source"
node.name = "plasmashell"
node.name = "alsa_playback.aplay"
node.name = "alsa_input.platform-snd_aloop.0.analog-stereo"
node.name = "alsa_output.platform-snd_aloop.0.analog-stereo"
node.name = "spotify"
...
```
(`pw-*` commands are only available with PipeWire)

After some speculation, I figured out my dummy audio output device is called `alsa_output.platform-snd_aloop.0.analog-stereo`
and my actual audio output device is called `alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp__sink`.

Confirm yours by running any of the following commands (added all that I figured out in the moment
here for documenting purpose) to redirect audio from your dummy audio output device to your actual
audio output device. Make sure to replace the `--target` param with the node names that seemingly
fit for your case.

```bash
$ pw-record --target alsa_output.platform-snd_aloop.0.analog-stereo - | pw-play --target alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp__sink -
```
(You may have to also pass in `-P stream.capture.sink=true` to `pw-record`, thanks @pkgmvd as reported on 23rd November, 2024!)
```bash
$ pw-loopback -C alsa_output.platform-snd_aloop.0.analog-stereo -P alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp__sink
```
```bash
$ pw-link alsa_output.platform-snd_aloop.0.analog-stereo alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp__sink
$ pw-link --disconnect alsa_output.platform-snd_aloop.0.analog-stereo alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp__sink
```

You should be able to hear your Spotify music if both the dummy audio output device and the
actual audio output device you selected are the right ones.

Wohoo! We can now mess with this audio. As an example, we'll attempt to increase sample rate for
whatever's playing in Spotify to make it sound nightcorish:

```bash
$ pw-record --target alsa_output.platform-snd_aloop.0.analog-stereo - | aplay -B 5000000 -r 52000 -f S16_LE -c 2 -
```

At the time of writing, `pw-record` captures audio at a sample rate of 44.8KHz. In the above example
we resampled it to 52KHz (`-r 52000`). Since we'll be playing audio at a higher sample rate than what we'll be
receiving from `pw-record`, our dummy audio output will have to play catch up with our actual audio
output. This means our actual audio output will stutter every now and then.

As a little workaround, we passed `-B 5000000` to let Spotify fill up the audio buffer for 5s everytime
it starts to play catch up after which `aplay` would attempt to begin resampling.

We can also do multiple pipes for a bit more complexy stuff:
```
$ pw-record --target alsa_output.platform-snd_aloop.0.analog-stereo - | ffmpeg -ar 48000 -f s16le -ac 2 -i - -filter:a "asetrate=48000*1.1" -f wav - | mpv --audio-buffer=5 -
```

----------------------------------------

## Synchronizing audio output from a process to multiple machines

A few years ago, I wrote a [post on synchronizing multimedia plaback (and Syncplay)](/2019/04/01/synchronizing-multimedia-playback-on-different-machines/).
Quite a while after writing it, I discovered [Snapcast](https://github.com/badaix/snapcast) which is
more tailored to audio syncing and seems to work better than [Syncplay](https://github.com/Syncplay/syncplay) in that regard.
(although, I'll still stick to Syncplay for video syncing stuff)

Install Snapcast and edit `/etc/snapserver.conf` to have your `source` line as:
```
source = pipe:///tmp/snapfifo?name=default
```

Launch the Snapcast server:
```bash
$ snapserver
```

In another terminal, we'll write the audio output from the dummy audio output device to this named pipe
which'll be used by snapcast server to broadcast audio to connected clients:
```
$ pw-record --target alsa_output.platform-snd_aloop.0.analog-stereo - > /tmp/snapfifo
```
Have some application writing audio output to this dummy audio output device (Spotify as we talked about
in the previous section, anything else works fine too).

Snapcast server by default also provides a little built-in client running on [http://0.0.0.0:1780](http://0.0.0.0:1780), you
can open this in a browser (which'll be writing audio output to our actual audio output device) and tap
the play button. If you're able to hear music now, then we're good to go!

Snapcast client app is also available for Android and iOS. We can have our phones be a part of this syncy
mesh too.
