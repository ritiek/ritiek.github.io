+++
title = "Final GSoC update on musicbrainz_rs"
date = 2021-08-20
path = "2021/08/20/final-gsoc-update-on-musicbrainz-rs"
template = "page.html"
[taxonomies]
tags = []
+++

This post is a follow-up of what I've been working on since my [last post](/2021/07/15/gsoc-with-metabrainz-in-rust/),
for my involvement as a GSoC student with [musicbrainz_rs](https://github.com/oknozor/musicbrainz_rs).

## What we've achieved since then

#### Relationship Level Includes

- We now support requesting for relationship level includes from the web-api.
  These can requested similar to the way how other includes are requested for.
```swift
    let polly = Recording::fetch()
        .id("af40d6b8-58e8-4ca5-9db8-d4fca0b899e2")
        .with_work_relations()
        .with_work_level_relations()
        .execute()
        .unwrap();

    let relations = polly.relations.unwrap();

    assert!(relations.iter().any(|rel| rel.target_type == "work"));
```

#### Search

- We now also have search implemented on most of the entities supported by musicbrainz.
```swift
    use musicbrainz_rs::entity::area::AreaType::*;
    use musicbrainz_rs::entity::area::*;
    use musicbrainz_rs::Search;

    let query = AreaSearchQuery::query_builder()
        .area("London")
        .and()
        .tag("place")
        .build();

    let result = Area::search(query).execute().unwrap();

    assert!(result
        .entities
        .iter()
        .any(|area| area.area_type.as_ref().unwrap() == &City));
```
  The ones still missing the search implementation are the `Place` and `Tag` entity.

  There's some inconsistency in the API response for the `Place` entity which I reported
[here](https://tickets.metabrainz.org/browse/SEARCH-664). We should probably wait before implementing
search on the `Place` entity and see maybe see if this can be resolved from the musicbrainz side
itself otherwise we'll have to workaround this in our library as
[we currently parse the coordinates as `f64`](https://github.com/oknozor/musicbrainz_rs/blob/ae0fd81fecb8897514d9c211ba52650cd1512ab1/src/entity/place.rs#L45-L49)
which fails when attempting to use the same coordinate struct to also parse the search response.

  On the other hand `Tag` entity [requires http digest authentication](https://musicbrainz.org/doc/MusicBrainz_API#Misc_inc.3D_arguments)
which isn't implemented in musicbrainz_rs at the moment. `Tag` search will need to be implemented once
we have authentication up.

These are the main things we worked upon last month. I also fixed some mis-matches with the web-api in
our library, improved docs, and a little bit of refactoring.

All of my PRs made during the GSoC period can be found [here](https://github.com/oknozor/musicbrainz_rs/pulls?q=is%3Apr+author%3Aritiek+created%3A%3C%3D2021-08-23).

## Wrapping up

There are still quite a few things that could be done in musicbrainz_rs as detailed in the
[issues section](https://github.com/oknozor/musicbrainz_rs/issues). Overall, I had a great time working on
musicbrainz_rs these few months and would like to thank [MetaBrainz Foundation](https://metabrainz.org/)
and my mentor, [Paul](https://github.com/oknozor/) for providing me with this opportunity, letting me
take the wheel for a while, and dealing with my cute questions all along the way! I'm starting to feel
a tiny bit more confident in Rust now.

I'd love to contribute to musicbrainz_rs if I get the chance in future, but for now I've got to focus
on other things. My college is over and I'm yet to find out what awaits for the future next!

--------

You can also read a more detailed version of this post and about my final work submission at:

[https://blog.metabrainz.org/2021/08/23/gsoc-2021-complete-rust-binding-for-the-musicbrainz-api/](https://blog.metabrainz.org/2021/08/23/gsoc-2021-complete-rust-binding-for-the-musicbrainz-api/).
