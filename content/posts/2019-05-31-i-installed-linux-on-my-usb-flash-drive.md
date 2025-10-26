+++
title = "I installed Linux on my USB flash drive!"
date = 2019-05-31
path = "2019/05/31/i-installed-linux-on-my-usb-flash-drive"
template = "blog/page.html"
[taxonomies]
tags = []
+++

In my university, we mostly have only-Windows computers. What I mean by "only-windows computers" that the computers
have Windows as the only operating system installed on them. Now, I always like to be accompanied by a terminal
with everything I do (even writing this post in a TUI on Linux) and avoid proprietary software whenever possible.
By the way, [cmder](https://github.com/cmderdev/cmder) is a pretty good project that adds the missing flakes (like
wget, curl, etc.) to the command-prompt but it doesn't change the fact that Windows itself is still closed-source
(atleast as of writing this). Me, being an avid supporter of open-source cannot back down here.

I plotted an evil-plan. I created a live Linux Mint bootable USB (that's what I use as my home OS) and told myself
that I would install a copy alongside Windows on each machine I sit in every computer lab. Installing Linux Mint
takes about 15 minutes on these computers in my lab but it got annoying that I would have to later on also
install the compilers, dependencies and other configuration stuff I make home with. And, also sometimes I would
find that someone (other students or staff?) would delete the partition I installed Linux Mint on and thus bring all of
my progress back to zero again. I dunno why or who did that but it sucks. It wasn't as if I made Windows unusable on
those machines or ate a lot of hard-drive space (30GB isn't really much, ok?) but that was it.

This is beyond to what I would have guessed but looking up I found that I could also make a full install Linux Mint
on the flash drive itself. I've never seen a USB with full installed Linux Mint so this was quite interesting and
I was genuinely surprised when I did this and it worked. I've also tried making a persistent Live Mint bootable
USB but it created too many partitions on the USB that it looked ugly and also it didn't offer any login password
protection essential for protecting against non-techie people. Also, the internet and my tests say that
a full install on flash drive is faster to boot than a persistent live flash drive. I haven't tested this one
but I guess the read/write speed would also probably be a bit faster.

Later, I realized that a USB with fully installed Linux formatted as Ext4 wouldn't be recognized by Windows
(unlike persistent live USB, which gets recognized by Windows and allows you to both read & write to the USB). This is a
problem because sometimes I have to copy some general documents and maybe print them. Most students are happy
with Windows and the printing shops in our campus also are Windows. It would be stupid if my USB wouldn't be
recognized on such machines. I could carry around another USB formatted as FAT32 or NTFS but there has to be a
better solution. I thought about creating a multipartioned USB with Linux installed on Ext4 formatted parition
and another empty partition formatted as FAT32 for Windows to recognize it. However, it turns out that and earlier
versions of Windows (before Windows 10) would only go through the 1st partition of the USB and mount it if is able
to properly read that partition. Other partitions are completely ignored irrespective of whether the 1st partition
is readable by Windows or not. Windows 10 on the other hand has a small improvement that it will iterate on all
the available partitions, mount the first one it is able to read correctly and ignore the remaining partitions.

Nevertheless, I formatted the 1st partition as FAT32 with enough space to suffice everyday copy-pasting documents
and installed on Linux Mint on the 2nd partition with the remaining space. Everything worked fine, I was able to boot
into Linux Mint and see the FAT32 partition on Windows. I also like this since unexperienced people who get hold
of my flash drive would only see the FAT32 partition on Windows and assume that's all the storage the flash drive
has to offer while the partition with Linux on it would essentially stay hidden in Windows! Thanks Windows!

Also, I have a cheap laptop, the ones that come with a 64-bit processor but a 32-bit UEFI (and no legacy BIOS support).
I intially created my bootable USB with legacy BIOS since I have yet to find a use for all the fancy features that
UEFI gives and most machines with 64-bit UEFI also support legacy BIOS boot. Now, if I could get the flash drive to
boot on my cheap laptop I could be done with this. You see 64-bit processor with 32-bit UEFI can be a pain! Linux
Mint does not officially support for 32-bit UEFI. So far only raw Debian and Fedora does AFAIK. I've heard this is a
limitation in the Linux kernel itself, so these OS probably modify the kernel to add support for 32-bit UEFI. Anyway,
I was able to manually create a UEFI bootable partition on my flash drive USB with the help of this beautifully written guide:

[https://medium.com/@realzedgoat/a-sorta-beginners-guide-to-installing-ubuntu-linux-on-32-bit-uefi-machines-d39b1d1961ec](https://medium.com/@realzedgoat/a-sorta-beginners-guide-to-installing-ubuntu-linux-on-32-bit-uefi-machines-d39b1d1961ec)

BUT, turns out that most stuff does not work properly. Sound does not work. Battery percentage won't show up.
Touchpad gets recognized as a USB mouse, that means no two-finger scrolling or gestures. And sometimes the operating
system just freezes for eternity. Anyway, I'm happy that I made it this far and atleast that my flash drive works perfectly
fine with legacy BIOS boot and machines with 64-bit architecture and UEFI.
