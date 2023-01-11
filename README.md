# LunchQuest

## An overscoped and overengineered take home test.

And so it came to pass that as I was looking for my next source of income I approached a certain company —that I
actually like— and asked for an opportunity to interview for an open position they had.

And they said "sure, but first you'll have to build us this sample app". And I looked at the sample app and said
"_are you kidding me_". And they probably would have let me get around it but it wasn't a good fit for where I stood in
my career and had a better offer already so I politely declined.

But I wanted to try out building some reusable components and needed a not-too-complex app to try them out, so I ended
up building the app anyway.

## The App

The application will request access to the user's location during use on first launch and perform a search of
restaurants around it. The user can input search terms in the search field to fine tune what restaurants show up in the
search (i.e. "pizza").

The results are shown in a list by default but can be displayed on a map as well. In either type of display tapping on
an entry (list row or map pin) will display a detail view with whatever I saw Google API actually returning from place
calls.

## The Extra Bits

A few reusable components saw their first prototyping with this app:

- SwiftUX: I had been playing with the idea of building reusable controller types inspired by my work at Tome, the old
macOS `NSController` KVO-based classes and some fashionable libraries like redux and the action bits of TCA for a while.
This was a good opportunity to fine tune the idea to its cleanest expression —or close enough to it— with the hope that
I can rebuild the additional complexity on future work. It needs a small adapter to work with `SwiftUI` which I left
off the basic classes as having it around tended to confuse things.

- SwiftCache: Everyone wants an image cache, everyone reinvents the image caching wheel. So do I! But I overkilled it in
a multilayered data pipeline system that just incidentally is pretty good at caches. The one used in this app is the
MVP version, but most of the enhancements can be built on top of this structure just within the layered components.

- ImageLoadingView: Contained within `Iutilitis` (it will probably see its own package at some point) this is a good,
if still too simple, replacement for `SDWebImage` facilities and other similar tools. I included placeholder image
support and I believe it would be generally usable with some additional configurability, better testing coverage and
better documentation. But the added logic to `UIImageView` is solid and should also work well enough for a `NSImageView`
enhancement.
