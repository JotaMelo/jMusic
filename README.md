# jMusic

This is the most up to date source code for the jMusic app. It contains features never released to the App Store like multi-playlist import (which hasn't been extensively tested but mostly works).

## Authentication

The app interacts with two APIs: Spotify and Apple Music.

### Spotify

Go to https://developer.spotify.com/ to create an app and fill out the client ID and client secret on `SpotifyAPI.swift`

### Apple Music

The Apple Music API uses JWT (JSON Web Token) for authentication, and these tokens have an expiration date (max 6 months). Currently the app has a backend to generate these tokens, and if by any chance that request fails there's a hardcoded "last resort" token in the app. This logic can be found on the `TokenManager` class, declared in `AppleMusicService.swift`.

The fastest way to get the app running is to generate your own "last resort" token and insert it on the `Constants.swift` file. There's a Python script on the root of the project that can be used to generate a new token, which has two dependencies:

```
sudo pip install PyJWT==1.5.3
sudo pip install cryptography==2.0.3
```

You also need a MusicKit private key ([instructions here](https://developer.apple.com/library/content/documentation/NetworkingInternetWeb/Conceptual/AppleMusicWebServicesReference/SetUpWebServices.html)) and your team ID.

Usage:
```
python JWTGenerator.py /path/to/key/AuthKey_SI2I3O2.p8
```

## App Store Description

Apple Music is great, but you sure do miss all the great playlists people create on Spotify don't you?
That's where jMusic comes in.

jMusic helps you transfer any Spotify playlist (either from your account or an URL) to Apple Music without adding the songs to your main library, so it doesn't make a mess of things.

The process is simple:
- Login to Spotify
- Select the playlist or paste the playlist's URL
- Select the tracks to be imported (it has a Select All button, don't worry)
- Wait
- Smile

You can even leave the app while jMusic does all the magic. iOS allows apps to run in the background for 3 to 5 minutes. In my tests, that's enough for about 40 songs.
If your import takes longer than that, jMusic will notify you so you can open the app to "renew" the time. It'll also notify you when the import finishes, so be sure to allow for notifications (I won't bother you, really).

If you have any feedback or suggestions, please email me, I'll answer!
You can find the link in the About menu in the app.

## Author

[Jota Melo](https://twitter.com/Jota), jpmfagundes@gmail.com

## License

jMusic is available under the MIT license. See the LICENSE file for more info.
