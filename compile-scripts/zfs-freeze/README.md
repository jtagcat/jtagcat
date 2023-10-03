# zfs-freeze

Recursively clones latest snapshots of datasets in a given dataset. This exposes a mounted snapshot of a path, what is useful for backing up ZFS without zfs-send (rclone, rsync).

## Usage
```
go build .
sudo chown root:root zfs-freeze
sudo chmod 4755 zfs-freeze
sudo mv zfs-freeze /usr/local/bin

zfs-freeze target/dataset freezename
#: target/_freeze_dataset/freezename

# cleanup:
zfs-freeze --destroy target/_freeze_dataset/freezename
```
