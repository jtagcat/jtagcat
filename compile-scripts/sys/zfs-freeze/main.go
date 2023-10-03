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

func main() {
	if os.Geteuid() != 0 {
		slog.Error("Must run with effective UID of root to mount zfs clones", slog.Int("euid", os.Geteuid()))
		os.Exit(1)
	}

	ctx := context.Background()
	signal.NotifyContext(ctx, os.Interrupt)

	if len(os.Args)-1 < 1 {
		usage()
	}
	switch os.Args[1] {
	case "--help":
		usage()
	case "--destroy", "-d":
		mainDestroy(ctx)
		os.Exit(0)
	}

	argCount := 2
	if len(os.Args)-1 != argCount {
		slog.Error("expected exact number of arguments", slog.Int("got", len(os.Args)-1), slog.Int("want", argCount))
		usage()
	}

	//

	rootDataset := os.Args[1]
	rootParent, rootName, ok := std.RevCut(rootDataset, "/")
	if !ok {
		rootName = rootParent
	}

	destination := std.SafeJoin(rootParent, "_freeze_"+rootName, os.Args[2])

	snapFile := filepath.Join("/", destination, "snapshot.list")
	if _, err := os.Stat(snapFile); !os.IsNotExist(err) {
		slog.Error("preparing snapshot.list", slog.Any("error", "file exists"), slog.String("path", snapFile))
		os.Exit(1)
	}

	//

	datasets, err := datasetList(ctx, rootDataset)
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

		snapDestination := std.SafeJoin(destination, strings.TrimPrefix(dataset, rootDataset))

		if err := cloneSnapshot(ctx, snap, snapDestination); err != nil {
			slog.Error("cloning snapshot", slog.Any("zfs clone", err.Error()), slog.String("snapshot", snap), slog.String("destination", snapDestination))
			os.Exit(1)
		}

		report += snap + "\n"
	}

	snapshotReport, err := renameio.NewPendingFile(snapFile)
	if err != nil {
		slog.Error("creating snapshot.list", slog.Any("error", err.Error()), slog.String("path", snapFile))
		os.Exit(1)
	}

	if _, err := snapshotReport.WriteString(report); err != nil {
		slog.Error("writing to snapshot.list", slog.Any("error", err.Error()), slog.String("path", snapshotReport.Name()))
		os.Exit(1)
	}

	if err := snapshotReport.CloseAtomicallyReplace(); err != nil {
		slog.Error("writing snapshot.list", slog.Any("error", err.Error()), slog.String("path", snapFile))
		os.Exit(1)
	}

	if err := os.Chown(snapFile, os.Getuid(), os.Getgid()); err != nil {
		slog.Error("changing permissions for snapshot.list", slog.Any("error", err.Error()), slog.String("path", snapFile))
		os.Exit(1)
	}

	fmt.Println(destination)
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

func mainDestroy(ctx context.Context) {
	argCount := 1
	if len(os.Args)-1-1 != argCount {
		slog.Error("expected exact number of arguments", slog.Int("got", len(os.Args)-1), slog.Int("want", argCount))
		usage()
	}

	dataset := os.Args[2]
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
