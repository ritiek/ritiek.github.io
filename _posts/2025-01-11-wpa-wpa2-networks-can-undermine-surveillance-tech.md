---
title: "WPA/WPA2 networks can undermine surveillance tech"
date: 2025-01-11
layout: post
comments: false
tags:
  - linux
---

There's a home that's built on a nice mountain. The members of this nuclear family all live a life that
requires them to spend a part of the day outside the house. Parents go out to attend work. The kids have school.
Knowing that there'll be no one (or worse, only kids) in the house for a period of time everyday, the family
realized it'd be nice to secure the perimeter of the house by setting up surveillance cameras. The family members consume technology but they aren't very technical themselves. They research a bit around before deciding on
the cameras they'll use to set the surveillance up using.

"Honey. These surveillance cameras also have a mobile app. It says so on the website."

"What if there happens to be an electricity cut? Cameras gonna go off."

"Humm. Yeah."

"Oh, found them. These ones have an internal battery that says it should last the camera for 2 hours."

"These cameras work on WiFi, but that's fine as we've already got our ONT on a UPS backup."

"Awesome! Karen from my office also uses similar cameras for their home."

"Let's get these!"

The family gets some nice cameras that they fit around the house. Their phones don't have to be connected to
their home WiFi since these "nice" cameras have come with a mobile app that allows them to see the video feed
of their cameras even if they are outside of their home. This means, the family can monitor their cameras from
their office workplace.

It's been a few months now with the cameras installed. Their house is safe. The mobile app notifies the
parents when their kids have returned safely from school. They're able to monitor their house during the
occasional power-outages. The video feeds stay on the (camera company's proprietary) cloud. Which is cool
as the parents are now able to access the past video feeds, even when the cameras are turned off.

Everything's looking good.


One day, dad gets a notification on his phone from the camera's mobile app: "Human presence detected!".
Dad thinks to himself without checking the camera feed:

"Oh cool. Wifey's sandals must be here."

He expects to receive a call from the delivery guy since the front door is locked.

"It's been a while, what's the guy doing..?"

*Casually opens the camera app on his phone.*

He sees two people with their faces masked up. They are leaving the house with a few sacks in their hands
to a car parked near the family's house. That spikes up dad's anxiety.

"...the heck?!"

Dials up 911 (or the equivalent) to send a dispatch to their house.

"Wait. This video feed was recorded 3 hours ago?!"

That is interesting. Why did the notification showed up now and not while the burglary was unfolding? Did the
cameras mess up?
Was it the software? Did the internet go down? No, that can't be so. The internet hardly ever goes down
this area, let alone such a coincidence with the robbery.

The master power control is present inside the house itself. It would've been very difficult to turn down
the power without first breaking into the house, which doesn't make sense as he'd have gotten the
notification if the burglars tried doing so. Also, the UPS would've lasted them a couple hours, both the
cameras and their home internet.


## What could've gone wrong here?

One plausible possibility seems like the camera software indeed messed up somewhere.

Maybe the camera software for some reason failed to send a motion event to the company's proprietary cloud.

Maybe the company's cloud software failed to notify dad and mom's mobile app.

Maybe the camera failed to detect the humans wearing masks over their face as humans, since we had to
disable object detection due to high rate of false-positives in motion detection due the plants moving
with the wind.

Maybe the camera firmware auto-updated and broke itself yesterday.

Maybe the mobile app and notifications have been broken since the last update on the playstore/appstore
which happened a few days ago.


You can self-host all the above parts of software to get more fine control over the devices you own, which run
the above mentioned software, to reduce the possibility of the above issues. I feel this can easily take a
month to get into and solve the problem to a good extent, given the person is supposed to show up at their
office on weekdays and the person is technical enough to even consider attempting to solve the problem in
the first place.

Dealing with all of the above is something pretty much out of the question for your average neighbour.

The local police can't seem to get a grip on what happened. Of course, people change their clothes. and
any physically wearable and social masks.

However, the cameras and the company software were both godsend, so none of the above was an issue. It was
seen in the recorded video feed later on that the burglars looked to be carrying some sort of antenna-based
device?

"Wait. What is this antenna thingy that robbers look to have forgotten in our house??"

Bombsquad made sure it's not a bomb.

The family clicked pictures of the thing. The next day, they sent it over to this young distant relative of
theirs.

"We occasionally ask him to fix our printer. A very nice guy."

The relative takes a while to get back.

"Hmm. Is it a Raspberry Pi? It looks a Raspberry Pi Zero. Hacked up to a battery backup?"

"Oh, that antenna looks like an external WiFi adapter. I can read it saying ...ALFA??"

My guess is the burglars connected an external WiFi adapter to a RPi Zero, constantly broadcasting deauth
packets to the nearby APs, *cough cough* aircrack-ng is it called? Oh right, the family also used a WPA/WPA2
secure network. Isn't that what everybody sees when they're connecting to their favourite WiFi? Yeah, seems
it's suspectible to an attack that forces the access point to drop any connected clients if it receives this
specially crafted network packet. This must've went on until the battery ran out and the RPi forced itself
off from the lack of input power.

This exploit may not have worked with if the access point used was WPA3. But that is not what we're all doing,
right?

"So you say our cameras wouldn't connect to our WiFi because of this thing nearby?"

"But we tried to turn on this antenna thing using our uh.. what they call.. MicroUSB wall adapter and
our WiFi has been working fine for the past hour."

The filesystem present in the MicroSD card in the RPi is LUKS encrypted. Yep right, it asks for a key
to unlock at initrd when it's connected it to a monitor. Now to guess what it'd be.

"password"?

Yeah. Good luck.
