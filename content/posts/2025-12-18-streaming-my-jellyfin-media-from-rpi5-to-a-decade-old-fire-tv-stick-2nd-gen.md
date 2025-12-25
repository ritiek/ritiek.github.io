+++
title = "Streaming my Jellyfin media from RPi5 to a decade old Fire TV Stick (2nd Gen)"
date = 2025-12-18
path = "2025/12/18/streaming-my-jellyfin-media-from-rpi5-to-a-decade-old-fire-tv-stick-2nd-gen"
template = "blog/page.html"
[taxonomies]
tags = []
+++

I own a decade old Amazon Fire TV Stick (Gen 2) which only supports H.264 hardware decoding. I've a couple of HEVC
encoded media files on my self-hosted Jellyfin instance which runs on my RPi5. RPi5 although supports HEVC hardware
decoding, it still lacks H.264 hardware encoding. For me to play my HEVC encoded Jellyfin media files on my Fire TV
Stick, I need to transcode my media from HEVC to H.264. I've tried out software transcoding to H.264 through my RPi5
itself, but RPi5 isn't performant enough to re-encode in real-time, more so after
[Jellyfin deprecated support for hardware decoding on RPi5](https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/#raspberry-pi-hardware-acceleration-support-deprecation)
likely even for hardware decoding of HEVC media, which the Pi5 itself is capable of. I could pre-transcode and store
everything HEVC to H.264, but then I also like the storage space savings I get from storing my media encoded as HEVC.

The Fire TV Stick variant I own is also end-of-life in regards to software updates and the last official (and 
unofficial) released Android version for it is 5.x. While Jellyfin installs fine on the stick, the problem is that
my RPi5 and my stick aren't on the same local network. I originally planned to tunnel my stick to reach my RPi5's
Jellyfin instance over VPN through Tailscale. However, Tailscale doesn't run on my stick since Tailscale doesn't
support Android 5 due to security concerns and the older Tailscale android releases that did support Android 5 do
not work on Android TV. I tried this and researched around, so this is coming from first-hand experience. And I'm
currently not daring enough to host my Jellyfin instance exposed to the public Internet.


## Streaming media from Jellyfin to my Fire TV Stick

The problem being it's not possible to install Tailscale app onto my Fire TV Stick, at least not any I could think
of or come across on the Internet. Since my Jellyfin instance is hosted in a different subnet,
I've to figure out a way to expose my Jellyfin instance to my Fire TV Stick without exposing my Jellyfin instance
to the public Internet.

I have a spare RPi400 in the same local network as my Fire TV Stick already in my Tailnet. I figured I could setup
Nginx to forward Jellyfin instance from my RPi5 onto my RPi400 and then feed in my RPi400's local IP address into
Fire TV Stick's Jellyfin client. [I did just that](https://github.com/ritiek/dotfiles/commit/51e0004ec96e6fa7ca038a1e53c0caa8fba420f4)
and it seems to work fine! I was able to access my Jellyfin content on the Fire TV Stick with this. However, there
is still the problem of me not being able to utilize hardware transcoding on my RPi5. Playing my media on the stick
suffered from long and frequent stutters that I couldn't overlook. Looking into btop on my RPi5, ffmpeg was bringing
up my CPU usage to 100%. I really needed something better.


## Remote transcoding

Looking around I came across [rffmpeg](https://github.com/joshuaboniface/rffmpeg) which simply wraps any ffmpeg
invocations to run on a remote machine through SSH. This seemed ideal for my case. My personal lappy is a somewhat
capable machine that supports hardware encoding and decoding for various media formats, at the very least it does
so for both H.264 and HEVC which I am dealing with here. I imagined I could use rffmpeg to offload transcoding onto
my personal lappy (inside my Tailnet) instead of performing it natively on my RPi5. It also looks rffmpeg primarily
supports covering the case of transcoding Jellyfin media as mentioned in the project's README, which looked promising.

Setting up rffmpeg to work properly with Jellyfin turned out to be quite an adventure (as we'll see below) which is
what prompted me to write this post. It did end up working nicely for my use case once everything was into place.

### My Jellyfin setup

I run a containerized version of Jellyfin (image provided by linuxserver) using Docker on my RPi5 through OCI
containers on NixOS. My RPi5's NixOS config for this Jellyfin server before setting up rffmpeg can be found
[here](https://github.com/ritiek/dotfiles/blob/6a4d93af53f6ec7f46397baf38a9aea5948a2f91/machines/pilab/compose/jellyfin.nix).

### Integrating rffmpeg

It looks the image I'm using [lscr.io/linuxserver/jellyfin](https://lscr.io/linuxserver/jellyfin) supports
rffmpeg through this mod:
[https://github.com/linuxserver/docker-mods/tree/jellyfin-rffmpeg](https://github.com/linuxserver/docker-mods/tree/jellyfin-rffmpeg).

This mod can be used through docker-compose with the Jellyfin image provided by linuxserver by adding in the following
environment variables:

```yaml
services:
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    ...
    environment:
      ...
      - DOCKER_MODS=linuxserver/mods:jellyfin-rffmpeg
      - RFFMPEG_USER=ritiek
      - RFFMPEG_HOST=mishy.lion-zebra.ts.net
      - FFMPEG_PATH=/usr/local/bin/ffmpeg
```

The other part of the setup (setting up SSH keys, etc.) is explained in detail over at rffmpeg's SETUP.md:
[https://github.com/joshuaboniface/rffmpeg/blob/master/docs/SETUP.md](https://github.com/joshuaboniface/rffmpeg/blob/master/docs/SETUP.md)

All what rffmpeg seems to do is pass the arguments over to the remote machine transparently, including the `-i`
parameter for the path to the input file. This is also a bit problematic. I'll have to replicate the file structure
for the input files from the Jellyfin container which runs on my RPi5, onto my personal lappy, so that ffmpeg
doesn't have trouble finding the path to input pieces when invoked through rffmpeg. I did try out rffmpeg without
these changes first and it indeed complains about missing path to the input file. I was able to look into these
logs using:
```bash
$ docker exec -it jellyfin rffmpeg log -f
```

To make the paths consistent inside of both the Jellyfin's docker container and my personal lappy, I could think of
a few options:

1. Run ffmpeg on my personal lappy inside of a Docker container and have path to input files in this container
   mapped exactly as how it is so in linuxserver's Jellyfin Docker image. I'll have to figure out what devices
   under `/dev/` would have to be passthrough'd inside of this Docker container from my host machine (I guess
   `/dev/dri` should be enough).

2. Run ffmpeg on my personal lappy in a chroot environment. In this case, say if my Jellyfin container expects media
   files to be present in `/data/movies`, then my lappy could have a path like `/home/ritiek/nfs/data/movies` and
   then I could wrap my ffmpeg binary to chroot into `/home/ritiek/nfs` as the first thing it does when invoked.
   That would make the paths consistent between the Jellyfin's Docker container and my lappy.

3. Create the paths from Jellyfin's Docker container onto my personal lappy. I don't want to make things messy on
   my personal lappy by creating random `/data/` or `/config/` directories on my root filesystem. I could however,
   update these paths into the container first to something like `/var/lib/jellyfin/data/` and then create these
   same paths onto my lappy.

I went with the third option. Just seemed a little less complex to maintain in comparison to other options once I
was to be done with adapting the paths to not look messy.

And so I had to update the paths where Jellyfin stores its Cache, Metadata, and Transcodes inside the `encoding.xml`
and `system.xml` config files created by Jellyfin. There also look to be options to update these paths from the WebUI
itself but I didn't try them. I also had to update the paths inside of my .nfo files for my saved music in Jellyfin
from `/config/data/metadata` to `/var/lib/jellyfin/data/metadata`:
```bash
$ sd "/config/data/metadata/" "/var/lib/jellyfin/data/metadata/" /media/HOMELAB_MEDIA/services/jellyfin/data/metadata/artists/*/artist.nfo
```

Be careful, this renaming of directories should be done after bringing the Jellyfin container down. Performing these
changes and then restarting the Jellyfin container, I had to re-specify the paths to my library items through the
Jellyfin WebUI to the newly mounted locations under `/var/lib/jellyfin/`.

There was still one last piece left - I had to somehow mount or share these filesystem paths from my RPi5 to my
personal lappy. For my case, I went ahead with setting up NFS between my RPi5 and lappy. This can also be done using
SSHFS but NFS seemed slightly more mature to use on NixOS with it having its own NixOS module (couldn't find one for
SSHFS) when looking up on the Internet. Expect some tinkering but there's information on the Internet on how to set
these up.

The diff of what changed when integrating rffmpeg into my NixOS config can be found
[here](https://github.com/ritiek/dotfiles/commit/dea99c792e1bdd0c10a952655eacf7ed6f79679f).

rffmpeg worked nicely after all of these things were into place and it was correctly invoking ffmpeg on my lappy instead
of running natively on my RPi5 as I could monitor using btop on my lappy - ffmpeg spawned up and was eating CPU on
my lappy as soon as I played anything on my Fire TV stick!


### Hardware transcoding

My lappy has an Nvidia MX450 chip but this chip doesn't support Nvidia NVENC so I can't use it to help with hardware
acceleration in Jellyfin sadly. The list of supported hardware acceleration methods can be found under Transcoding
settings in the Jellyfin WebUI. Nonetheless, I've an Intel processor in my lappy with Iris Xe graphics and I found
that Intel QuickSync (QSV) and Video Acceleration API (VAAPI) indeed work!

I can specify the path to QSV device on the Jellyfin WebUI as per how it's present on my lappy: `/dev/dri/renderD128`.
This works since this path is passed as a parameter to ffmpeg when invoked, and the ffmpeg present on my lappy gets
invoked thanks to rffmpeg.

I decided to stick with Intel QSV as the general consensus on the Internet seemed that it's a little more performant
in comparison to VAAPI. I also enabled the "Enable Intel Low-Power H.264 hardware encoder" and "Enable Intel Low-Power
HEVC hardware encoder" settings in Jellyfin WebUI and those seem to work as well.

I noticed that enabling this setting made Intel's Render/3D engine not work as hard and instead seemed to drive up
the Video engine a little more as seen in `intel_gpu_top`.

<p>
  <img src="/assets/intel_gpu_top.png" width="750">
</p>

This I like, since it frees up the Render/3D engine for other tasks (web browsing and all).

### Security concerns

Right now, I've been telling rffmpeg to login into my personal lappy as my default user via SSH. I need to create
a jellyfin specific user on my lappy with limited permissions, and re-configure rffmpeg to login as this user instead.

**UPDATE:** I've accounted for this after a few days later. I created a Jellyfin-specific user on my lappy with its own SSH key for authentication. Diff of my NixOS config for this change can be found [here](https://github.com/ritiek/dotfiles/commit/b9cc6eb15d74ba9f3b75d5b6be22b6bdd5ec7a81).

## Thoughts

That's pretty much it and I'm happy with this implementation. Although, it requires me to keep my lappy on anytime I
am streaming to my Fire TV Stick but I think I'm okay with the trade-offs as of writing this. Happy scavenging!
