---
title: "Sharing Linux event devices with other Linux machines"
date: 2019-02-18
layout: post
comments: false
tags:
  - linux
  - event
  - wireless
---

In Linux machines, `/dev/input/event*` are special files known as devices files. These files act
as a middle man between an application software and the kernel to interact with the hardware input
devices connected to the system. To know what devices are connected to your system, run:
```
$ cat /proc/bus/input/devices
...
I: Bus=0011 Vendor=0002 Product=0007 Version=01b1
N: Name="SynPS/2 Synaptics TouchPad"
P: Phys=isa0060/serio1/input0
S: Sysfs=/devices/platform/i8042/serio1/input/input5
U: Uniq=
H: Handlers=mouse0 event5
B: PROP=1
B: EV=b
B: KEY=e520 xxxxx 0 0 0 0
B: ABS=66080001100xxxx
...
```

This should give you list of input devices attached to your machine at the moment. For example,
the output above contains information about my laptop's touchpad. The corresponding event file of my
mouse is `/dev/input/event5`. Let's try to `cat` it (you may need root):
```
$ cat /dev/input/event5
```
It wouldn't normally output anything, but you should get lots of *weird* output on placing a finger
on your touchpad, here is what it looks on my laptop:
```
Zj\(
    5Zj\(
         :AZj\(
               Zj\(
                   AZj\(
                        Zj\4
...
```

This output is actually a serialized `struct` corresponding to following data of an input device:
```
struct input_event {
    struct timeval time;
    unsigned short type;
    unsigned short code;
    unsigned int value;
};
```

The docs here contain some detailed information on input devices in Linux:
[https://www.kernel.org/doc/Documentation/input/input.txt](https://www.kernel.org/doc/Documentation/input/input.txt).

Someone on stackoverflow has written some Python code on how this output can be decoded into
readable form, here [https://stackoverflow.com/a/16682549/6554943](https://stackoverflow.com/a/16682549/6554943).

There is also a Python package named [evdev](https://python-evdev.readthedocs.io/en/latest/install.html)
which allows us to both read events and write custom events to these device files.


**Let's get to the nasty stuff now.**

It is also possible to read the event device files of another machine via SSH, like so:
```
$ ssh user@hostname cat /dev/input/event1
```
Make sure the user has been granted read access to the event device file, otherwise you'll get
a permission denied error. This can be done by running `$ sudo gpasswd -a USER input`. Replace
`USER` with the host's username. If it still doesn't work, a hacky workaround would be to use
`chmod` with appropriate permissions on the event device file to allow read access to the
unprivileged user. Either way, you should now be able to read the event device file of the other
machine.

If the client machine's and the host machine's architecture are the same (say both are x64). You
could also pipe events from the host machine to your machine! I tried this and it seemed to work
with keyboards but didn't work with mouse.

```
$ ssh user@hostname "cat /dev/input/event1" > /dev/input/event4
```
On running this, you would be able to pipe device data from the host machine to your client machine.
Both event devices should correspond to the same input device for it to work, that is, say `/dev/input/event1`
is the keyboard device on the host machine whereas `/dev/input/event4` is the keyboard device on the client
machine. Anything entered on the host machine via the keyboard will now also mimic on the client machine.

However, this does not "grab" the input received on host machine. That is, pressing a keyboard key
would perform an operation on the client operation but the same operation will also be performed on the
host machine. I'd rather pass all event data to my client machine and block the event data from reaching
the event device file on the host machine. In this way, one could work wirelessly without worrying
about the input device causing the same effects on the host machine when one is focused on the client
machine.


## What if the host machine's architecture and the client machine's architecture are not the same?

I tried the same procedure above to share the keyboard attached to my Raspberry Pi Zero W with my x64
machine. Meaning everything entered on the Pi Zero will also be mimiced on my x64 machine.
However, it didn't work. If you remember the `struct` above, all of the items in that `struct` were
same for the same set of keys pressed, except for `value`. The value of `value` parameter seems
to be architecture dependent.

I imagined a possible a way to get around this would be to read the event device file of a remote
machine having a different architecture and modify the `value` parameter such that it is correctly read
by the kernel and then write this new data to my local event device file. So, I went on a quest but
not much later I came across [https://github.com/Blub/netevent/](https://github.com/Blub/netevent/) which
probably does the same thing ("probably", because I am not a C++ guy). The example given in their README
"sharing keyboard & mouse with a machine via ssh" does exacty what we need - sharing event device files
between architectures. It also offers the ability to share devices that are not present in the client
machine. For example, I could share an X-Box controller which is connected to my host machine, with my client
machine which does not have any event device file for parsing X-Box controller events (I think it might
be possible to achieve this via `$ mknod` command but I haven't tried yet). One would need to add the event
devices he/she wishes to share via SSH in the `netevent-setup.ne2` file and add a hotkey on the host machine
which would then pipe the output of the written `/dev/input/event*` device files to the client machine.
Another good thing is that it "grabs" the input events on the host machine. So, the events are only
received by the client machine while all the input on the host machine is blocked from reaching the event
device file present on the host machine itself.

Also, since Android is based on the Linux kernel - it is very much possible to run netevent on it. In
fact, I was able to compile the codebase for Termux on my rooted Android Phone with a few modifications
[https://github.com/ritiek/netevent/tree/termux](https://github.com/ritiek/netevent/tree/termux).
You must need root to access `/dev/input/event*` files on
Android. After completing the intial setup, it allowed me to virtually connect my Linux machine's keyboard,
mouse, gamepad, powerlid switch, power button (, you name it!) to my Android Phone. Moving the touch pad of
my Laptop moved a mouse pointer on the Phone (I never knew my Phone could display a mouse pointer!), the
power button on my laptop turns off/on the phone screen! If you're going to try this out, make sure you export
the LD_LIBRARY_PATH for root user before executing the netevent binary via SSH. To do so, replace your output
command in `netevent-setup.ne2` with something like this:
```
output add myremote exec:ssh user@hostname -p 8022 su -c "LD_LIBRARY_PATH=/data/data/com.termux/files/usr/lib /data/data/com.termux/files/usr/bin/applets/netevent create"
```

I was also able to make my Android Phone act the host machine and share my Phone's power and volume buttons
with my laptop to perform actions which is equivalent to pressing the power button / changing the system
volume on my laptop. However, the touch on my Android didn't seem to perform anything on the laptop, not
even control the mouse as one would expect. I saw that there were additional `/dev/input/event*` files
created on my laptop and the Android touch on was being registered on my when I `cat` the appropriate device
event file on my laptop but it seems like my laptop has no idea what the event data it received is supposed to do. There might
be some more things possible like sharing the fingerprint scanner with the Linux machine (I tried it but
couldn't get it to work, but someone more experienced might have a better chance).

I also have a jailbroken Kindle Paperwhite 3, so I decided to give it a try as well. Turns out I was able
to cross-compile netevent for Kindle using `arm-linux-gnueabi-cpp-4.9` cross-compiler (seems like the apt
package `g++-4.9-arm-linux-gnueabi` is only available on older distro versions like Ubuntu Xenial, so I
created a Travis CI build which runs Xenial and used it to cross-compile for Kindle and allowed it to put
up the generated binary on the internet for me to download). For some reason, it looks like g++-5 and later
do not work with the Kindle. It would complain about some missing libraries I have no idea to workaround
them. Anyway, transferred the binary generated g++-4.9 to my Kindle and worked without a hitch. My Kindle
Paperwhite 3 doesn't offer many input devices, only the power button device file and touch screen device
file were located inside `/dev/input/`. Set the Kindle power button as the hotkey for netevent. And even
then, I was at best only able to control my Laptop's and Android's mouse pointer with the Kindle touch screen.
I couldn't get it to work the other way round (that is, controlling Kindle by sharing my laptop's event
devices).

Anyway, this is such a cool tool! I wonder why not more people know about it?

**CAUTION!** If any of you wish to try the stuff above, be very careful! You are root and mistakenly moving
or deleting any system file could put you in real trouble as you can't live boot or use other recovery
utilities available on a usual full-fledged Linux machine with Android and Kindles (especially the
Paperwhite 3 which doesn't even offer a fastboot mode!). A small mistake and you could end up in a void.
