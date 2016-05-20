require 'benchmark/ips'
require 'net/http'

REPEAT_COUNT = 10
URL = 'http://google.com'

Benchmark.ips do |x|
  x.report('Sequential') do
    REPEAT_COUNT.times do
      url = URI.parse(URL)
      request = Net::HTTP::Get.new(url)
      Net::HTTP.start(url.host, url.port) { |http| http.request(request) }
    end
  end

  x.report('Threads') {} # TODO

  x.report('Typhoeus') {} # TODO

  x.report('Parallel') {} # TODO

  x.report('Celluloid') {} # TODO

  x.report('Em-http-request') {} # TODO

  x.compare!
end
