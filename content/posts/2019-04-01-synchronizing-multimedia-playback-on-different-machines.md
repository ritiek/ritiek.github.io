+++
title = "Synchronizing multimedia playback on different machines"
date = 2019-04-01
path = "2019/04/01/synchronizing-multimedia-playback-on-different-machines"
template = "page.html"
[taxonomies]
tags = []
+++

I wanted to synchronize audio playback between different machines so I could
hear the same sound from speakers connected to all my machines in the house.
But before trying out external utilites, I decided to give it a try myself. I
primarily use [mpv-player](https://mpv.io/) for everything multimedia. So, naturally I went on to tinker
if I could somehow synchronize playback on different devices with mpv.

I went ahead with my Laptop and Raspberry Pi and saw they have a pretty noticeable difference in startup times of mpv.
I thought if I could synchronize the startup times of mpv between machines, every other piece of the puzzle would
automatically fall into place, since there is probably no computation lag on my machines when decoding an audio
encoding to be played by the speaker in real-time. I synchronized my
device clocks from an external NTP server and launched mpv with the following params:
```
$ mpv https://www.youtube.com/watch?v=ixUWy9qdi08 --input-ipc-server=/tmp/mpvsocket --no-video --pause
```

I imagined this would workaround mpv's startup time, and once both are ready - I would instruct the
[IPC server](https://mpv.io/manual/stable/#json-ipc) to unpause the mpv on both my Laptop and Raspberry Pi at the
same time. Boom! We would now have same audio being given off by both the devices. I installed
[`at`](https://www.linuxjournal.com/content/schedule-one-time-commands-unix-tool) tool which allows you to run a
command at a specific time. I added an entry to unpause mpv at a specific time on both devices. Something like this:
```
$ at 20:28
at> echo '{ "command": ["set_property", "pause", "no"] }' | socat - /tmp/mpvsocket
at> <EOT>
job 1 at Mon Apr  1 20:28:00 2019
```

I tested this but for some reason I would usually end up with reasonable gap between the audio like 1 second or so -
enough for any human ear to detect the out-of-sync audio. I suspect this gap might occur from several reasons, `at`
command only checks at a gap of every second to see if there is any job. Let's say `at` previously checked at 20:27:59
and 900 milliseconds. The next time it checks for a pending job might be on 20:28:00 and 900 milliseconds. We're
already late by 900 milliseconds. I'm not sure whether this is the case but it could take some investigation.
Second reason might probably be because of the small delays that occur on the Raspberry Pi when executing `at` and
writing the data with `socat` to mpv's IPC server. The last one would be as simple as the clocks of the two machines
are not really synchronized in the order of milliseconds. Or a combination of these. Anyway, I couldn't get it to
work reliably with this approach.

So I gave up, and a bit of looking up on the Internet for external utilities. I tried out one such software mentioned -
[Syncplay](https://github.com/Syncplay/syncplay/) which supports multiple players and mpv being one of them. `make`
went without problems. Although, I initially had trouble to get audio-only (since Syncplay is more tailored to video syncing)
output working on my headless Raspberry Pi,
but I found out you could pass additional parameters to the player and disabled the video output (I also created an issue
[#229](https://github.com/Syncplay/syncplay/issues/229)):
```
$ syncplay --no-gui -a syncplay.pl -r randomroom --player-path mpv https://www.youtube.com/watch?v=ixUWy9qdi08 -- --no-video --vo=null
```

On my laptop, I launched the same command without any additional parameters to the player:
```
$ syncplay --no-gui -a syncplay.pl -r randomroom --player-path mpv https://www.youtube.com/watch?v=ixUWy9qdi08
```

This resulted in mpv running in pseudo GUI mode on my laptop and I could control the player with it (seek, un/pause).
Adjusting the playback so would also cause similar changes to the syncplay client instance running on my Pi. It seems
to work pretty well but can sometimes the audio may get out-of-sync. I found that seeking backwards/forwards a bit can
help eliminate out-of-sync issues. Syncplay, however, does not seem whether it is intended for such a purpose (of syncing
audio between machines). Its main purpose (as on their GitHub page) seems to mainly focus on video playing so that viewers
can watch the same thing at the same time, as it states:

> Solution to synchronize video playback across multiple instances of mpv, VLC, MPC-HC, MPC-BE and mplayer2 over the
> Internet.

Like with most command-line software I find cool, I tried to get Syncplay running on my Android with Termux. However, mpv isn't
compiled with Lua support when installed with `pkg` on Termux and I didn't want to go through the trouble of
setting up the toolchain to compile it for Android. Turns out, I just needed to disable loading the Lua script
as in [https://github.com/ritiek/syncplay/tree/mpv-without-lua-support](https://github.com/ritiek/syncplay/tree/mpv-without-lua-support)
and somehow everything turned out to be fine!

Either way, I'll keep Syncplay.

I still haven't dug in the Syncplay codebase deep enough to understand how everything works yet. It might be
a fun thing to do so in my spare time.

I also found out [Snapcast](https://github.com/badaix/snapcast) (especially tailored to sync audio) to work pretty well
might like it even more than Syncplay for audio syncing purposes! Although, I'll still stick to Syncplay for anything video
syncing.
I've done a revised section on syncing audio playback in [this post](/2023/06/11/capturing-and-piping-audio-output-from-a-process-in-linux/).
