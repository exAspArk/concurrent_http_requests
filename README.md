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
* EM-HTTP-request with EM-Synchrony

## Benchmark

The following benchmarks show only approximate values. These results may vary depending on the circumstances.

```
$ REPEAT_COUNT=5 URL=http://google.com ruby benchmark.rb

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

```
$ REPEAT_COUNT=30 URL=http://baidu.com ruby benchmark.rb

Comparison:
            EM-HTTP-request Multi: 0.9 i/s
                       Curb Multi: 0.8 i/s - 1.12x slower
                  Curb in threads: 0.7 i/s - 1.31x slower
              Parallel in threads: 0.5 i/s - 1.86x slower
EM-HTTP-request with EM-Synchrony: 0.4 i/s - 2.14x slower
                   Typhoeus Hydra: 0.4 i/s - 2.25x slower
             Net::HTTP in threads: 0.2 i/s - 3.71x slower
       Patron with ConnectionPool: 0.1 i/s - 17.39x slower
                Celluloid futures: 0.0 i/s - 24.31x slower
            Net::HTTP in sequence: 0.0 i/s - 29.12x slower
```

## Conclusion

In my opinion, using `Parallel` is the simplest way to make concurrent HTTP requests in threads.
Look at the [Clients::ParallelThreads](clients.rb) class, it is as simple as just making requests in sequence.

However, if you are making a lot of requests simultaneously, using a lot of threads may be too expensive for you.
In this case `Curb::Multi` will probably be the best solution for you.
The code seems not so elegant, but you can always encapsulate it in your own method or class.

`Typhoeus` is another fast and reliable HTTP client which allows to make concurrent requests by using `Typhoeus::Hydra`.

Personally, I wouldn't recommend using `EM-HTTP-request` even if it works really fast.
The only situation when it may be useful if you already use EventMachine in your project.

Using `Patron` is not as fast as other options here.
Plus it requires one more additional dependency, e.g. `ConnectionPool`, because `Patron::Session` is [not thread
safe](https://github.com/toland/patron#threading).

`Celluloid` is a great actor-based library, but making simple HTTP requests in actors adds too much overhead.

## Useful links

* http://andrey.chernih.me/2014/05/29/downloading-multiple-files-in-ruby-simultaneously/
* https://www.toptal.com/ruby/ruby-concurrency-and-parallelism-a-practical-primer
* https://reevoo.github.io/blog/2014/09/12/http-shooting-party/
* https://groups.google.com/forum/#!topic/celluloid-ruby/io4AQ1yzNIs
