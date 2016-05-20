require 'benchmark/ips'
require 'net/http'
require 'curb'
require 'typhoeus'
require 'patron'
require 'parallel'
require 'celluloid'
require 'connection_pool'
require 'em-http-request'

REPEAT_COUNT = (ENV['REPEAT_COUNT'] || 5).to_i
URLS = ['http://google.com'] * REPEAT_COUNT

def net_http_response(url)
  uri = URI.parse(url)
  request = Net::HTTP::Get.new(uri)
  response = nil
  Net::HTTP.start(uri.host, uri.port) { |http| response = http.request(request) }
  response
end

class CelluloidWorker
  include Celluloid

  def get(url)
    net_http_response(url)
  end
end

Benchmark.ips do |x|
  x.warmup = 0

  x.report('Net::HTTP in sequence') do
    response_bodies = URLS.map { |url| net_http_response(url).body }
    response_bodies
  end

  x.report('Net::HTTP in threads') do
    response_bodies = []

    URLS.each do |url|
      thread = Thread.new { response_bodies << net_http_response(url).body }
      thread.join
    end

    response_bodies
  end

  x.report('Curb in threads') do
    response_bodies = []

    URLS.each do |url|
      tread = Thread.new { response_bodies << Curl.get(url).body_str }
      tread.join
    end

    response_bodies
  end

  x.report('Curb Multi') do
    response_bodies = []

    curl_multi = Curl::Multi.new
    URLS.each do |url|
      curl = Curl::Easy.new(url) do |c|
        c.on_body do |body|
          response_bodies << body
          body.size
        end
      end
      curl_multi.add(curl)
    end
    curl_multi.perform

    response_bodies
  end

  x.report('Typhoeus Hydra') do
    response_bodies = []

    hydra = Typhoeus::Hydra.new
    requests = URLS.map do |url|
      request = Typhoeus::Request.new(url, followlocation: false)
      hydra.queue(request)
      request
    end
    hydra.run

    response_bodies = requests.map { |req| req.response.body }
    response_bodies
  end

  x.report('Patron with ConnectionPool') do
    response_bodies = []

    patron_pool = ConnectionPool.new(size: URLS.size, timeout: 5) do
      Patron::Session.new { |s| s.max_redirects = 0 }
    end
    URLS.each do |url|
      response_bodies << patron_pool.with { |session| session.get(url) }
    end

    response_bodies
  end

  x.report('Parallel in threads') do
    response_bodies = Parallel.map(URLS, in_threads: URLS.size) { |url| net_http_response(url).body }
    response_bodies
  end

  x.report('Celluloid futures') do
    worker = CelluloidWorker.new
    futures = URLS.map { |url| worker.future.get(url) }
    response_bodies = futures.map { |future| future.value.body }
    response_bodies
  end

  x.report('EM-HTTP-request') do
    response_bodies = []

    EventMachine.run do
      multi = EventMachine::MultiRequest.new
      URLS.each_with_index { |url, i| multi.add("#{i}:#{url}", EventMachine::HttpRequest.new(url).get) }

      multi.callback do
        response_bodies = multi.responses[:callback].values.map(&:response)
        EventMachine.stop
      end
    end

    response_bodies
  end

  # x.report('Em-http-request with Em-Synchrony') {} # TODO

  x.compare!
end
