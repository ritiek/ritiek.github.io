+++
title = "Structuring our Plasma factory"
date = 2018-05-28
path = "2018/05/28/structuring-the-plasma-factory"
template = "page.html"
[taxonomies]
tags = []
+++

We're mostly done with structuring our Plasma factory. The PR
([#459](https://github.com/PlasmaPy/PlasmaPy/pull/459)) just got merged yesterday! I'd have to say
we weren't expecting this to work out this quickly.

The reference to
[SunPy's Map](https://github.com/sunpy/sunpy/tree/0d784d24160ab04a0bd6876d948c915cdffea092/sunpy/map)
source made it a tad easier to understand how things are supposed to work for our PlasmaPy's
Plasma. :D

Also, [SunPy's `BasicRegistrationFactory`](https://github.com/sunpy/sunpy/blob/0d784d24160ab04a0bd6876d948c915cdffea092/sunpy/util/datatype_factory_base.py)
was so generic that we could have directly imported it in PlasmaPy without having to work <u>o</u>ut <u>o</u>n
<u>o</u>ne <u>o</u>n <u>o</u>ur <u>o</u>wn (wow, that's a lot of "<u>o</u>"s!). But really, I wonder
if it makes more sense that they should just publish a separate PyPi package for just this
registration factory.

If we didn't had any such reference, I am certain that our factory implementation would have consumed
a lot more time than we actually took.

Anyway, there are plenty of things that probably would need work in near future, like
overriding methods under `BasicRegistraionFactory` being inherited in `PlasmaFactory` to make it more
specific as we get to know our subclass needs, and defining generic plasma methods which are
common in most plasmas (`electronTemperature`, `ionTemperature`, etc.) under a `GenericPlasma` class.
We'll get to learn more about these needs as we work on subclasses for our Plasma factory as well.

Currently, We've been discussing about what subclasses would be nice to have
(some bits can be found in [#458](https://github.com/PlasmaPy/PlasmaPy/issues/458)).
And so, this is our next plan, to create variety of subclasses that deal with different plasma datasets.

Some of the openly available datasets we've located are
[Dense plasma database](https://github.com/MurilloGroupMSU/Dense-Plasma-Properties-Database),
[Johns Hopkins Turbulence Database](http://turbulence.pha.jhu.edu) and some
[example datasets](https://github.com/openPMD/openPMD-example-datasets) using the
[OpenPMD stanadard](https://github.com/openPMD/openPMD-standard).
By the way, if by any chance you're working on a particle-mesh dataset, I'd recommend you to use the
conventions under OpenPMD standard. It has the potential to make particle-mesh databases easier for other
people to visually parse and automate!

Lately, I've been working with [h5py](https://www.h5py.org) python package which allows parsing
the [HDF5 binary data format](https://hdfgroup.org). I'm very excited since this is going to be my
first time working in such a close proximity to large scientific datasets!

That will be all for now. See ya later.
