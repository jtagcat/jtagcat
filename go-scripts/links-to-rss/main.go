package main

import (
	"fmt"
	"log"
	"net/url"
	"os"
	"strings"
	"time"

	"github.com/gorilla/feeds"
)

func main() {
	zeroTime := time.Time{}

	if len(os.Args) != 2 {
		panic("expected exactly 1 argument, file to read urls from")
	}

	urlFile := os.Args[1]
	urlBytes, err := os.ReadFile(urlFile)
	if err != nil {
		panic("reading urls from file with name of first argument")
	}

	urls := strings.Split(string(urlBytes), "\n")

	firstUrl, err := url.Parse(urls[0])
	if err != nil {
		panic("parsing first url")
	}

	var items []*feeds.Item
	for _, item := range urls {
		if item == "" { // empty and EOF lines
			continue
		}

		items = append(items, &feeds.Item{
			Title:   item,
			Link:    &feeds.Link{Href: item},
			Created: zeroTime,
		})
	}

	feed := &feeds.Feed{
		Title:       firstUrl.Host + " archive",
		Link:        &feeds.Link{Href: "https://" + firstUrl.Host},
		Description: "manual feed archive",
		Created:     zeroTime,
		Items:       items,
	}

	rss, err := feed.ToRss()
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println(rss)
}
