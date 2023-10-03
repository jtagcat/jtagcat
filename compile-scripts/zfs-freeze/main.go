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

const version = "v1.0.0"

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
	signal.NotifyContext(ctx, os.Interrupt)

	ensureArgCount(1)
	switch os.Args[1] {
	case "--help":
		usage()
	case "--destroy", "-d":
		ensureArgCount(2)
		Destroy(ctx, os.Args[2])
	default:
		ensureArgCount(2)
		Freeze(ctx, os.Args[1], os.Args[2])
	}
}

func Freeze(ctx context.Context, targetDataset, freezeName string) {
	targetParent, targetName, ok := std.RevCut(targetDataset, "/")
	if !ok {
		targetName = targetParent // dataset is top level
	}

	freezeRoot := std.SafeJoin(targetParent, "_freeze_"+targetName, freezeName)

	snapFile := filepath.Join("/", freezeRoot, "snapshot.list")
	if _, err := os.Stat(snapFile); !os.IsNotExist(err) {
		slog.Error("preparing snapshot.list", slog.Any("error", "file exists"), slog.String("path", snapFile))
		os.Exit(1)
	}

	//

	datasets, err := datasetList(ctx, targetDataset)
	if err != nil {
		slog.Error("listing target datasets", slog.Any("zfs list", err.Error()))
		os.Exit(1)
	}

	var report string

	for _, dataset := range datasets {
		snap, err := latestSnapshot(ctx, dataset)
		if err != nil {
			slog.Error("getting latest snapshot", slog.Any("zfs list", err.Error()), slog.String("dataset", dataset))
			os.Exit(1)
		}

		snapDestination := std.SafeJoin(freezeRoot, strings.TrimPrefix(dataset, targetDataset))

		if err := cloneSnapshot(ctx, snap, snapDestination); err != nil {
			slog.Error("cloning snapshot", slog.Any("zfs clone", err.Error()), slog.String("snapshot", snap), slog.String("destination", snapDestination))
			os.Exit(1)
		}

		report += snap + "\n"
	}

	if err := writeReport(snapFile, report); err != nil {
		slog.Error("writing snapshot.list", slog.Any("error", err.Error()), slog.String("path", snapFile))
		os.Exit(1)
	}

	fmt.Println(freezeRoot)
}

func datasetList(ctx context.Context, root_dataset string) ([]string, error) {
	stdout, _, err := std.RunWithStdouts(exec.CommandContext(ctx,
		"zfs", "list", "-H", "-r",
		"-o", "name", "-s", "name",
		"--", root_dataset,
	), true)
	if err != nil {
		return nil, err
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
		return "", err
	}

	if stdout == "" {
		return "", errNoSnapshots
	}

	return strings.Split(stdout, "\n")[0], nil
}

func cloneSnapshot(ctx context.Context, snapshot, target string) error {
	_, _, err := std.RunWithStdouts(exec.CommandContext(ctx,
		"zfs", "clone", "--",
		snapshot, target,
	), true)

	return err
}

func writeReport(name string, content string) error {
	snapshotReport, err := renameio.NewPendingFile(name)
	if err != nil {
		return err
	}

	if _, err := snapshotReport.WriteString(content); err != nil {
		return err
	}

	if err := snapshotReport.CloseAtomicallyReplace(); err != nil {
		return err
	}

	if err := os.Chown(name, os.Getuid(), os.Getgid()); err != nil {
		return err
	}

	return nil
}

func Destroy(ctx context.Context, dataset string) {
	argCount := 1
	if len(os.Args)-1-1 != argCount {
		slog.Error("expected exact number of arguments", slog.Int("got", len(os.Args)-1), slog.Int("want", argCount))
		usage()
	}

	_, cutSection, ok1 := strings.Cut(dataset, "/_freeze_")
	beforeCut, afterCut, _ := strings.Cut(cutSection, "/")

	if !ok1 || beforeCut == "" || afterCut == "" {
		slog.Error("dataset name does not have authorized .../_freeze_*/ as its parent", slog.String("dataset", dataset))
		os.Exit(1)
	}

	_, _, err := std.RunWithStdouts(exec.CommandContext(ctx,
		"zfs", "destroy", "-r",
		"--", dataset,
	), true)
	if err != nil {
		slog.Error("destroying dataset", slog.Any("error", err.Error()), slog.String("dataset", dataset))
		os.Exit(1)
	}
}
