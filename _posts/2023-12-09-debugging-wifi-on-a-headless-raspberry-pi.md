---
title: "Debugging WiFi on a headless Raspberry Pi"
date: 2023-12-09
layout: post
comments: false
tags:
  - linux
---


### Unsupported WiFi channels

My place gets minor power outages time to time and without having a power backup to rely on, my home router
and machines tend to go off. One peculiar thing I noticed is that about half the times when power did come
back, my Raspberry Pi 4 would fail to connect back to my WiFi router, even when my other machines connected to
WiFi just fine. Also my Pi runs headless with no immediate access to a monitor or an ethernet cable combined
with laziness didn't help debugging in what could've been going wrong.

Initial few times I shrugged it off about WiFi being WiFi, as rebooting my router/Pi would usually bring my Pi
back online. It was annoying nonetheless, say I was outside and wanted to monitor some sensors in my house, a
lil power trip would end up causing problem with this. I tried disabling WiFi power saving settings on my
Pi. There's resources on this issue, such as
[this](https://photobyte.org/raspberry-pi-unreliable-wifi-power-saving/).
The problem still remained but I can't say for sure if it may or may have not have helped with a different
but a related problem.

Giving some thought, I realized I have a USB to TTL
adapter and few jumper cables around which'll allow me to access Pi's serial console through my lappy, all
without having my Pi on network. This seemed like a good enough first step to figure out what could've been
going wrong with my Pi not connecting back to my home WiFi after a power outage.

<p align="center">
  <img src="https://i.imgur.com/l2HYjdi.png" width="200">
  <i>USB to TTL adapter</i>
</p>

There's lots of resources out there on how to set up UART to access the serial console on Pi using USB to TTL.

<!-- -------------------- -->

#### The Culprit

Once I got the above all set up. The next time Pi refused to connect to my home WiFi, I logged into my Pi and
tried doing the usual network checkups.

`ping google.com` fails.

`ifconfig` says no IP assigned to `wlan0`.

Seems Pi isn't connected to WiFi after all.

I tried scanning for WiFi networks around me using:
```
$ sudo nmcli device wifi list --rescan yes
```
I think `nmcli` `nmtui` commands do not work unless you're using `NetworkManager`. So make sure to switch
to `NetworkManager` from `dhcpcd` (which is the default as of writing) using `sudo raspi-config`.

And my home WiFi doesn't show up.

Turned on my phone's WiFi access point mode, rescanned WiFi networks, okay this showed up in nmcli, but for
some reason home WiFi still didn't.

At this point, it almost felt as if my Pi got so tired of always having to connect to my home WiFi that it
evolved in ways to intentionally ignore my home WiFi.

Rebooted my Pi, still seemed mad at WiFi. Again. Still mad.

No nothing. So eventually also brought in my WiFi router into this reboot chaos. 

Eventually eventually after a couple power cycles each, yess it connected happy!

I got suspicious of what radio channel was my home's WiFi access point listening for clients to connect on,
since this seemed a thing that fit into the signs and also that on what WiFi channel a router listens on
usually defaults to automatic. This could mean the channel my router preferred to listen on could change post
every power cycle.

Researching up a bit, it seems I can check out what WiFi channels my Pi 4 supports using:
```bash
$ sudo iwlist wlan0 freq
wlan0     32 channels in total; available frequencies :
          Channel 01 : 2.412 GHz
          Channel 02 : 2.417 GHz
          Channel 03 : 2.422 GHz
          Channel 04 : 2.427 GHz
          Channel 05 : 2.432 GHz
          Channel 06 : 2.437 GHz
          Channel 07 : 2.442 GHz
          Channel 08 : 2.447 GHz
          Channel 09 : 2.452 GHz
          Channel 10 : 2.457 GHz
          Channel 11 : 2.462 GHz
          Channel 36 : 5.18 GHz
          Channel 40 : 5.2 GHz
          Channel 44 : 5.22 GHz
          Channel 48 : 5.24 GHz
          Channel 52 : 5.26 GHz
          Channel 56 : 5.28 GHz
          Channel 60 : 5.3 GHz
          Channel 64 : 5.32 GHz
          Channel 100 : 5.5 GHz
          Channel 104 : 5.52 GHz
          Channel 108 : 5.54 GHz
          Channel 112 : 5.56 GHz
          Channel 116 : 5.58 GHz
          Channel 120 : 5.6 GHz
          Channel 124 : 5.62 GHz
          Channel 128 : 5.64 GHz
          Channel 132 : 5.66 GHz
          Channel 136 : 5.68 GHz
          Channel 140 : 5.7 GHz
          Channel 144 : 5.72 GHz
          Channel 149 : 5.745 GHz
          Current Frequency:5.24 GHz (Channel 48)
```

and comparing these what my router provides:

<p align="center">
  <img src="https://i.imgur.com/tqz4TMn.png" width="500">
  <i>2.4GHz channels</i>
  <br>
  <br>
  <img src="https://i.imgur.com/Gsg2Wty.png" width="500">
  <i>5GHz channels</i>
</p>

It looks there are some channels my router can listen on to but which aren't supported by Pi.

I was able to replicate the problem of Pi not "seeing" my home WiFi after I set my router to listen on a
channel unsupported by my Pi.

I also read around that setting your WLAN country in `sudo raspi-config` should make it so that my Pi
listens only on WiFi channels legalized in my country. This was already set to my country code. I tried
skimming in my router settings to find something similar but no avail here. But it's ok, my router allows
me to bind it to listen on a specific WiFi channel, and anything that the Pi is capable of listening on
should be fine for my case. So I did it. And having me closely keep a track of this for about a week or a two,
didn't notice the problem of my Pi not connecting my WiFi after a power outage cycle happen again.


### Conflicting Docker Interfaces

After I set up some Docker stacks, I noticed a similar problem of my Pi losing WiFi connection would happen
randomly at times. Looking up, it seems Docker is notorious for this problem where it messes with the default
network routes (that provide actual Internet). It seemed the problem went away once I replaced my
`NetworkManager.conf` to ignore virtual network interfaces created by Docker and Tailscale, using the following
contents:

```yaml
# /etc/NetworkManager/NetworkManager.conf

[main]
plugins=ifupdown,keyfile

[ifupdown]
managed=true

[keyfile]
unmanaged-devices=interface-name:docker0;interface-name:veth*;interface-name:br*;interface-name:tailscale0
```

Make sure you're using `NetworkManager` to manager network interfaces (and not `dhcpcd` or anything else)
for this to work.

--------------------

WiFi is still WiFi, so until next time.
