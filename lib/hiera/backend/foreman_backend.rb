# Foreman Backend for Hiera
# Many thanks to @ohadlevy

class Hiera
  module Backend
    class Foreman_backend
      attr_reader :url

      def initialize
        require 'net/http'
        require 'net/https'

        @url = Config[:foreman][:url]
        Hiera.debug("Hiera Foreman backend starting")
      end

      def lookup(key, scope, order_override, resolution_type)
        Hiera.debug("Looking up #{key} in Foreman backend")
        
        fqdn = scope['fqdn'] if scope.has_key?('fqdn')

        foreman_uri      = URI.parse("#{@url}/node/#{fqdn}?format=yml")
        http             = Net::HTTP.new(foreman_uri.host, foreman_uri.port)
        http.use_ssl     = foreman_uri.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl
        request          = Net::HTTP::Get.new(foreman_uri.request_uri)

        YAML.load(http.request(request).body)['parameters'][key]
      end
    end
  end
end

