+++
title = "Sharing MIDI controllers between Linux machines"
date = 2019-02-25
path = "2019/02/25/sharing-midi-controllers-between-linux-machines"
template = "blog/page.html"
[taxonomies]
tags = []
+++

In the [last post](/2019/02/18/sharing-linux-event-devices-with-other-linux-machines/) - I talked about how one can
share input event devices available as `/dev/input/event*`. Lately, I've been also wanting to share my
MIDI keyboard (Yamaha P-45 Digital Piano) so that I can receive and send MIDI events to my Linux machine
without using a cable.

A problem with MIDI keyboards is that they do not show up as an event device in `/dev/input/`. Instead
on my machine, it is picked up by ALSA and is available via the event file `/dev/snd/midiC1D0`.

This is the kind of output I get when I hit some keys on my MIDI keyboard:
```
$ cat /dev/snd/midiC1D0
2%2242G0H.Q.HGO'M#QOJLMH#JLQ%HQOOTTX*Y/V'YVXS,Q0SQJ0H+G,HJGF7D3DFB=D1DB<5>/?,@+=+?@=><<3;<9<9;<
```

For some reason, the netevent tool also fails to read this file:
```
$ netevent show /dev/snd/midiC1D0
error: failed to query device name: Inappropriate ioctl for device
```

I tried some stuff and there's this one thing that worked - Piping the output of `/dev/snd/midiC1D0` from
the host machine to a virtual MIDI device on the client machine.


### Client Machine (Run the commands on the machine with whom you want to share MIDI controller with)

You'll need to install timidity on client machine which allows us to create virtual MIDI devices.
```
$ sudo apt install timidity
```

The documentation on [https://wiki.archlinux.org/index.php/timidity](https://wiki.archlinux.org/index.php/timidity) is pretty good. I'll repeating the
parts useful to us here:

Now let's try playing some MIDI file to make sure timidity is installed correctly. Download this sample
www.angelfire.com/fl/herky/images/because.mid and call timidity to play it:
```
$ timidity because.mid
```

You should hear the sound from your computer speakers.

Let's create a timidity server:
```
$ timidity -iA
```

The output of the above command should contain the port it is listening on, something like:
```
...
Opening sequencer port: 128:0 128:1 128:2 128:3
...
```

You should now also able to see timidity's software MIDI ports with:
```
$ aconnect -o
client 14: 'Midi Through' [type=kernel]
    0 'Midi Through Port-0'
client 128: 'TiMidity' [type=user,pid=3373]
    0 'TiMidity port 0 '
    1 'TiMidity port 1 '
    2 'TiMidity port 2 '
    3 'TiMidity port 3 '
```

Let's again play the MIDI file to make sure the MIDI ports are listening properly:
```
$ aplaymidi -p 128:0 because.mid
```
You should hear the MIDI play via your computer speakers.

So far, so good.

We'll now create a virtual MIDI device which will allow us to pipe MIDI data from the host machine.

Insert the `snd-virmidi` kernel module:
```
$ sudo modprobe snd-virmidi
```

Use aconnect to verify the virtual MIDI device:
```
$ aconnect -o
client 14: 'Midi Through' [type=kernel]
    0 'Midi Through Port-0'
client 20: 'Virtual Raw MIDI 1-0' [type=kernel,card=1]
    0 'VirMIDI 1-0     '
client 21: 'Virtual Raw MIDI 1-1' [type=kernel,card=1]
    0 'VirMIDI 1-1     '
client 22: 'Virtual Raw MIDI 1-2' [type=kernel,card=1]
    0 'VirMIDI 1-2     '
client 23: 'Virtual Raw MIDI 1-3' [type=kernel,card=1]
    0 'VirMIDI 1-3     '
client 128: 'TiMidity' [type=user,pid=3373]
    0 'TiMidity port 0 '
    1 'TiMidity port 1 '
    2 'TiMidity port 2 '
    3 'TiMidity port 3 '
```
We can see some Virtual Raw MIDI devices indicating things are working properly.

Now, connect timidity's software port with this virtual MIDI device:
```
$ aconnect 20:0 128:0
```

We should now have this virtual device file as `/dev/snd/midiC1D0`.

Let's try piping the MIDI data from the host machine to this client machine.

Make sure you have a MIDI controller attached to the host machine. We'll try to share that MIDI
controller with our client machine.

Run these two commands in separate terminals:
```
# Output data being written to local device file to the host machine
cat /dev/snd/midiC1D0 | ssh user@hostmachine "cat > /dev/snd/midiC1D0"
```
```
# Output data being written to host device file to local machine
ssh user@hostmachine "cat /dev/snd/midiC1D0" > /dev/snd/midiC1D0
```
This way you can both send and receive MIDI events.

Let's test whether this setup works.

Install [linthesia](https://github.com/linthesia/linthesia) (A synthesia-like software for Linux):
```
$ sudo apt install linthesia
```
If it isn't available in your apt repositories, you might have to build it from source.
Their GitHub repo page has instructions on compiling.

Add
```
deb http://cz.archive.ubuntu.com/ubuntu xenial main universe
```
to `/etc/apt/sources.list`.
```
$ sudo apt install libgtkglextmm-x11-1.2-dev
$ sudo apt install libgconfmm-2.6-dev
$ sudo apt install libasound2-dev
$ sudo apt install libsqlite3-dev
```


and play the sample MIDI file with linthesia:
```
$ linthesia because.mid
```

This will open the Linthesia GUI. Select `VirMIDI 1-0` as both Output Device and Input Device and play
the song.

The sound should now be output from your MIDI controller. Also, try hitting some keys on your MIDI
controller and you should see them being represented in gray color on Linthesia. The delay is very
little even when I tested only on WiFi.

