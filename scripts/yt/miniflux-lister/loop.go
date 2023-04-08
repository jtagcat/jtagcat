package main

import (
	"fmt"
	"log"
	"os"
	"path"
	"strings"

	"github.com/google/renameio/v2"
	"github.com/jtagcat/util/std"
	miniflux "miniflux.app/client"
)

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

	catMap, catCount := make(map[string]*renameio.PendingFile), make(map[string]int)

	for _, fp := range ytFeeds {
		category := strings.ToLower(fp.feed.Category.Title)
		if !strings.HasPrefix(category, "yt/") {
			continue
		}

		category = strings.TrimPrefix(category, "yt/")
		category += "-auto"

		appendable, archiveIt := useTags(fp.tags)
		if !archiveIt {
			continue
		}

		// divide to maximum MAX_PER_FILE per (category) file
		catC, _ := catCount[category]
		catCount[category] = catC + 1

		catN := (catC / MAX_PER_FILE) + 1
		if catN > 1 {
			category += fmt.Sprintf("-%d", catN)
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

	// delete files with -auto, that aren't referenced this time around

	ls, err := os.ReadDir(outdir)
	if err != nil {
		log.Fatalf("listing files in %s: %e", outdir, err)
	}

	for _, file := range ls {
		if file.IsDir() {
			continue
		}

		part, _, _ := strings.Cut(file.Name(), "+")

		if strings.HasSuffix(part, "-auto") { // ignore non-auto
			_, ok := catMap[strings.ToLower(file.Name())]
			if !ok {
				os.Remove(path.Join(outdir, file.Name()))
			}
			continue
		}
	}
}

func useTags(tags tagMap) (appendable string, archiveIt bool) {
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

			if f.Disabled {
				continue
			}

			// add empty tag
			if !strings.HasSuffix(f.Title, "]") {
				newTitle := f.Title + " []"
				if _, err := c.UpdateFeed(f.ID, &miniflux.FeedModificationRequest{Title: &newTitle}); err != nil {
					log.Printf("error adding empty tag to feed %d: %e", f.ID, err)
				}

				continue
			}

			if strings.HasSuffix(f.Title, "[]") {
				log.Printf("feed %d (%s) tag is empty", f.ID, f.Title)
				continue
			}

			f.Title = f.Title[:len(f.Title)-1] // rm "]"
			cleanTitle, tagStr, _ := std.RevCut(f.Title, " [")
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
