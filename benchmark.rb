require 'benchmark/ips'
require 'net/http'
require 'curb'
require 'typhoeus'
require 'parallel'

REPEAT_COUNT = 10
URL = 'http://google.com'

Benchmark.ips do |x|
  x.warmup = 0

  x.report('Sequential Net::HTTP') do
    REPEAT_COUNT.times do
      uri = URI.parse(URL)
      request = Net::HTTP::Get.new(uri)
      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
    end
  end

  x.report('Threads Net::HTTP') do
    REPEAT_COUNT.times do
      thread = Thread.new do
        uri = URI.parse(URL)
        request = Net::HTTP::Get.new(uri)
        Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
      end

      thread.join
    end
  end

  x.report('Threads Curb') do
    REPEAT_COUNT.times do
      thread = Thread.new { Curl.get(URL) }
      thread.join
    end
  end

  x.report('Typhoeus') do
    hydra = Typhoeus::Hydra.new
    REPEAT_COUNT.times { hydra.queue(Typhoeus::Request.new(URL, followlocation: false)) }
    hydra.run
  end

  x.report('Parallel') do
    urls = [URL] * REPEAT_COUNT
    Parallel.each(urls, in_threads: urls.size) do |url|
      uri = URI.parse(url)
      request = Net::HTTP::Get.new(uri)
      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
    end
  end

  x.report('Celluloid') {} # TODO

  x.report('Em-http-request') {} # TODO

  x.compare!
end
