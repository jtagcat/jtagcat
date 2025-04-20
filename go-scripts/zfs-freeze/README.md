# zfs-freeze

Recursively clones latest snapshots of datasets in a given dataset. This exposes a mounted snapshot of a path, what is useful for backing up ZFS without zfs-send (rclone, rsync).

## Usage
```
go build .
# or without cloning: go install github.com/jtagcat/jtagcat/compile-scripts/zfs-freeze@latest
# → binary will be at $GOPATH/bin/zfs-freeze

sudo chown root:root zfs-freeze
sudo chmod 4755 zfs-freeze
sudo mv zfs-freeze /usr/local/bin

zfs-freeze target/dataset freezename
#: target/_freeze_dataset/freezename

# cleanup:
zfs-freeze --destroy target/_freeze_dataset/freezename
```
