require 'benchmark/ips'
require_relative 'clients'

REPEAT_COUNT = (ENV['REPEAT_COUNT'] || 5).to_i
URLS = (['http://google.com'] * REPEAT_COUNT).freeze

Benchmark.ips do |x|
  x.warmup = 0

  x.report('Net::HTTP in sequence')             { Clients::NetHttp.perform(URLS) }
  x.report('Net::HTTP in threads')              { Clients::NetHttpThreads.perform(URLS) }
  x.report('Curb in threads')                   { Clients::CurbThreads.perform(URLS) }
  x.report('Curb Multi')                        { Clients::CurbMulti.perform(URLS) }
  x.report('Typhoeus Hydra')                    { Clients::TyphoeusHydra.perform(URLS) }
  x.report('Patron with ConnectionPool')        { Clients::PatronWithConnectionPool.perform(URLS) }
  x.report('Parallel in threads')               { Clients::ParallelThreads.perform(URLS) }
  x.report('Celluloid futures')                 { Clients::CelluloidFutures.perform(URLS) }
  x.report('EM-HTTP-request Multi')             { Clients::EmHttpRequestMulti.perform(URLS) }
  x.report('EM-HTTP-request with EM-Synchrony') { Clients::EmHttpRequestSynchrony.perform(URLS) }

  x.compare!
end
