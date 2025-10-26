+++
title = "Adding support for JHTD in PlasmaPy"
date = 2018-07-11
path = "2018/07/11/adding-support-for-jhtd-in-plasmapy"
template = "blog/page.html"
[taxonomies]
tags = []
+++

During this period, nothing big happened except we're able to get merge a new
Plasma subclass supposed to work with OpenPMD Datasets
[#500](https://github.com/PlasmaPy/PlasmaPy/pull/500)! It still isn't
very efficient to work with larger datasets and should rather be considered a
prototype at the moment. It currently supports reading only mesh data from an
HDF5. It also reads the complete record into memory, which is certain to cause
problems with big datasets. In the real world, heavy datasets can go into dozens
of GBs. In the future, we're going to have to provide a way to read stuff
directly from disk or provide some other way instead writing all of it to memory.

As mentioned in my last blog post, we were able to add some more tests and
fill up some missing coverage in
[#506](https://github.com/PlasmaPy/PlasmaPy/pull/506). It gets kinda weird
when you're at a really high coverage like 95%+ and to increment another percent,
you have to add over a hundred more lines of code for tests. IMO it's worth it.

We're also working on [#509](https://github.com/PlasmaPy/PlasmaPy/pull/459) to
implement two fluid dispersion solvers in PlasmaPy. We have the formulae and
methods working to tackle "two fluid problems". We need some more refactoring to
make the interface a bit more cleaner, more tests and docs, and then it should
be ready to merge.

There were a few PRs accommodating small changes like
[#504](https://github.com/PlasmaPy/PlasmaPy/pull/504)
which I took over as the original contributor went inactive on GitHub and
[#510](https://github.com/PlasmaPy/PlasmaPy/pull/510) which adds another
attribute to return istopic name of a `Particle`.

We had some discussion over adding another subclass for working with
[JHTD (Johns Hopkins Turbulence Databases)](http://turbulence.pha.jhu.edu/) in
PlasmaPy and this is probably what we're going to be working on in the next phase.

As a side news, SunPy on the other hand might be rewriting their baseclass for
visibilities in xrayvision to focus on a more factory based approach just like
we did it with our plasma classes.

Also, my next semester classes are going to be starting on 16th this July. I really
wish I could stay home all day and just code and stuff for a little while more
but nah, life happens.

Okay then, take care. Oh and yes, evaluations for phase-2 are currently on their way!
Time frikkin' flies and here we are about to move into our GSoC's final phase!
