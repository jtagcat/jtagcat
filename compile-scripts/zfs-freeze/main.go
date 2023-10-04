package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strings"

	"github.com/google/renameio/v2"
	"github.com/jtagcat/util/std"
)

const version = "v1.1.0"

func usage() {
	fmt.Println(
		"zfs-freeze "+version+"\n",
		"\n",
		"Usage:\n",
		"$ "+os.Args[0]+" --help\n",
		"$ "+os.Args[0]+" tank/mydata moon-2023-10-03\n",
		"$ "+os.Args[0]+" --destroy tank/_freeze_mydata/moon-2023-10-03\n",
		"\n",
		"Setup:\n",
		"# chown root:root "+os.Args[0]+"\n",
		"# chmod 4755 "+os.Args[0]+"\n",
	)
	os.Exit(64)
}

func ensureArgCount(want int) {
	if len(os.Args)-1 != want {
		slog.Error("expected exact number of arguments", slog.Int("got", len(os.Args)-1), slog.Int("want", want))
		usage()
	}
}

func main() {
	if os.Geteuid() != 0 {
		slog.Error("Must run with effective UID of root to mount zfs clones", slog.Int("euid", os.Geteuid())) // if anyone knows any other way with zfs allow and alike, lmk
		os.Exit(1)
	}

	ctx := context.Background()
	ctx, _ = signal.NotifyContext(ctx, os.Interrupt)

	if len(os.Args)-1 < 1 {
		usage()
	}
	switch os.Args[1] {
	case "--help":
		usage()
	case "--destroy", "-d":
		ensureArgCount(2)
		if err := Destroy(ctx, os.Args[2]); err != nil {
			err.(std.SlogError).Wrap(slog.LevelInfo, "destroying freeze").LogD()
			os.Exit(1)
		}
	default:
		ensureArgCount(2)
		if err := Freeze(ctx, os.Args[1], os.Args[2]); err != nil {
			err.(std.SlogError).Wrap(slog.LevelInfo, "creating freeze").LogD()
			os.Exit(1)
		}
	}
}

func Freeze(ctx context.Context, targetDataset, freezeName string) error {
	targetParent, targetName, ok := std.RevCut(targetDataset, "/")
	if !ok {
		targetName = targetParent // dataset is top level
	}

	freezeRoot := std.SafeJoin(targetParent, "_freeze_"+targetName, freezeName)

	snapFile := filepath.Join("/", freezeRoot, "snapshot.list")
	if _, err := os.Stat(snapFile); !os.IsNotExist(err) {
		return std.SlogWrap(slog.LevelWarn, "snapshot.list already exists", slog.String("path", snapFile), slog.String("freeze", freezeRoot))
	}

	//

	datasets, err := datasetList(ctx, targetDataset)
	if err != nil {
		return err
	}

	var report string

	for _, dataset := range datasets {
		snap, err := latestSnapshot(ctx, dataset)
		if err != nil {
			return err.(std.SlogError).Wrap(slog.LevelDebug, "getting latest snapshot", slog.String("freeze", freezeRoot))
		}

		snapDestination := std.SafeJoin(freezeRoot, strings.TrimPrefix(dataset, targetDataset))

		_, _, err = std.RunWithStdouts(exec.CommandContext(ctx,
			"zfs", "clone", "--",
			snap, snapDestination,
		), true)

		if err != nil {
			return std.SlogWrap(slog.LevelError, "cloning snapshot", slog.String("snapshot", snap), slog.String("destination", snapDestination), std.SlogNamedErr("zfs clone", err), slog.String("freeze", freezeRoot))
		}

		report += snap + "\n"
	}

	if err := writeReport(snapFile, report); err != nil {
		return err.(std.SlogError).Wrap(slog.LevelInfo, "writing snapshot.list", slog.String("freeze", freezeRoot))
	}

	fmt.Println(freezeRoot)
	return nil
}

func datasetList(ctx context.Context, targetDataset string) ([]string, error) {
	stdout, _, err := std.RunWithStdouts(exec.CommandContext(ctx,
		"zfs", "list", "-H", "-r",
		"-o", "name", "-s", "name",
		"--", targetDataset,
	), true)
	if err != nil {
		return nil, std.SlogWrap(slog.LevelError, "listing dataset", slog.String("target", targetDataset), std.SlogNamedErr("zfs list", err))
	}

	return strings.Split(stdout, "\n"), nil
}

var errNoSnapshots = errors.New("dataset has no snapshots")

func latestSnapshot(ctx context.Context, dataset string) (string, error) {
	stdout, _, err := std.RunWithStdouts(exec.CommandContext(ctx,
		"zfs", "list", "-H",
		"-o", "name", "-S", "creation",
		"-t", "snap",
		"--", dataset,
	), true)
	if err != nil {
		return "", std.SlogWrap(slog.LevelError, "listing snapshots", slog.String("target", dataset), std.SlogNamedErr("zfs list", err))
	}

	if stdout == "" {
		return "", std.SlogWrap(slog.LevelError, "dataset has no snapshos", slog.String("target", dataset))
	}

	return strings.Split(stdout, "\n")[0], nil
}

func writeReport(path string, content string) error {
	snapshotReport, err := renameio.NewPendingFile(path)
	if err != nil {
		return std.SlogWrap(slog.LevelError, "creating file", std.SlogErr(err), slog.String("path", path))
	}

	if _, err := snapshotReport.WriteString(content); err != nil {
		return std.SlogWrap(slog.LevelError, "writing to file", std.SlogErr(err), slog.String("path", path))
	}

	if err := snapshotReport.CloseAtomicallyReplace(); err != nil {
		return std.SlogWrap(slog.LevelError, "atomically replacing file", std.SlogErr(err), slog.String("path", path))
	}

	if err := os.Chown(path, os.Getuid(), os.Getgid()); err != nil {
		return std.SlogWrap(slog.LevelError, "changing file permissions", std.SlogErr(err), slog.String("path", path))
	}

	return nil
}

func Destroy(ctx context.Context, dataset string) error {
	dataset = strings.TrimPrefix(dataset, "/") // allows for specifying path instead of dataset

	_, cutSection, ok1 := strings.Cut(dataset, "/_freeze_")
	beforeCut, afterCut, _ := strings.Cut(cutSection, "/")

	if !ok1 || beforeCut == "" || afterCut == "" {
		return std.SlogWrap(slog.LevelError, "not a freeze: dataset name does not have .../_freeze_*/ as its parent", slog.String("dataset", dataset))
	}

	_, _, err := std.RunWithStdouts(exec.CommandContext(ctx,
		"zfs", "destroy", "-r",
		"--", dataset,
	), true)
	if err != nil {
		return std.SlogWrap(slog.LevelError, "destroying dataset", std.SlogNamedErr("zfs destroy", err), slog.String("dataset", dataset))
	}

	return nil
}
