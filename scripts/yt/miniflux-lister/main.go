package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"path"
	"strings"
	"time"

	"github.com/google/renameio/v2"
	miniflux "miniflux.app/client"
)

const ENVPREFIX = "YTLISTER_"

func main() {
	// os.Exit with 2 on hard kill
	// does not exits on error
	// inspired from https://pace.dev/blog/2020/02/17/repond-to-ctrl-c-interrupt-signals-gracefully-with-context-in-golang-by-mat-ryer.html

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

	for {
		timer := time.NewTimer(duration)

		select {
		case <-timer.C:
		case <-ctx.Done():
			return
		}

		mainLoop()
	}
}

func mainLoop() {
	outdir := os.Getenv(ENVPREFIX + "OUTDIR")
	if outdir == "" {
		log.Fatal(ENVPREFIX + "OUTDIR env variable is empty")
	}
	endpoint, token := os.Getenv(ENVPREFIX+"MINIFLUX_ENDPOINT"), os.Getenv(ENVPREFIX+"MINIFLUX_TOKEN")
	endpoint = strings.TrimSuffix(strings.TrimSuffix(endpoint, "/"), "/v1") // https://github.com/miniflux/v2/pull/1582
	c := miniflux.New(endpoint, token)

	me, err := c.Me()
	if err != nil {
		log.Fatal("error authenticating: %w", err)
	}
	log.Printf("Authenticated as %s", me.Username)

	feeds, err := c.Feeds()
	if err != nil {
		log.Fatal("error getting feeds: %w", err)
	}

	// programmer hardcoding like hell

	ytFeeds := processFeeds(c, feeds)

	catMap := make(map[string]*renameio.PendingFile)
	for _, fp := range ytFeeds {
		category := strings.ToLower(fp.feed.Category.Title)
		if !strings.HasPrefix(category, "yt/") {
			continue
		}
		category = strings.TrimPrefix(category, "yt/")

		appendable, archiveIt := useTags(fp.tags)
		if !archiveIt {
			continue
		}
		category += appendable

		if _, ok := catMap[category]; !ok {
			catMap[category], err = renameio.NewPendingFile(path.Join(outdir, category))
			if err != nil {
				log.Fatalf("error creating temporary file at %s: %e", path.Join(outdir, category), err)
			}
		}

		if strings.Contains(fp.feed.SiteURL, "/channel/") {
			fp.feed.SiteURL = fp.feed.SiteURL + "/videos"
		}

		_, err := catMap[category].WriteString(fmt.Sprintf("%s # %s\n", fp.feed.SiteURL, fp.feed.Title))
		if err != nil {
			log.Fatalf("error writing to temporary file of %s: %e", category, err)
		}
	}

	for category, pf := range catMap {
		if err := pf.CloseAtomicallyReplace(); err != nil {
			log.Fatalf("error replacing temporary file of %s: %e", category, err)
		}
	}

	// delete files with +auto, that aren't referenced this time around

	ls, err := os.ReadDir(outdir)
	if err != nil {
		log.Fatalf("listing files in %s: %e", outdir, err)
	}

	for _, file := range ls {
		if file.IsDir() {
			continue
		}

		parts := strings.Split(file.Name(), "+")

		for _, t := range parts[1:] { // ignore category name to get tags, might be nil
			if strings.EqualFold(t, "auto") { // ignore non-auto

				_, ok := catMap[strings.ToLower(file.Name())]
				if !ok {
					os.Remove(path.Join(outdir, file.Name()))
				}
				continue
			}
		}

	}
}

func useTags(tags tagMap) (appendable string, archiveIt bool) {
	appendable += "+auto"

	if _, ok := tags["a"]; ok {
		archiveIt = true
	}

	if _, ok := tags["c"]; ok {
		appendable += "+comments"
		archiveIt = true
	}

	return appendable, archiveIt
}

type (
	feedPlus struct {
		tags tagMap
		feed *miniflux.Feed
	}
	tagMap map[string]bool // lowercase, bool has no meaning
)

// filters for yt,
// if not added, adds add_youtube_video_using_invidious_player,
// parses tags
// uses log.Printf for errors
func processFeeds(c *miniflux.Client, feeds miniflux.Feeds) (ytFeeds []feedPlus) {
	for _, f := range feeds {
		if strings.HasPrefix(f.SiteURL, "https://www.youtube.com/") {

			// lazy auto-adjustment
			if f.RewriteRules == "" {
				rewriteStr := "add_youtube_video_using_invidious_player"
				if _, err := c.UpdateFeed(f.ID, &miniflux.FeedModificationRequest{RewriteRules: &rewriteStr}); err != nil {
					log.Printf("error updating RewriteRules of feed %d: %e", f.ID, err)
				}
			}

			// somethingTitle [tag,tag2]
			if !strings.HasSuffix(f.Title, "]") {
				if !f.Disabled {
					log.Printf("Feed %d (%s) has no tag!", f.ID, f.Title)
				}
				continue
			}

			f.Title = f.Title[:len(f.Title)-1] // rm "]"
			cleanTitle, tagStr, _ := revCut(f.Title, " [")
			f.Title = cleanTitle

			tags := make(map[string]bool)
			for _, t := range strings.Split(
				strings.ToLower(tagStr), ",") {
				//
				tags[t] = false
			}

			ytFeeds = append(ytFeeds, feedPlus{
				tags: tags,
				feed: f,
			})
		}
	}
	return ytFeeds
}
