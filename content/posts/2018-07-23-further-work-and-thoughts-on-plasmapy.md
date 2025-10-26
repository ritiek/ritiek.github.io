+++
title = "Further work and thoughts on PlasmaPy"
date = 2018-07-23
path = "2018/07/23/further-work-and-thoughts-on-plasmapy"
template = "blog/page.html"
[taxonomies]
tags = []
+++

Oh, there we go! Time for GSoC's pre-final blog post.

Ah, so the last week was a bit draining for me. My college started last monday
and I accidently messed up my Linux machine the next day! Never ever remove
(`apt purge`) the `dbus` package (especially not when playing with `python-dbus` package).
It will render your system utter useless, atleast that's what happened to me.
It removed several other system packages on my machine along with `dbus`.
I ended up destroying my X server and network-manager (and god knows how many other packages).

For fixing these broken packages - I tried to install the missing .deb packages via external USB but those packages
complained about several other missing packages and this kept recursing
until I gave up. Couldn't get chroot from a live USB to install the missing
packages either.
I finally took a backup of the little things I wouldn't be able to live
without and installed Linux Mint 19. Tara (codename) has many cool features and UI
improvements. Though I won't be mentioning them here and consume more of your
time hearing my nasty adventures.

During these unfortunate times, I tried to set-up PlasmaPy on my brother's
Windows machine. Everything went fine except I wasn't able to run our
test suite, [so I filed a bug](https://github.com/PlasmaPy/PlasmaPy/issues/516).
Eventually, I was able to trace it back to astropy and
[pushed a fix to upstream](https://github.com/astropy/astropy/pull/7673)!

Otherwise, this period went pretty smooth. We decided to not work further on
JHTDP (atleast not in this phase) as we're not yet perfectly clear on how we
are going to be using this database and if it would be worth the effort.
Additonally, I looked up [some examples](https://github.com/idies/pyJHTDB/tree/master/examples)
on using the [pyJHTDB](https://github.com/idies/pyJHTDB) API and IMO this
probably wasn't going to be completed within a single GSoC phase. Those
examples still scare me.

The community is working to get PlasmaPy on conda-forge and has made
[quite a progress](https://github.com/conda-forge/staged-recipes/pull/4793)!
We might be coming to conda soon!

I also made a PR (not yet merged) to
[accept non-unit type annotations in `@quantity_input`](https://github.com/astropy/astropy/pull/7672)
in astropy. This will allow us to use this useful decorator in PlasmaPy in many
places we avoided earlier. Many a times, we end up annotating our function definitions
to whatever data type is expected by the function parameter. That's some cool stuff.

At the moment, I am manually playing with our API hoping to find bugs and ideas.
I did find a bug where our
[`online_help` function did not work as expected](https://github.com/PlasmaPy/PlasmaPy/pull/511).

We also added another attribute
[`isotope_name` on `Particle` class](https://github.com/PlasmaPy/PlasmaPy/pull/510)
a few days back. Yey!

By the way, I haven't been able to spend as much time on PlasmaPy and other projects under
OpenAstronomy due to my college classes and travelling to & fro, which take most
of my day time. I hope this wouldn't be a problem as I completed many of my
GSoC's main project goals already. ;)

Anyway, I'm still trying to make time to contribute the littlest of things I can
manage during this phase.

(I also just realized I need to enable the comment section on these posts, oh crud,
I felt some static. This would be more work than I expected.)
