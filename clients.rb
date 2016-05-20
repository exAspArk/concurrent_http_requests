module Clients
  class NetHttp
    require 'net/http'

    def self.perform(urls)
      urls.map { |url| get_body(url) }
    end

    def self.get_body(url)
      uri = URI.parse(url)
      request = Net::HTTP::Get.new(uri)
      response = nil
      Net::HTTP.start(uri.host, uri.port) { |http| response = http.request(request) }
      response.body
    end
  end

  class NetHttpThreads
    def self.perform(urls)
      response_bodies = []

      threads = urls.map do |url|
        Thread.new { response_bodies << NetHttp.get_body(url) }
      end
      threads.each(&:join)

      response_bodies
    end
  end

  class CurbThreads
    require 'curb'

    def self.perform(urls)
      response_bodies = []

      threads = urls.map do |url|
        Thread.new { response_bodies << Curl.get(url).body_str }
      end
      threads.each(&:join)

      response_bodies
    end
  end

  class CurbMulti
    require 'curb'

    def self.perform(urls)
      response_bodies = []

      curl_multi = Curl::Multi.new
      urls.each do |url|
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
  end

  class TyphoeusHydra
    require 'typhoeus'

    def self.perform(urls)
      response_bodies = []

      hydra = Typhoeus::Hydra.new
      requests = urls.map do |url|
        request = Typhoeus::Request.new(url, followlocation: false)
        hydra.queue(request)
        request
      end
      hydra.run

      response_bodies = requests.map { |req| req.response.body }
      response_bodies
    end
  end

  class PatronWithConnectionPool
    require 'patron'
    require 'connection_pool'

    def self.perform(urls)
      response_bodies = []

      patron_pool = ConnectionPool.new(size: urls.size, timeout: 5) do
        Patron::Session.new { |s| s.max_redirects = 0 }
      end
      urls.each do |url|
        response_bodies << patron_pool.with { |session| session.get(url) }
      end

      response_bodies
    end
  end

  class ParallelThreads
    require 'parallel'

    def self.perform(urls)
      Parallel.map(urls, in_threads: urls.size) { |url| NetHttp.get_body(url) }
    end
  end

  class CelluloidFutures
    require 'celluloid'

    class CelluloidWorker
      include Celluloid

      def get(url)
        NetHttp.get_body(url)
      end
    end

    def self.perform(urls)
      worker = CelluloidWorker.new
      futures = urls.map { |url| worker.future.get(url) }
      futures.map(&:value)
    end
  end

  class EmHttpRequestMulti
    require 'em-http-request'

    def self.perform(urls)
      response_bodies = []

      EventMachine.run do
        multi = EventMachine::MultiRequest.new
        urls.each_with_index { |url, i| multi.add("#{i}:#{url}", EventMachine::HttpRequest.new(url).get) }

        multi.callback do
          response_bodies = multi.responses[:callback].values.map(&:response)
          EventMachine.stop
        end
      end

      response_bodies
    end
  end

  class EmHttpRequestSynchrony
    require 'em-http-request'
    require 'em-synchrony'

    # Use this module with refinement instead of requiring 'em-synchrony/em-http'
    # which doesn't allow to use em-http-request without fibers
    module EmHttp
      refine ::EventMachine::HttpConnection do
        alias :aget :get

        def get(options = {}, &blk)
          f = Fiber.current
          conn = setup_request(:get, options, &blk)
          if conn.error.nil?
            conn.callback { f.resume(conn) }
            conn.errback  { f.resume(conn) }
            Fiber.yield
          else
            conn
          end
        end
      end
    end
    using EmHttp

    def self.perform(urls)
      response_bodies = []

      EM.synchrony do
        multi = EventMachine::Synchrony::Multi.new
        URLS.each_with_index { |url, i| multi.add("#{i}:#{url}", EventMachine::HttpRequest.new(url).aget) }
        result = multi.perform
        response_bodies = result.responses[:callback].values.map(&:response)
        EventMachine.stop
      end

      response_bodies
    end
  end
end
