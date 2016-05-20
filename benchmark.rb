require 'benchmark/ips'
require_relative 'clients'

REPEAT_COUNT = (ENV['REPEAT_COUNT'] || 5).to_i
URL = (ENV['URL'] || 'http://google.com').freeze
URLS = ([URL] * REPEAT_COUNT).freeze

def run_test!(klass, urls)
  result = klass.perform(urls)
  return if result.size == urls.size

  raise "Failed to run #{klass}"
end

Benchmark.ips do |x|
  x.warmup = 0

  x.report('Net::HTTP in sequence')             { run_test!(Clients::NetHttp, URLS) }
  x.report('Net::HTTP in threads')              { run_test!(Clients::NetHttpThreads, URLS) }
  x.report('Curb in threads')                   { run_test!(Clients::CurbThreads, URLS) }
  x.report('Curb Multi')                        { run_test!(Clients::CurbMulti, URLS) }
  x.report('Typhoeus Hydra')                    { run_test!(Clients::TyphoeusHydra, URLS) }
  x.report('Patron with ConnectionPool')        { run_test!(Clients::PatronWithConnectionPool, URLS) }
  x.report('Parallel in threads')               { run_test!(Clients::ParallelThreads, URLS) }
  x.report('Celluloid futures')                 { run_test!(Clients::CelluloidFutures, URLS) }
  x.report('EM-HTTP-request Multi')             { run_test!(Clients::EmHttpRequestMulti, URLS) }
  x.report('EM-HTTP-request with EM-Synchrony') { run_test!(Clients::EmHttpRequestSynchrony, URLS) }

  x.compare!
end
