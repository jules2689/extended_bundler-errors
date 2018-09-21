module ExtendedBundler
  module Errors
    class Cache
      CACHE_URL = "https://jules2689.github.io/extended_bundler-errors/"
      CACHE_EXPIRY = 60 * 60 * 24 # 1 day

      class << self
        def handlers_index
          if cache_expired?
            File.write(cache_file, Time.now.utc.iso8601)
            fetch_file('index').lines
          else
            nil
          end
        end

        def fetch_file(file)
          require "net/http"
          require "uri"
          url = File.join(CACHE_URL, file)
          uri = URI.parse(url)
          Net::HTTP.get_response(uri).body
        end

        private

        def cache_expired?
          require 'time'
          Time.parse(File.read(cache_file)).utc - Time.now.utc > CACHE_EXPIRY
        rescue ArgumentError, Errno::ENOENT
          true
        end

        def cache_file
          File.expand_path("../../index_cache_time", __dir__)
        end
      end
    end
  end
end
