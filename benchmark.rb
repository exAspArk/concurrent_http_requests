require 'benchmark/ips'

Benchmark.ips do |x|
  x.report('Sequential') {} # TODO

  x.report('Threads') {} # TODO

  x.report('Typhoeus') {} # TODO

  x.report('Parallel') {} # TODO

  x.report('Celluloid') {} # TODO

  x.report('Em-http-request') {} # TODO

  x.compare!
end
