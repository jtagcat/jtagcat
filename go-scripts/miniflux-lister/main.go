package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"time"

	"k8s.io/apimachinery/pkg/util/wait"
)

const (
	ENVPREFIX    = "YTLISTER_"
	MAX_PER_FILE = 6
)

func main() {
	duration, durationUnparsed := time.Duration(0), os.Getenv(ENVPREFIX+"LOOPDURATION")
	if durationUnparsed != "" {
		var err error
		duration, err = time.ParseDuration(durationUnparsed)
		if err != nil {
			log.Fatalf("parsing loop duration: %e", err)
		}
	}

	ctx := context.Background()
	ctx, cancel := context.WithCancel(ctx)

	signalChan := make(chan os.Signal, 1)
	signal.Notify(signalChan, os.Interrupt)
	defer func() {
		signal.Stop(signalChan)
		cancel()
	}()

	go func() {
		select {
		case <-signalChan: // first signal, cancel context
			os.Stderr.WriteString("Signal relayed, press ^C again to kill.")
			cancel()
		case <-ctx.Done():
		}
		<-signalChan // second signal, hard exit
		os.Stderr.WriteString("Killing...")
		os.Exit(2)
	}()

	mainLoop()

	if duration <= 0 {
		return
	}

	wait.Until(mainLoop, duration, ctx.Done())
}
