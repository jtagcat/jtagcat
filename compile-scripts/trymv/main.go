package main

import (
	"bytes"
	"crypto/sha256"
	"fmt"
	"io"
	"io/fs"
	"log/slog"
	"os"
	"path/filepath"
	"strconv"
)

func usage() {
	fmt.Printf(
		"Merge duplicate directories while keeping the conflicts.\n"+
			"\n"+
			"USAGE: %s <source> <dest>\n", os.Args[0])

	os.Exit(64)
}

func main() {
	if ok, _ := strconv.ParseBool(os.Getenv("DEBUG")); ok {
		h := slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: slog.LevelDebug})
		slog.SetDefault(slog.New(h))
	}

	if len(os.Args)-1 != 2 {
		fmt.Printf("ERROR: Expected exactly 2 arguments\n")
		usage()
	}

	srcRoot, dstRoot := os.Args[1], os.Args[2]

	if err := walk(srcRoot, dstRoot); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func walk(srcAbs, dstAbs string) error {
	slog.Debug("walking", slog.String("src", srcAbs))

	srcInfo, err := os.Stat(srcAbs)
	if err != nil {
		return err
	}

	dstInfo, err := os.Stat(dstAbs)
	if err != nil {
		if os.IsNotExist(err) {
			slog.Debug("moving", slog.String("src", srcAbs))
			return os.Rename(srcAbs, dstAbs)
		}

		return err
	}

	if !srcInfo.IsDir() {
		slog.Debug("comparing", slog.String("src", srcAbs))
		if err := diff(srcAbs, dstAbs, srcInfo, dstInfo); err != nil {
			return fmt.Errorf("file differs: %s: %w", srcAbs, err) // TODO: can we get rel?
		}

		slog.Debug("removing", slog.String("src", srcAbs))
		return os.Remove(srcAbs)
	}

	slog.Debug("listing", slog.String("src", srcAbs))
	listing, err := os.ReadDir(srcAbs)
	if err != nil {
		return err
	}

	var keepDir bool
	for _, srcChild := range listing {
		if err := walk(filepath.Join(srcAbs, srcChild.Name()), filepath.Join(dstAbs, srcChild.Name())); err != nil {
			keepDir = true
			slog.Error("child:", slog.String("err", err.Error()))
		}
	}

	if keepDir {
		slog.Debug("skipping dir removal", slog.String("src", srcAbs))
		return nil
	} else {
		slog.Debug("removing dir", slog.String("src", srcAbs))
		return os.Remove(srcAbs)
	}
}

func diff(srcAbs, dstAbs string, srcInfo, dstInfo fs.FileInfo) error {
	if srcInfo.Size() != dstInfo.Size() {
		return fmt.Errorf("size mismatch: %d in source, %d in destination", srcInfo.Size(), dstInfo.Size())
	}

	// TODO:
	// if srcInfo.ModTime() != dstInfo.ModTime() {
	// 	return fmt.Errorf("modtime mismatch: %v in source, %v in destination", srcInfo.ModTime(), dstInfo.ModTime())
	// }

	srcSum, err := sum(srcAbs)
	if err != nil {
		return fmt.Errorf("summing source: %w", err)
	}

	dstSum, err := sum(dstAbs)
	if err != nil {
		return fmt.Errorf("summing destination: %w", err)
	}

	if !bytes.Equal(srcSum, dstSum) {
		return fmt.Errorf("sha256 mismatch: %x in source, %x in destination", srcSum, dstSum)
	}

	return nil
}

func sum(name string) ([]byte, error) {
	f, err := os.Open(name)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return nil, err
	}

	return h.Sum(nil), nil
}
