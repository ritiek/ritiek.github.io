+++
title = "I got myself an Xteink X3 e-reader"
date = 2026-06-10
path = "2026/06/10/i-got-myself-an-xteink-x3-e-reader"
template = "blog/page.html"
[taxonomies]
tags = []
+++

My Kindle Paperwhite 3 is now more than a decade old. I remember jailbreaking it not long after I got it
to see what else I could do outside the corpo wall. It runs a Linux-based OS, and we can add custom
screensavers, run an SSH server, use KOReader, or use the [display as a wireless mouse](/2019/02/18/sharing-linux-event-devices-with-other-linux-machines/), among other things. Besides the obvious used look now,
it still works surprisingly well.

Unfortunately, I've had a difficult time fitting the Kindle into my routine to read more books or anything
that requires sustained attention. It doesn't feel like a very portable device, and it makes me prefer reading on my phone over carrying a special device that takes twice the space of my phone. Lately,
I've found myself doom-scrolling or just finding ways to kill time on my phone when I'm not in a physical
or mental place to be productive, and the stimulation really does make me feel like a mindless being.
I've been looking for replacements or excuses to nope out of that urge, and I've lately
seen Xteink gaining popularity. Their devices seem to somewhat adhere to open software standards, which
helps with fun tinkering. They also seem small enough to be pocketable and perhaps help me get some reading done, unlike with my Kindle.

I got myself the Xteink X3 from the official website ([https://www.xteink.com/](https://www.xteink.com/)).
They ship from China, and it took around a week for it to reach me here in India. I've read about some people
preferring the X4 (which is the older variant) over the X3 due to the X3 removing the USB-C charging port
and using an obscure charging port instead. This wasn't a problem for me since my SenseCAP Card Tracker
T1000-E flashed with Meshtastic uses a similar charging port, and the data/charging cables I received with the T1000-E and X3 have been cross-compatible.

<p align="center">
  <img src="/assets/IMG_20260531_211556.jpg" width="700">
  <i>T1000-E and Xteink X3 Front Side</i>
</p>

<p align="center">
  <img src="/assets/IMG_20260531_211257.jpg" width="700">
  <i>T1000-E and Xteink X3 Back Side (charging wire and port are cross-compatible)</i>
</p>

## Flashing CrossInk

The first thing I did was a sanity check to ensure all the hardware buttons, sensors, charging, etc. were
working correctly on the stock firmware. I then flashed CrossPoint Reader ([https://github.com/crosspoint-reader/crosspoint-reader](https://github.com/crosspoint-reader/crosspoint-reader)) and played around with it for
about a week. I then tried out a couple of alternative firmware options for the X3.

I found out that CrossInk, which is a fork of CrossPoint, has more features
([https://github.com/uxjulia/CrossInk](https://github.com/uxjulia/CrossInk)). What in particular made me migrate from CrossPoint to CrossInk were the current page becoming the
sleep screensaver when in a book and the ability to re-map hardware buttons to perform more operations compared
to what CrossPoint allows (CrossInk v1.3.2 as of writing this).

## Browsing via OPDS

CrossPoint (and by extension the CrossInk fork) supports OPDS, which lets me browse and download books and articles from the Internet.
I found out [Calibre-Web-Automated](https://github.com/crocodilestick/calibre-web-automated) provides an OPDS endpoint, and I already self-host it. It works nicely with CrossInk and lets me browse my collection from the device
itself. Due to the lack of OPDS support in [Karakeep](https://github.com/karakeep-app/karakeep) (as of writing
this), I also switched to self-hosting [Readeck](https://codeberg.org/readeck/readeck) to browse my saved
archives of interesting articles I come across on the Internet. I also self-host
[Miniflux](https://github.com/miniflux/v2) to subscribe to RSS feeds of people who write interesting stuff,
and I was able to connect Miniflux to Readeck to archive a post as soon as it lands. Now I can browse
and read on my X3. I really adore open ecosystems.
