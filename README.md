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
REPEAT_COUNT=5 ruby benchmark.rb
```

## Useful links

* http://andrey.chernih.me/2014/05/29/downloading-multiple-files-in-ruby-simultaneously/
* https://www.toptal.com/ruby/ruby-concurrency-and-parallelism-a-practical-primer
* https://reevoo.github.io/blog/2014/09/12/http-shooting-party/
* https://groups.google.com/forum/#!topic/celluloid-ruby/io4AQ1yzNIs
