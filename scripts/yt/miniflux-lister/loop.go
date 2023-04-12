package main

import (
	"fmt"
	"log"
	"os"
	"path"
	"sort"
	"strings"

	"github.com/google/renameio/v2"
	"github.com/jtagcat/util/std"
	miniflux "miniflux.app/client"
)

func client() *miniflux.Client {
	endpoint, token := os.Getenv(ENVPREFIX+"MINIFLUX_ENDPOINT"), os.Getenv(ENVPREFIX+"MINIFLUX_TOKEN")
	endpoint = strings.TrimSuffix(strings.TrimSuffix(endpoint, "/"), "/v1") // https://github.com/miniflux/v2/pull/1582

	c := miniflux.New(endpoint, token)

	me, err := c.Me()
	if err != nil {
		log.Fatal("error authenticating: %w", err)
	}
	log.Printf("Authenticated as %s", me.Username)

	return c
}

func mainLoop() {
	basedir := os.Getenv(ENVPREFIX + "OUTDIR")
	if basedir == "" {
		log.Fatal(ENVPREFIX + "OUTDIR env variable is empty")
	}

	c := client()

	feeds, err := c.Feeds()
	if err != nil {
		log.Fatal("error getting feeds: %w", err)
	}

	ytFeeds := processFeeds(c, feeds)

	flushToFiles(basedir, ytFeeds)
}

type (
	feedPlus struct {
		tags tagMap
		feed *miniflux.Feed
	}
	tagMap map[string]bool // lowercase, bool has no meaning

	categorizedFeeds map[string][]feedPlus
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
				tags[t] = true
			}

			ytFeeds = append(ytFeeds, feedPlus{
				tags: tags,
				feed: f,
			})
		}
	}
	return ytFeeds
}

func filterFeeds(ytFeeds []feedPlus) (feeds, feedsWithComments categorizedFeeds) {
	feeds, feedsWithComments = make(categorizedFeeds), make(categorizedFeeds)

	for _, feed := range ytFeeds {
		feed.feed.Category.Title = strings.ToLower(feed.feed.Category.Title)
		if !strings.HasPrefix(feed.feed.Category.Title, "yt/") {
			continue
		}

		if yes, ok := feed.tags["i"]; ok && yes {
			continue
		}

		if yes, ok := feed.tags["a"]; ok && yes {
			feeds[feed.feed.Category.Title] = append(feeds[feed.feed.Category.Title], feed)
			continue
		}

		if yes, ok := feed.tags["c"]; ok && yes {
			feedsWithComments[feed.feed.Category.Title] = append(feedsWithComments[feed.feed.Category.Title], feed)
			continue
		}
	}

	return
}

func flushToFiles(basedir string, ytFeeds []feedPlus) {
	feeds, feedsWithComments := filterFeeds(ytFeeds)

	flushWithSuffix(basedir, feeds, "")
	flushWithSuffix(basedir, feedsWithComments, "comments")
}

func flushWithSuffix(basedir string, feeds categorizedFeeds, suffix string) {
	for category, subfeeds := range feeds {
		sort.SliceStable(subfeeds, func(i, j int) bool {
			return subfeeds[i].feed.ID > subfeeds[j].feed.ID
		})

		filename := rotatingFile{
			basename:     fmt.Sprintf("%s-auto", strings.TrimPrefix(category, "yt/")) + addSuffix("-", suffix),
			maxPerIndex:  MAX_PER_FILE,
			currentIndex: 1,
		}

		files := make(pendingFiles)

		for _, feed := range subfeeds {
			currentFile := getPending(files, basedir, filename.get()+addSuffix("+", suffix))

			if strings.Contains(feed.feed.SiteURL, "/channel/") {
				feed.feed.SiteURL = strings.TrimSuffix(feed.feed.SiteURL, "/") + "/videos"
			}

			_, err := currentFile.WriteString(fmt.Sprintf("%s # %s\n", feed.feed.SiteURL, feed.feed.Title))
			if err != nil {
				log.Fatalf("error writing to temporary file of %s: %e", category, err)
			}

		}

		for _, file := range files {
			file.CloseAtomicallyReplace()
		}

		// delete unreferenced -auto files
		ls, err := os.ReadDir(basedir)
		if err != nil {
			log.Fatalf("listing files in %s: %e", basedir, err)
		}

		for _, file := range ls {
			if file.IsDir() {
				continue
			}

			if !strings.HasPrefix(file.Name(), filename.basename) {
				continue
			}

			_, ok := files[file.Name()]
			if !ok {
				os.Remove(path.Join(basedir, file.Name()))
			}
		}
	}
}

type rotatingFile struct {
	basename    string
	maxPerIndex int

	inCurrent    int
	currentIndex int
}

func (c *rotatingFile) get() string {
	c.inCurrent++

	if c.inCurrent > c.maxPerIndex {
		c.currentIndex++
		c.inCurrent = 1
	}

	return fmt.Sprintf("%s-%d", c.basename, c.currentIndex)
}

type pendingFiles map[string]*renameio.PendingFile

func getPending(files pendingFiles, basedir, name string) *renameio.PendingFile {
	if _, ok := files[name]; !ok {
		var err error

		files[name], err = renameio.NewPendingFile(path.Join(basedir, name))
		if err != nil {
			log.Fatalf("error creating temporary file %q: %e", name, err)
		}
	}

	return files[name]
}

func addSuffix(separator, suffix string) string {
	if suffix == "" {
		return ""
	}

	return separator + suffix
}
