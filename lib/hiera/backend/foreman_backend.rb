# Foreman Backend for Hiera
# Many thanks to @ohadlevy
# from: https://github.com/torrancew/hiera-foreman

class Hiera
  module Backend
    class Foreman_backend
      attr_reader :url

      def initialize
        require 'net/http'
        require 'net/https'
        require 'timeout'
        require 'uri'
        require 'json'

        @url = Config[:foreman][:url]
        @user = Config[:foreman][:user]
        @pass = Config[:foreman][:pass]
        Hiera.debug("Hiera Foreman backend starting")
      end

      def lookup(key, scope, order_override, resolution_type)
        begin
          fqdn = scope.catalog.tags[4]
        rescue
          fqdn = scope['fqdn'] if scope.has_key?('fqdn')
          Hiera.debug("trying mcollective")
        end
        Hiera.debug("got fqdn #{fqdn}")

        results = []
        
        Hiera.debug("Trying #{key} in ENC")
        results = encquery(fqdn, key)
        if !results
          Hiera.debug("Trying #{key} in SmartVar")
          results = smartquery(fqdn, key)
        end 
        Hiera.debug("Found #{results}")
        return results
      end

      def encquery (fqdn, key)
        Hiera.debug("performing ENC lookup on #{fqdn} for #{key}")
        answer = []

        foreman_uri      = URI.parse("#{@url}/node/#{fqdn}?format=yml")
        http             = Net::HTTP.new(foreman_uri.host, foreman_uri.port)
        http.use_ssl     = foreman_uri.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl
        request          = Net::HTTP::Get.new(foreman_uri.request_uri)
  
        data = YAML.load(http.request(request).body)

        case key
          when 'classes'
            Hiera.debug("Parsing classes")
            answer = data['classes'] || []
          else
            Hiera.debug("Parsing something else")
            answer = data['parameters'][key] || nil
        end
  
        Hiera.debug("ENC returning #{answer}")
        return answer
      end

      def smartquery (fqdn, key)
        uri = URI.parse("#{@url}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'

        path = URI.escape("/hosts/#{fqdn}/lookup_keys/#{key}")
        req = Net::HTTP::Get.new(path)
        req.basic_auth("#{@user}", "#{@pass}")
        req['Content-Type'] = 'application/json'
        req['Accept'] = 'application/json'

        begin
          Timeout::timeout(5) { JSON.parse(http.request(req).body)["value"] }
        rescue
          Hiera.debug("no smart var for #{key}")
          return nil
        end
      end
  
    end
  end
end
