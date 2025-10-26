+++
title = "Summer past and GSoC ends"
date = 2018-08-10
path = "2018/08/10/summer-past-and-gsoc-with-plasmapy-ends"
template = "blog/page.html"
[taxonomies]
tags = []
+++

It's that time of the year when students are supposed to submit their final
evaluations. As Google expects students to put up their final reports somewhere
in a stable location and as there is always a chance that I might mess up something
on my blog, so I also made a
[Gist wrap up of this blog post](https://gist.github.com/ritiek/505b696436182a4b3da027787c831edc)
of how we progressed in
these few months and all the great stuff that happened in our community.

My original project - to create a factory based implementation for unifying handling of different types of Plasmas, was completed sooner than expected. Here are the link to related pull requests I made during the summer.

  | PR                                                    | Status                                     | Description                                                                                                   |
  |-------------------------------------------------------|--------------------------------------------|---------------------------------------------------------------------------------------------------------------|
  | [#501](https://github.com/PlasmaPy/PlasmaPy/pull/501) | ![Merged](/assets/YnDnRzm.jpeg) | Raise more fitting `NotImplementedError` for functions that are yet to be implemented in our Plasma metaclass |
  | [#489](https://github.com/PlasmaPy/PlasmaPy/pull/489) | ![Merged](/assets/YnDnRzm.jpeg) | Independent tests for our Plasma subclasses                                                                   |
  | [#459](https://github.com/PlasmaPy/PlasmaPy/pull/459) | ![Merged](/assets/YnDnRzm.jpeg) | Implement a Plasma factory interface to unify handling different Plasma types                                 |


Hail `plasmapy.classes.Plasma`! A glimpse of how it looks like
```python
>>> import astropy.units as u
>>> import numpy as np
>>> import plasmapy.classes

>>> T_e = 25 * 15e3 * u.K
>>> n_e = 1e26 * u.cm ** -3
>>> Z = 2.0
>>> particle = 'p'
>>> blob = plasmapy.classes.Plasma(T_e=T_e,
...                                n_e=n_e,
...                                Z=Z,
...                                particle=particle)

>>> type(blob)
plasmapy.classes.sources.plasmablob.PlasmaBlob

>>> three_dims = plasmapy.classes.Plasma(domain_x=np.linspace(0, 1, 3) * u.m,
...                                      domain_y=np.linspace(0, 1, 3) * u.m,
...                                      domain_z=np.linspace(0, 1, 3) * u.m)

>>> type(three_dims)
plasmapy.classes.sources.plasma3d.Plasma3D
```

As my original project was completed sooner than expected. I further implemented a new Plasma subclass for reading HDF5 datasets respecting OpenPMD standards.

We had to choose between [h5py](https://github.com/h5py/h5py) and [OpenPMD-api](https://github.com/openPMD/openPMD-api) packages for reading HDF5 dataset files.
At that time, the OpenPMD-api had a few [installation issues](https://github.com/openPMD/openPMD-api/issues/279) and it was hard to distribute with PlasmaPy as it isn't available on PyPi yet, not many people use [spack](https://github.com/openPMD/openPMD-api#spack) and certainly not many people would give it a go [building from source](https://github.com/openPMD/openPMD-api#from-source).
It is however, available on [conda-forge](https://anaconda.org/conda-forge/openpmd-api) but PlasmaPy isn't (yet). :(

So, h5py it was then.

  | PR                                                    | Status                                     | Description                                                                                                   |
  |-------------------------------------------------------|--------------------------------------------|---------------------------------------------------------------------------------------------------------------|
  | [#500](https://github.com/PlasmaPy/PlasmaPy/pull/500) | ![Merged](/assets/YnDnRzm.jpeg) | Implement a prototype to read attributes from HDF5 datasets based on OpenPMD standards                        |

However, It still isn’t very efficient to work with larger datasets and should rather be considered a prototype at the moment.
It currently only supports reading mesh data from an HDF5 dataset.
It also reads the complete record into memory, which is certain to cause problems with big datasets.
In the real world, heavy datasets can go into dozens of GBs, so we’re going to have to provide a way to read a part of dataset at a time from disk or provide some other way in the future instead writing all of it to memory at once.

----------------------------------------------------------------------

**During the summer, I also worked on implementing other functionality, bug fixes and improving test coverage in PlasmaPy.**

We ended up making our `atomic.Particle` class and `@atomic.particle_input` decorator more pleasant to use and now works better than ever!

  | PR                                                    | Status                                     | Description                                                                                                   |
  |-------------------------------------------------------|--------------------------------------------|---------------------------------------------------------------------------------------------------------------|
  | [#528](https://github.com/PlasmaPy/PlasmaPy/pull/528) | ![Merged](/assets/YnDnRzm.jpeg) | Functions decorated with `@particle_input` now accept default Particle value                                  |
  | [#527](https://github.com/PlasmaPy/PlasmaPy/pull/527) | ![Merged](/assets/YnDnRzm.jpeg) | Typo fixes in `@particle_input` error messages                                                                |
  | [#510](https://github.com/PlasmaPy/PlasmaPy/pull/510) | ![Merged](/assets/YnDnRzm.jpeg) | Add an `isotope_name` property on `Particle` class                                                            |
  | [#504](https://github.com/PlasmaPy/PlasmaPy/pull/504) | ![Merged](/assets/YnDnRzm.jpeg) | Add a `roman_symbol` property which returns integer Particle charge in Roman notation                         |
  | [#493](https://github.com/PlasmaPy/PlasmaPy/pull/493) | ![Merged](/assets/YnDnRzm.jpeg) | Decorate functions in `collisions.py` with `@particle_input` decorator                                        |
  | [#483](https://github.com/PlasmaPy/PlasmaPy/pull/483) | ![Merged](/assets/YnDnRzm.jpeg) | Accept a tuple or list of Particles for a parameter in a function decorated by `@particle_input`              |
  | [#290](https://github.com/PlasmaPy/PlasmaPy/pull/290) | ![Merged](/assets/YnDnRzm.jpeg) | [Pre-GSoC] Optionally accept integer charges in Roman notations                                               |
  | [#265](https://github.com/PlasmaPy/PlasmaPy/pull/265) | ![Merged](/assets/YnDnRzm.jpeg) | [Pre-GSoC] Move `Particle.reduced_mass` to a module level function                                            |


And we fought against code coverage problems to make CodeCov happy!

  | PR                                                    | Status                                     | Description                                                                                                   |
  |-------------------------------------------------------|--------------------------------------------|---------------------------------------------------------------------------------------------------------------|
  | [#506](https://github.com/PlasmaPy/PlasmaPy/pull/506) | ![Merged](/assets/YnDnRzm.jpeg) | Write tests to improve coverage in various packages                                                           |
  | [#502](https://github.com/PlasmaPy/PlasmaPy/pull/502) | ![Merged](/assets/YnDnRzm.jpeg) | Move `coveragerc` file to expected default location so that it can be read correctly                          |
  | [#498](https://github.com/PlasmaPy/PlasmaPy/pull/498) | ![Merged](/assets/YnDnRzm.jpeg) | Add tests to improve coverage in our langmuir package                                                         |
  | [#494](https://github.com/PlasmaPy/PlasmaPy/pull/494) | ![Merged](/assets/YnDnRzm.jpeg) | Include `__init__.py` in our diagnostics package, so that any tests placed aren't skipped                     |
  | [#320](https://github.com/PlasmaPy/PlasmaPy/pull/320) | ![Merged](/assets/YnDnRzm.jpeg) | Write tests for `PlasmaBlob.regimes()`                                                                        |

We have an astonishing code coverage - 98%! It's great that we were able to keep with our code coverage even after so much going in and out of PlasmaPy.

Then comes the list of all the other stuff I tinkered with during the season!

  | PR                                                    | Status                                     | Description                                                                                                   |
  |-------------------------------------------------------|--------------------------------------------|---------------------------------------------------------------------------------------------------------------|
  | [#513](https://github.com/PlasmaPy/PlasmaPy/pull/513) | ![Merged](/assets/YnDnRzm.jpeg) | Fix conda recipe by including LICENSE.md in MANIFEST.in                                                       |
  | [#511](https://github.com/PlasmaPy/PlasmaPy/pull/511) | ![Merged](/assets/YnDnRzm.jpeg) | Load correct URLs when using `online_help()`                                                                  |
  | [#509](https://github.com/PlasmaPy/PlasmaPy/pull/509) | ![Open](/assets/Mjp2nr7.jpeg)   | Some refactoring of [@tulasinandan's](https://github.com/tulasinandan) work on two fluid dispersion relations |
  | [#360](https://github.com/PlasmaPy/PlasmaPy/pull/360) | ![Merged](/assets/YnDnRzm.jpeg) | Mention `RelativityError` in docstrings when input velocity is same or greater than the speed of light        |
  | [#358](https://github.com/PlasmaPy/PlasmaPy/pull/358) | ![Merged](/assets/YnDnRzm.jpeg) | Return `Quantity` objects correctly formatted when passed to `call_string()`                                  |


During these months, I also got the chance to contribute to [astropy](https://github.com/astropy/astropy/) and [poliastro](https://github.com/poliastro/poliastro) which are also sub-organizations under the the OpenAstronomy umbrella organization.

### astropy

  | PR                                                    | Status                                     | Description                                                                                                   |
  |-------------------------------------------------------|--------------------------------------------|---------------------------------------------------------------------------------------------------------------|
  | [#7673](https://github.com/astropy/astropy/pull/7673) | ![Open](/assets/YnDnRzm.jpeg)   | [Upstream] Fix string Python code to test coverage on Windows which would otherwise result in `SyntaxError`   |
  | [#7672](https://github.com/astropy/astropy/pull/7672) | ![Open](/assets/YnDnRzm.jpeg)   | Accept non-unit type annotations in functions decorated with`@quantity_input` decorator                       |
  | [#7284](https://github.com/astropy/astropy/pull/7284) | ![Closed](/assets/ksGNF55.jpeg) | [Pre-GSoC] Override `HDUList.__add__()` to return a sum of two `HDUList` instances                            |
  | [#7218](https://github.com/astropy/astropy/pull/7218) | ![Open](/assets/YnDnRzm.jpeg)   | [Pre-GSoC] Implement shallow copy and deep copy on an `HDUList` instance                                      |

### poliastro

  | PR                                                      | Status                                     | Description                                                                                                   |
  |---------------------------------------------------------|--------------------------------------------|---------------------------------------------------------------------------------------------------------------|
  | [#312](https://github.com/poliastro/poliastro/pull/312) | ![Open](/assets/YnDnRzm.jpeg)   | [Pre-GSoC] Return a tuple (`Time`, `CartesianRepresentation`) in `Orbit.sample()`                             |

-------------------------------

A lot of other cool stuff happened in these past few months. We went from a [new logo](https://github.com/PlasmaPy/PlasmaPy-logo),

<img src="/assets/with-text-dark.png" width="350">

from no releases to releasing v0.1.1 [on PyPi](https://pypi.org/project/plasmapy/) ([coming soon on conda!](https://github.com/conda-forge/staged-recipes/pull/4793)), from [Coveralls to CodeCov](https://github.com/PlasmaPy/PlasmaPy/pull/490), confirmed that PlasmaPy works great with Python 3.7, to [submitting an abstract](https://agu.confex.com/agu/fm18/preliminaryview.cgi/Paper401465) for the AGU Fall Meeting!

This was one hell of an awesome summer working with [PlasmaPy](https://github.com/PlasmaPy/PlasmaPy) under Google Summer of Code 2018. I want to thank Google and OpenAstronomy (an umbrella organization for PlasmaPy) for giving me this opportunity to work with such an amazing community. A shoutout and a special thanks to my mentors
([Nick Murphy](https://github.com/namurphy), [Drew Leonard](https://github.com/SolarDrew) and [Dominik Stańczak](https://github.com/StanczakDominik)) for guiding me throughout the summer!

And so the wonderful journey comes to an end.

