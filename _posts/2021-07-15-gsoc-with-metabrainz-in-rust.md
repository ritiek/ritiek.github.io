---
title: 'GSoC with MetaBrainz (in Rust!)'
date: 2021-07-15
layout: post
comments: false
tags:
  - metabrainz
  - musicbrainz
  - rust
  - gsoc
---

So, my GSoC project proposal got selected this year! I've been working with the
[MetaBrainz Foundation](https://metabrainz.org/) on extending the Rust wrapper around
the MusicBrainz Web-API, named [musicbrainz_rs](https://github.com/oknozor/musicbrainz_rs).

For all the folks who have no idea what [MusicBrainz](https://musicbrainz.org/) is -
MusicBrainz is an openly accessible database maintained by the community, which contains
records on music metadata. If you've ever worked with the Spotify Web-API, you'll know
you can make API calls to access information on some of the metadata on artists, albums
and songs that Spotify exposes. MusicBrainz has been built on the same idea with a laser
focus only on music metadata (unlike Spotify, where you can also control music playback
through their API) and offers a lot more detail on this metadata compared to other
services like Spotify.


## Accessing the metadata

You can go right now and explore this metadata through [their web search](https://musicbrainz.org/search)!
For the context, let's say we look up on the music artist Green Day, we'll get to the [artist's page](https://musicbrainz.org/artist/084308bd-1654-436f-ba03-df6697104e19),
neatly showcasing the albums that the artist has released. If you look at this page's URL,
you'll notice this long alphanumeric string - `084308bd-1654-436f-ba03-df6697104e19`. This is
the artist's MBID (short for MusicBrainz ID). MusicBrainz supports [many entities](https://musicbrainz.org/doc/MusicBrainz_Entity)
and every entity is associated with a unique MBID. So, every artist, track, or any other
entity in MusicBrainz is associated with a unique MBID.

You can even download the complete database onto your local disk from
[here](https://musicbrainz.org/doc/MusicBrainz_Database), anytime!


### The Web-API

MusicBrainz also offers a [Web-API](https://musicbrainz.org/doc/MusicBrainz_API) to
programatically access this metadata. Let's say to access metadata for the artist Green Day
through the API, you'll need to know the artist's MBID (which we already have from the
last section) and then make a GET request to the endpoint:<br>
[https://musicbrainz.org/ws/2/artist/084308bd-1654-436f-ba03-df6697104e19](https://musicbrainz.org/ws/2/artist/084308bd-1654-436f-ba03-df6697104e19)

You'll notice that we're missing a lot of information here compared to what we saw in the web
interface in the last section. This is because the API returns minimal information by default.
You need to pass additional parameters to access any further information.

Let's say to also access the artist's albums (which is termed as `release-groups` in MusicBrainz) -
we pass `?inc=release-groups` when making the request:<br>
[https://musicbrainz.org/ws/2/artist/084308bd-1654-436f-ba03-df6697104e19?inc=release-groups](https://musicbrainz.org/ws/2/artist/084308bd-1654-436f-ba03-df6697104e19?inc=release-groups)

See [Subqueries](https://musicbrainz.org/doc/MusicBrainz_API#Subqueries) for the complete list
of supported parameters. There are many more things that you can do through the Web-API (see the [API documentation](https://musicbrainz.org/doc/MusicBrainz_API)).
I won't be covering them here.


### Language libraries

People have created library wrappers around the Web-API for many programming languages. The list
of recognized of libraries can be found [here](https://musicbrainz.org/doc/MusicBrainz_API#Libraries),
and this is where I come in. This summer, I've been working on one such library for the Rust
programming language, named [musicbrainz_rs](https://github.com/oknozor/musicbrainz_rs).

For example, you can make queries using musicbrainz_rs this way:
```swift
extern crate musicbrainz_rs;

use musicbrainz_rs::entity::artist::Artist;
use musicbrainz_rs::prelude::*;

fn main() {
    let green_day = Artist::fetch()
        .id("084308bd-1654-436f-ba03-df6697104e19")
        .with_release_groups()
        .execute()
        .unwrap();

    let release_groups = green_day.release_groups.unwrap();

    assert!(release_groups
        .iter()
        .any(|release_group| release_group.title == "Dookie"));
}
```

musicbrainz_rs isn't listed as a recognized library by MusicBrainz, since the library does
not completely wrap around the Web-API at the moment. Off the top of my head, we're mainly missing
on Non-MBID Lookups, Search and Submitting Data.
There are also parts of the library that need to be addressed before it being suitable for use in
production. Anyway, I've been working with Paul (creator of musicbrainz_rs) to build new features in the library.
We've had some cool things going on since the last month, which I'll talk about in the next sections!

#### Coverart

- The library can now fetch for coverart for the release and release-group entities. An
example covering all of these methods can be found in - [fetch_release_coverart.rs](https://github.com/oknozor/musicbrainz_rs/blob/648215ad5e7661ac48016c9627507818c8345928/examples/fetch_release_coverart.rs).
<br><br>

#### Auto-retries

- The library will now auto-retry on queries failed due to rate-limiting by the MusicBrainz
servers. In case of a failed query due to rate-limiting, we're returned with the time duration in the
response header until the next query would be accepted the MusicBrainz servers. The library
now automatically sleeps the current thread for this received duration and retries the
query by default. The default is set to 2 retries per failed query and this can be changed with:
```swift
musicbrainz_rs::config::set_default_retries(3);
```

- We've also previously had trouble running our test-suite due to this. Our test-suite is
constantly making queries to MusicBrainz servers and the queries would start to fail after
a while. So we had ugly hacks in-place to get our test-suite to pass. We had introduced
a one second sleep in our test-suite after every call to the MusicBrainz servers to not trigger
their rate-limitations, and this had been greatly increasing our test-suite run times. I'm glad
this is no longer the case after introducing auto-retries!
<br><br>

#### Relationship Includes

- I mentioned earlier about how we can request for additional information when making queries
by passing the `?inc=` subquery parameter. Relationship includes can be considered as one such
category of parameters that can be passed to `?inc=`.

- I've been involved with refactoring the already implemented subquery include parameters
and further implemented the relationship include parameters. This involved some manual
work on my part to figure out what include parameters are accepted by what entities
(since this doesn't seem to have been documented [in the docs](https://musicbrainz.org/doc/MusicBrainz_API#Relationships)
and I couldn't find it anywhere else either). Anyway, requests to relationship
includes can now be made simliar to how subquery includes are requested for:

- ~~(This hasn't been merged into the main codebase yet, we'll get there soon!)~~ We're there now!
```swift
    let ninja_tune = Label::fetch()
        .id("dc940013-b8a8-4362-a465-291026c04b42")
        .with_recording_relations()
        .execute()
        .unwrap();

    let relations = ninja_tune.relations.unwrap();

    assert!(relations
        .iter()
        .any(|rel| rel.relation_type == "phonographic copyright"));
```


## This is fun!

I've been enjoying so far. This GSoC has given me a chance to extend the reaches of MusicBrainz
to Rust and also get better at writing Rust code, something that I've always been excited about
ever since I first tried it out. :P

I'm happy I got this opportunity. Thank you, Paul, and the MetaBrainz Foundation!
