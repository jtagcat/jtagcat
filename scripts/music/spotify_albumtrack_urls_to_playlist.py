# .envrc:
# export SPOTIPY_CLIENT_ID=
# export SPOTIPY_CLIENT_SECRET=
# export SPOTIPY_REDIRECT_URI=http://localhost:8080

PLAYLIST_ID = ""

import sys
import spotipy
from spotipy.oauth2 import SpotifyOAuth

sp = spotipy.Spotify(auth_manager=SpotifyOAuth(scope="playlist-modify-private"))

total = 0
for line in sys.stdin:
    if line == "":
        continue

    print("adding "+line)
    tracks = []

    if line.startswith("https://open.spotify.com/album"):
            album = sp.album(line)

            if album['total_tracks'] > 50:
                print(line + " has more than 50 items, pagination not implemented")
                exit(1)
    
            for item in album['tracks']['items']:
                tracks.append(item['uri'])

    elif line.startswith("https://open.spotify.com/track"):
        tracks.append(line)
    else:
        print("unknown spotipie url: "+line)
        exit(1)

    total += len(tracks)
    sp.playlist_add_items(PLAYLIST_ID, tracks)

print("total: "+str(total))
