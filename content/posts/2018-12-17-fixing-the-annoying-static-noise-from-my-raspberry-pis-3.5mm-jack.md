+++
title = "Fixing the annoying static noise from my Raspberry Pi's 3.5mm jack"
date = 2018-12-17
path = "2018/12/17/fixing-the-annoying-static-noise-from-my-raspberry-pis-3.5mm-jack"
template = "blog/page.html"
[taxonomies]
tags = []
+++

With my now four-year old Pi 2, I've noticed a static spark-like noise coming out from the 3.5mm audio
jack for as far as I can remember. This noise wasn't the kind of usual constant white noise buzzing from
the speakers. Instead, my connected speakers would make a crackle noise at regular intervals and then
remain perfectly noise-less for the remaining period. This periodic noise only appeared when the speakers
were connected to the Pi and didn't happen with any other device.

I read lots of stuff on the internet. Most of which is mentioned in
[here](https://github.com/superjamie/lazyweb/wiki/Raspberry-Pi-3.5mm-Audio-Hiss).
Most people as I've read around were mainly either lucky by setting:
```
audio_pwm_mode=2
```
or
```
disable_audio_dither=1
```
to `/boot/config.txt`. However, I tried these settings in every possible combination but still
didn't seem to fix for me.

Next thing I wondered about my power supply being crappy but nah. Same results with different adapaters,
different cables and different power sources. Failing to discover any possible fix, I gave up and settled
with a USB sound card lying around in my house assuming I might have accidently messed up with the hardware
on the board itself and also many people on the web mentioned that the 3.5mm audio jack is kinda sub-par.

Coming back; Recently, my laptop's audio jack also got ripped off and I decided to rather use the USB sound
card as a workaround which was connected to my Pi than buy a new one as I am usually not listening to music
24/7 in my house with the Pi.

This worked quite well but was a pain to pull off and plugin the sound card every time and I wanted music to
surround me. I started tinkering with my Pi again, going mostly (I don't know why) through the same stuff I
tried in the past (config files, power sources, different speakers, etc.) but to no avail.

I almost gave up yet again. My `/boot/config.txt` became messy and thought about replacing it with the
default settings. So, I backed up my old `/boot/config.txt/` and reverted back to a fresh
configuration and boom; no more static! I hadn't expected this at all. So, adding my old configuration line-by-line
with a consecutive reboot, I was able to pin-point the problem to this line:
```
initial_turbo=30
```
I remember reading it at the time somewhere ([see relevant post](https://www.raspberrypi.org/forums/viewtopic.php?t=112480))
that it increases the CPU frequency during the boot period so that the Pi can complete loading the kernel faster
and then reverts back to the usual frequency depending on the configuration. I probably might've done this when
I was using my Pi for a different purpose in the past and it prolonged there since I didn't saw any obvious drawbacks
of it.

But gotta kick this line off my `config.txt` now! No more static via 3.5mm jack!
