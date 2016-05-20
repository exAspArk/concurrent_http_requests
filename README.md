# Concurrent HTTP requests in Ruby

## Options

* Net::HTTP in sequence
* Net::HTTP in threads
* Curb in threads
* Curb Multi
* Typhoeus Hydra
* Patron with ConnectionPool
* Parallel in threads
* Celluloid futures
* EM-HTTP-request Multi

## Benchmark

```
$ REPEAT_COUNT=5 ruby benchmark.rb

Comparison:
              Parallel in threads: 4.1 i/s
                  Curb in threads: 4.1 i/s - 1.01x slower
                       Curb Multi: 4.1 i/s - 1.01x slower
                   Typhoeus Hydra: 4.0 i/s - 1.03x slower
EM-HTTP-request with EM-Synchrony: 4.0 i/s - 1.03x slower
            EM-HTTP-request Multi: 4.0 i/s - 1.04x slower
             Net::HTTP in threads: 4.0 i/s - 1.04x slower
       Patron with ConnectionPool: 1.4 i/s - 2.86x slower
                Celluloid futures: 0.8 i/s - 4.88x slower
            Net::HTTP in sequence: 0.8 i/s - 5.46x slower
```

## Useful links

* http://andrey.chernih.me/2014/05/29/downloading-multiple-files-in-ruby-simultaneously/
* https://www.toptal.com/ruby/ruby-concurrency-and-parallelism-a-practical-primer
* https://reevoo.github.io/blog/2014/09/12/http-shooting-party/
* https://groups.google.com/forum/#!topic/celluloid-ruby/io4AQ1yzNIs
