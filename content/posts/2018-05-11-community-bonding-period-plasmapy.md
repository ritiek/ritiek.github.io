+++
title = "Community Bonding Period"
date = 2018-05-11
path = "2018/05/11/community-bonding-period-plasmapy"
template = "blog/page.html"
[taxonomies]
tags = []
+++

## How I Got Here

I've known about GSoC for a while but wasn't sure if it was something
I could be a part of. I decided to give it my first try this year. I got to know about
OpenAstronomy from the GSoC'18 organizations page. Initially, almost all of the
projects on their ideas page were very appealing to me. I started to get to know more about
different communities under OpenAstronomy and submitted patches to their
codebase to some of them. It was fun to contribute to them but I was still not sure
which organization and what project would work best for me.
After thinking for a while, I decided to settle on the project to develop a better way
of dealing with different types of plasma data structures using metaclasses under the
PlasmaPy organization.

These guys were still progressing to v0.1.0 and to have it up on PyPi. I imagined it
would be nice to give a hand and speed up things a bit as well as this was the
first time I was going to work with Python metaclasses in an actual real-world project,
metaclasses are some nasty Python dark magic! I spent most of march working on a proposal
and invloving with the PlasmaPy community. To my surprise, my proposal got selected for GSoC'18!


## Bonding Period

We're currently in the community bonding phase where I am getting to know more about
our community and my GSoC project. By the way, we also had our v0.1.0 release and
a brand new logo for our organization during this phase. Here is the glimpse of it!

<img src="/assets/graphic-circular.png" width="100">

As for the GSoC project, since PlasmaPy only supports Python 3.6+, it was suggested that
we use a base class that is a subclass of
[`ABC.abc`](https://docs.python.org/3/library/abc.html#abc.ABC) instead of defining
a metaclass. Python 3.6 brought this amazing method
[`__init_subclass__`](https://www.python.org/dev/peps/pep-0487/#subclass-registration)
that would make for a great replacement to register our subclasses.
In the first Jitsi meeting we had yesterday, we discussed about the project and
some stuff about what my mentors are expecting from me.
Our implemenation is supposed to be quite similar to how
[`sunpy.map.Map`](http://docs.sunpy.org/en/stable/code_ref/map.html) works.


## Ending Thoughts

I'm very excited about the journey next 3 months! I'll probably end up learning a
lot more about metaprogamming in Python and in general. I am grateful to OpenAstronomy
and my mentors for giving me this amazing opportunity and helping me get started!
