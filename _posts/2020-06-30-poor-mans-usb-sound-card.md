---
title: "Poor man's USB sound card"
date: 2020-06-30
layout: post
comments: false
tags:
  - linux
  - android
  - sound
---

Consider a situation where a Linux desktop is missing or has a broken 3.5mm audio jack. Yet you need to somehow
connect an external audio output device to the 3.5mm jack. If you have an Android phone with 3.5mm jack intact,
there is a way to stream audio from your Linux desktop to the 3.5mm audio jack on the Android phone. If you don't
mind the 0.2s audio delay, follow the steps:

1. Setup pulseaudio on Linux desktop to [stream audio to a TCP port](https://superuser.com/a/750324/693992) on
   0.0.0.0. Just in case this linked answer goes down, you basically need to load the pulseaudio tcp module:
   ```
   $ pactl load-module module-simple-protocol-tcp rate=48000 format=s16le channels=2 source=<source_name_here> record=true port=8000
   ```

2. Install [Simple Protocol Player](https://play.google.com/store/apps/details?id=com.kaytat.simpleprotocolplayer)
   on to your Android phone.

3. Connect your Android phone to your Linux desktop with a USB cable and turn on USB tethering, so the phone
   and Linux desktop are on the same network and therefore can communicate via TCP (being on the same WiFi network
   works too but audio lag was too much for my case).

4. Note your IP address for this newly available USB ethernet adapter on your Linux desktop with `ifconfig`, and
   enter it in the Simple Protocol Player app on your Android with the port `8000` which was mentioned
   when we loaded the pulseaudio tcp module.

That should be it. You should now be able to stream audio from the Linux desktop to your Android phone in
near-real-time.

If you noticed, this method didn't require authentication. So when you're done, unload the pulseaudio tcp module
on the Linux machine so strangers won't connect:
```
$ pactl unload-module `pactl list | grep tcp -B1 | grep M | sed 's/[^0-9]//g'`
```
