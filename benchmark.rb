require 'benchmark/ips'
require 'net/http'
require 'curb'
require 'typhoeus'
require 'parallel'
require 'celluloid'

REPEAT_COUNT = (ENV['REPEAT_COUNT'] || 10).to_i
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

  x.report('Sequential Net::HTTP') do
    response_bodies = URLS.map { |url| net_http_response(url).body }
    response_bodies
  end

  x.report('Threads Net::HTTP') do
    response_bodies = []

    URLS.each do |url|
      thread = Thread.new { response_bodies << net_http_response(url).body }
      thread.join
    end

    response_bodies
  end

  x.report('Threads Curb') do
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

  x.report('Typhoeus') do
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

  x.report('Parallel') do
    response_bodies = Parallel.map(URLS, in_threads: URLS.size) { |url| net_http_response(url).body }
    response_bodies
  end

  x.report('Celluloid') do
    worker = CelluloidWorker.new
    futures = URLS.map { |url| worker.future.get(url) }
    response_bodies = futures.map { |future| future.value.body }
    response_bodies
  end

  # x.report('Em-http-request') {} # TODO

  # x.report('Em-http-request with Em-Synchrony') {} # TODO

  x.compare!
end
