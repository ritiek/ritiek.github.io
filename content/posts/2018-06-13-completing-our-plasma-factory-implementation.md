+++
title = "Completing our Plasma factory implementation"
date = 2018-06-13
path = "2018/06/13/completing-our-plasma-factory-implementation"
template = "page.html"
[taxonomies]
tags = []
+++

As we all (probably) know now, our Plasma factory implementation got finished much
sooner than expected. So, I've been mostly lurking around since my last blog post
adding features in our plasma pie, discovering bugs under our plasma bed, reviewing
plasma requests, gazing at stars made of plasma, etc.

I'll talk about some of the progress that's being made in PlasmaPy. I made a PR
([#483](https://github.com/PlasmaPy/PlasmaPy/pull/483)) that allows us to pass collections
to our `particle_input` decorator. This was my first time working with decorators in real
world programming. It seems like it turned out pretty well. Oh and
[#493](https://github.com/PlasmaPy/PlasmaPy/pull/493) was cute.

I also moved around tests for our plasma subclasses
([#489](https://github.com/PlasmaPy/PlasmaPy/pull/489)).
One thing I noticed during this PR that it is important to have `__init__.py` in each of
your directory, otherwise any tests in directories without `__init__.py` are not going
to be picked up with `./setup.py test`! However, they seem to work when using `pytest`
directly though. I found a similar problem with
[#494](https://github.com/PlasmaPy/PlasmaPy/pull/494) which shot up our coverage from
93.18% and 95.38%. It is pretty surprising, a single empty `__init__.py` can do wonders.
So, if anyone is reading this uses `./setup.py test` in their projects right now, you better
take care of such stuff in your codebase. You really don't want to be writing tests only
to realize it later on that they aren't even being executed.

Also, we recently shifted to CodeCov instead of Coveralls. Why? No big reason except CodeCov
apparently has a greater userbase.
[and some minor differences can be found here](https://www.google.com/search?q=codecov+vs+coveralls).

We are currently fighting with `coveragerc` configuration file not being picked up by `coverage`,
which is a code coverage measurement in tool for Python.
([#495](https://github.com/PlasmaPy/PlasmaPy/pull/495),
[#496](https://github.com/PlasmaPy/PlasmaPy/pull/496),
[#497](https://github.com/PlasmaPy/PlasmaPy/pull/497)). So, some stuff like `# coveralls: ignore`
does not get respected and `coverage` marks these lines in red (meaning that they aren't covered)
instead of just leaving them whitish (ignoring them).

We could replace `# coveralls: ignore` with `# pragma: no cover` since that is the
default for `coverage` and it works with CodeCov integration
([ritiek/PlasmaPy#3](https://github.com/ritiek/PlasmaPy/pull/3)), but this might
leave other future additions to `coveragerc` file still a problem if it isn't going to be picked up
by `coverage`. There is a workaround that seems
to be sort of working ([ritiek/PlasmaPy#4](https://github.com/ritiek/PlasmaPy/pull/4), do
notice it further shoots up our coverage from 95.38% to 96.69%!) and is probably bit ugly but
should hopefully suffice for the moment if we can't find a better solution.

The next little bit related to GSoC is that I expect to create a Plasma subclass which reads
HDF5 files that are based upon OpenPMD format using h5py python module and then expose relevant
attributes of information.
I suspect it isn't going to be a big task but we'll get to shed light on further details once
we see this little bit happen in PlasmaPy.

OK that would be all for now. Happy plasma pie baking, bye!
