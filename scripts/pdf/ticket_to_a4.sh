#!/bin/bash
echo open and edit me

export in=small.pdf
pdfjam --page a4paper `# trap: a4 (invalid?) != a4paper (what you want)`\
  --landscape `# trap: you want --no-landscape`\
  --nup 2x4 \
  $(printf "${in}%.0s" {1..8}) `# 2x4=8` \
  --delta '5mm 5mm' `# it would be nice if it would oppurtunistically hug the page sides automatically, by default it centers..?` \
  -o output.pdf

# --pagecolor 0,0,0 # for black bg (0..255 RGB)

# To rotate the logical pages use the ‘angle’ option (e.g. ‘--angle 90’).
