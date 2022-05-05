## Parallel line-by-line processing from `io.Reader` using unbuffered channels.
```go
func ParseLines(input io.Reader) (output []string, _ error) {
	g, reschan := new(errgroup.Group), make(chan string)

	scanner := bufio.NewScanner(input)
	for i := 1; scanner.Scan(); i++ {
		line, linenum := scanner.Text(), linenum // https://golang.org/doc/faq#closures_and_goroutines
		g.Go(func() error {
			return parseLineSingle(line, linenum, reschan)
		})
	}

	var readOK sync.Mutex
	readOK.Lock()
	go func() {
		defer readOK.Unlock()
		for r := range reschan {
			output = append(output, r)
		}
	}()

	err := g.Wait()
	close(reschan)
	readOK.Lock() // wait for reschan to be fully flushed to output

	if err != nil {
		return output, fmt.Errorf("haz err: %e", err)
	}
	return output, scanner.Err()
}

parseLineSingle(line string, linenum int, reschan chan string) {}

```
