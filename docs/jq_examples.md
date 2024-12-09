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
jq '.[] += {"sourceId": 5}'
```

#### Output
```json
[
  {
    "endTime": "2021-03-19 00:13",
    "msPlayed": 91274,
    "sourceId": 5
  },
  {
    "endTime": "2021-03-19 00:14",
    "msPlayed": 37797,
    "sourceId": 5
  },
  {
    "endTime": "2021-03-19 00:15",
    "msPlayed": 0,
    "sourceId": 5
  }
]
```

### Add a dynamic key-value to all objects in an array.

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
jq '.[] |= . + {"sourceId": (.msPlayed*2)}'
```

#### Output
```json
[
  {
    "endTime": "2021-03-19 00:13",
    "msPlayed": 91274,
    "sourceId": 182548
  },
  {
    "endTime": "2021-03-19 00:14",
    "msPlayed": 37797,
    "sourceId": 75594
  },
  {
    "endTime": "2021-03-19 00:15",
    "msPlayed": 0,
    "sourceId": 0
  }
]
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

### Construct an object from array, alternative
#### Input
```json
[
  {
    "@starttime": "1700662366",
    "@endtime": "1700662673",
    "address": {
      "@addr": "99.99.99.99",
      "@addrtype": "ipv4"
    },
    "hostnames": {
      "hostname": [
        {
          "@name": "test.ee",
          "@type": "user"
        },
        {
          "@name": "pest.ee",
          "@type": "PTR"
        }
      ]
    }
  },
  {
    "@starttime": "1700662366",
    "@endtime": "1700662673",
    "address": {
      "@addr": "99.99.99.88",
      "@addrtype": "ipv4"
    },
    "hostnames": {
      "hostname": [
        {
          "@name": "kest.ee",
          "@type": "user"
        },
        {
          "@name": "sest.ee",
          "@type": "PTR"
        }
      ]
    }
  }
]
```

#### Command
```sh
jq '[.[] | {"addr": .address."@addr", "hostnames": [.hostnames.hostname[]."@name"?] }]'
```

#### Output
```json
[
  {
    "addr": "99.99.99.99",
    "hostnames": [
      "test.ee",
      "pest.ee"
    ]
  },
  {
    "addr": "99.99.99.88",
    "hostnames": [
      "kest.ee",
      "sest.ee"
    ]
  }
]
```

### Split to multiple files with filename from key
#### Input
```json
[
  {
    "id": "bar",
    "endTime": "2021-03-19 00:13",
    "msPlayed": 91274
  },
  {
    "id": "dar",
    "endTime": "2021-03-19 00:14",
    "msPlayed": 37797
  },
  {
    "id": "foo",
    "endTime": "2021-03-19 00:15",
    "msPlayed": 0
  }
]
```
#### Command
```sh
jq -r '.[] | (.id +"¤"+ (del(.id)|@base64) )' |\
while IFS=¤ read -r filename content; do
  base64 -d <<< "$content" | sed '$a\' > "$filename" # sed: end file with \n
done
```
#### Output
```sh
$ cat foo bar dar
foo
{"endTime":"2021-03-19 00:15","msPlayed":0}
bar
{"endTime":"2021-03-19 00:13","msPlayed":91274}
dar
{"endTime":"2021-03-19 00:14","msPlayed":37797}
```

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

### Filter, select a subset of keys
#### Input
```json
[
  {
    "junk": "bar",
    "endTime": "2021-03-19 00:13",
    "msPlayed": 91274
  },
  {
    "junk": "dar",
    "endTime": "2021-03-19 00:14",
    "msPlayed": 37797
  },
  {
    "garbage": "foo",
    "endTime": "2021-03-19 00:15",
    "msPlayed": 0
  }
]
```
#### Command
```sh
jq '[.[] | {endTime, msPlayed}]'
```

jq 1.7:
```sh
jq 'pick(.endTime, .msPlayed)'
```

#### Output
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

### Convert array (slice) to map:
#### Input
```json
[
    { "id": "bar",
      "msPlayed": 91274
    },
    { "id": "dar",
      "msPlayed": 37797
    },
    { "id": "foo",
      "msPlayed": 0
    }
]
```
#### Command
```sh
jq '[.[] | {key:.id, value:del(.id)}] | from_entries'
```
#### Output
```json
{
  "bar": {
    "msPlayed": 91274
  },
  "dar": {
    "msPlayed": 37797
  },
  "foo": {
    "msPlayed": 0
  }
}
```

### Convert map to array
(Get value of map parent; Getting value of map parent; Get key; Getting key)
#### Input
```json
{
    "bar": {
      "msPlayed": 91274
    },
    "dar": {
      "msPlayed": 37797
    },
    "foo": {
      "msPlayed": 0
    }
}
```
#### Command
```sh
jq '[to_entries[] | {parent: .key} + .value]'
```
#### Output
```json
[
  {
    "parent": "bar",
    "msPlayed": 91274
  },
  {
    "parent": "dar",
    "msPlayed": 37797
  },
  {
    "parent": "foo",
    "msPlayed": 0
  }
]
```

### Set a field to map with key
#### Input
```json
{
    "bar": {
      "msPlayed": 91274
    },
    "dar": {
      "msPlayed": 37797
    },
    "foo": {
      "msPlayed": 0
    }
}
```
#### Command
```sh
jq --arg key "bar" --arg val "hello"  '. * {($key): {"myValue": $val, "msPlayed": 5} }'
```
#### Output
```json
{
  "bar": {
    "msPlayed": 5,
    "myValue": "hello"
  },
  "dar": {
    "msPlayed": 37797
  },
  "foo": {
    "msPlayed": 0
  }
}
```

### Merge arrays
#### Input
```json
{
  "a": [
    {
      "hello": null
    }
  ],
  "b": [
    {
      "world": null
    }
  ]
}
```
#### Command
```sh
jq '[ .a[] , .b[] ]'
```
#### Output
```json
[
  {
    "hello": null
  },
  {
    "world": null
  }
]
```

### Format values
#### Input
```json
{
  "a": "hello",
  "b": {
    "c": "world"
  }
}
```
#### Command
```sh
jq -r '"\(.a) \(.b.c)!"'
```
#### Output
```plain
hello world!
```
