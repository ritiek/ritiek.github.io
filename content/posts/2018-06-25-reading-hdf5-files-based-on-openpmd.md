+++
title = "Reading HDF5 files based on OpenPMD"
date = 2018-06-25
path = "2018/06/25/reading-hdf5-files-based-on-openpmd"
template = "blog/page.html"
[taxonomies]
tags = []
+++

We're currently working on developing a new Plasma subclass. It is supposed to read
HDF5 files that are based on OpenPMD standard and we have a sort of prototype ready
in [#500](https://github.com/PlasmaPy/PlasmaPy/pull/500). It should be ready to
merge once we figure out how we are supposed to handle the example datasets for our
tests. It probably isn't a good idea to ship them with the main PlasmaPy codebase.
I guess we're going to settle downloading them on the fly when running our tests.
Let's see.

I had trouble getting
[OpenPMD-api](https://github.com/openPMD/openPMD-api) to install from source and
with spack package manager but the guys at OpenPMD are really helpful and
updated their documentation appropriately real quick
([openPMD/openPMD-api#279](https://github.com/openPMD/openPMD-api/issues/279))!

As an update from my last blog post on our coveragerc problems; in the end
we decided to settle with [#502](https://github.com/PlasmaPy/PlasmaPy/pull/502).
The problem is that PlasmaPy and SunPy (maybe also other projects?) depend on Astropy's testing
modules which is the root cause of the problem. We've had some discussion in
[astropy/astropy-helpers#397](https://github.com/astropy/astropy-helpers/issues/397).
However, [@Cadiar](https://github.com/Cadair) is still messing around with it in
SunPy and has made progress in
[sunpy/sunpy#2667](https://github.com/sunpy/sunpy/pull/2667). Hopefully, astropy
will go through some refactoring too and then we could all live peacefully.

Some other cool stuff that happened during this period. We increased coverage
in our langmuir.py module in [#498](https://github.com/PlasmaPy/PlasmaPy/pull/498).
There are still some corners where could increase coverage a bit, I think I am
going to make more PRs soon. I remember we had 99% code coverage in March then it
dropped to somewhere around 92% shortly after we had our first release. I am glad
we made it back to 98% as of now!

----------

Oh, I almost forgot! I received my first stipend a few days back! I've never
earned more in my whole life before this, not even a quarter to be honest.
I am not sure what I am going to do with it for now. Maybe get a new lappy?
A musical instrument? Pay the bills? Donate to a cause? No idea but it makes me
happy to think about stuff! :D

That's all folks. Stay happy, have fun!
