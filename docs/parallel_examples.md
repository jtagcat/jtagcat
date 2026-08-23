## while ls
```
parallel -n1 python3 foobar.py --parse --download {} ::: ../unzip/*
```

One argument at a time, default threads. Argument placed at `{}`, arguments come from bash expansion.

## Command concurrency
```
parallel -j8
```

Limits cuncurrent commands running. Do note,

```
parallel -j8 -n3
```

Runs 24 arguments at once (untested, not fully sure).

## Chained command `&&`
```
find -name '*.wav' | parallel -n1 "ffmpeg -i {} {.}.flac && rm {}"
```

- Quote whole command or escape both ampersands: `\&\&`
- `{.}` removes exactly one file extension: `foo.tar.gz` → `foo.tar`
- `{}` arguments don't need to be quoted

## Collect outputs to per-argument `>` with `\>`
```
cat input.txt | parallel -n1 python argumentful_working_thing.py {} \> ./anagramout/{}.txt
```

## Chained command `;` with `\;`
```
find 0_2021-08-25/ -wholename '*/photos/photo_*' |\
	parallel -n1 echo {}\; diffmv {} '"$(sed -E 's/photo_[0-9]+@//' <<< {})"'
```

`\;` runs within the same parallel universe. Reduces the need to quote the whole line.

## cd in each
```
for d in *; do cd "$d"; parallel unzip ::: '*.zip'; cd ..; done

# unwrapped:
for d in *; do
	cd "$d";
	parallel unzip ::: '*.zip';
	cd ..;
done
```

A bit less parallel, and keeps the working directory local.

## Trust source quotes (jq composed input)
```
jq -r '.id as $cid | .messages[] | if .'"$kind"' then ([($cid|tostring)+"_"+(.id|tostring),.'"$kind"',.file_name?] | @sh) else empty end' chat.json |\
	parallel echo {=uq=}
```
