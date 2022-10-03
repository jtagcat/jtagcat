package main

import (
	"strings"
)

// copied from jtagcat/offope
// strings.Cut, but starting from last character, found is either empty or seperator
func revCut(s, sep string) (before, after string, found bool) {
	if i := strings.LastIndex(s, sep); i >= 0 {
		return s[:i], s[i+len(sep):], true
	}
	return s, "", false
}
