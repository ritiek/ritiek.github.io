+++
title = "Docker freezes machine by spiking up CPU I/O to 100"
date = 2024-08-10
path = "2024/08/10/docker-freezes-machine-by-spiking-up-cpu-io-to-100"
template = "blog/page.html"
[taxonomies]
tags = []
+++

## ..on an RPi5

I've since moved from [micro-homelabbing on an RPi4](/2023/12/26/homelabbing-on-a-raspberry-pi-4/)
to an RPi5 now. I use the official power adapter as well as the active cooler, and have connected my NVMe drive through RPi5's
PCIe slot (over Pimoroni's NVMe Base).

During migration from RPi4 to RPi5, I decided to format a new MicroSD card to make sure the new RPi5 kernel'll support
all the new hardware present in RPi5. Before the migration, I double-checked to make sure everything homelabby that needed
to be persisted resided on my NVMe disk, and that nothing important resided in `/var/lib/docker/volumes`
(just had nukeable logs and some redis related cache there!).

## Problematic CPU I/O

That done, now a couple months later I've noticed my CPU I/O would spike up to 100 and stayed on it until my RPi5
came to a grinding halt. This spike would happen whenever I were to mount my LUKS + BTRFS NVMe drive and launch dockerd's
systemd service. It has also been interesting to notice that this I/O spike wasn't caused overnight. I've noticed it
gradually building up every successive time I mounted my drive and launched dockerd. It was only until recently that I
upgraded my kernel from 6.6.y to 6.9.y using `rpi-update`, rebooted my RPi5, and on mounting my drive + launching dockerd
that it started to freeze up the entire system during dockerd attempting to start my docker-compose swarms. Also the
problem stayed even if I tried out other kernel versions, both newer and the older ones from the one I had originally.

`btop`, `iotop -ao`, and `iostat` have been very helpful in analyzing these spikes all these months and figuring out that
it was indeed the high CPU I/O wait that has been building up all this while.

## Now what?

I upgraded my docker installation from the default bullseye apt repositories (Docker Engine v20) to use docker's official
repositories (Docker Engine v27). And then nuking my `/var/lib/docker` and starting over looks to have fixed it??

So not sure if this could've been a kernel, LUKS, BTRFS, or the buildup in `/var/lib/docker`, or some permutation of
these that had been contributing to the issue. My CPU I/O during dockerd launch while starting the same docker-compose
swarms is almost negligible now. All good.

I'll do an update here if I start to notice this CPU I/O building up again.
