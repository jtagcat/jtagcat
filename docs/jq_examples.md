### Add a static key-value to all objects in an array.

#### Input
```json
[
  {
    "endTime": "2021-03-19 00:13",
    "msPlayed": 91274
  },
  {
    "endTime": "2021-03-19 00:14",
    "msPlayed": 37797
  },
  {
    "endTime": "2021-03-19 00:15",
    "msPlayed": 0
  }
]
```

#### Command
```sh
jq '.[] + {"sourceId": 5}'
```

#### Output
```json
{
  "endTime": "2021-03-19 00:13",
  "msPlayed": 91274,
  "sourceId": 5
}
{
  "endTime": "2021-03-19 00:14",
  "msPlayed": 37797,
  "sourceId": 5
}
{
  "endTime": "2021-03-19 00:15",
  "msPlayed": 0,
  "sourceId": 5
}
```

### Construct an object with new key names and processing
[spotifytakeout_listenbrainz_streaminghistory.sh](../scripts/music/spotifytakeout_listenbrainz_streaminghistory.sh)

#### Input
```json
[
  {
    "endTime": "2021-03-19 00:07",
    "trackName": "Maria durch ein Dornwald ging",
    "msPlayed": 0,
    "artist_name": "Heinrich Kaminski"
  },
  {
    "endTime": "2021-03-19 00:07",
    "trackName": "Make We Joy In This Fest (Trad. Carol)",
    "msPlayed": 0,
    "artist_name": "William Walton"
  }
]
```

#### Command
```sh
jq '{"listen_type": "import", "payload": (.[] |= {"listened_at": (.endTime | split (" ") | .[0] + "T" + .[1] + ":00Z" | fromdateiso8601),'\
'"track_metadata": {"additional_info":{"listening_from":"spotify"}, "artist_name": .artistName, "track_name": .trackName } })}'
```


#### Output
```json
{
  "listen_type": "import",
  "payload": [
      {
        "listened_at": 1616112420,
        "track_metadata": {
          "additional_info": {
            "listening_from": "spotify"
          },
          "artist_name": "Heinrich Kaminski",
          "track_name": "Maria durch ein Dornwald ging"
        }
      },
      {
        "listened_at": 1616112420,
        "track_metadata": {
          "additional_info": {
            "listening_from": "spotify"
          },
          "artist_name": "William Walton",
          "track_name": "Make We Joy In This Fest (Trad. Carol)"
        }
      }
    ]
}
```

### Split to multiple files with filename from key; move 
[stg-versioning.sh](../scripts/stg/stg-versioning.sh)


#### Input

#TODO:

#### Command
```sh
jq --compact-output --raw-output '(del(.groups)) as $parent|.groups[]|{"filename":"\(.id).json","content":(.}|"\(.filename):\(.content)"' "$INPUTDIR/$backupinput" |\
grep -v '^ *#' | while IFS=: read -r filename content
do
  base64 -d <<< "$content" | jq '{"tabs":(.tabs | sort_by(.id))} + del(.tabs) | del(.tabs[].id)' > "$OUT/$filename" # sort by id, then get rid of the id
done
```

#### Output

#TODO:

### Get top-level keys of an object
#### Input
```json
{
  "listened_at": 1616112420,
  "track_metadata": {
    "additional_info": {
      "listening_from": "spotify"
    },
    "artist_name": "Heinrich Kaminski",
    "track_name": "Maria durch ein Dornwald ging"
  }
}
```
#### Command
```sh
jq 'keys'
```
#### Output
```json
[
  "listened_at",
  "track_metadata"
]
```
