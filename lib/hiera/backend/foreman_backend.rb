# Foreman Backend for Hiera

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

        Hiera.debug("Hiera Foreman backend starting")

        @http = nil
        @url  = Config[:foreman][:url]
        @user = Config[:foreman][:user]
        @pass = Config[:foreman][:pass]
      end

      def lookup(key, scope, order_override, resolution_type)
        fqdn    = scope['fqdn']
        results = []
        
        foreman_uri       = URI.parse("#{@url}")
        @http             = Net::HTTP.new(foreman_uri.host, foreman_uri.port)
        @http.use_ssl     = foreman_uri.scheme == 'https'
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @http.use_ssl

        data = lookup_enc(fqdn).merge(lookup_smartvars(fqdn))
        data[key] || nil
      end

      def lookup_enc(fqdn)
        Hiera.debug("Performing Foreman ENC lookup on #{fqdn}")

        path = URI.parse("#{@url}/node/#{fqdn}?format=yml")
        req  = Net::HTTP::Get.new(path.request_uri)

        # Using interpolated strings allows this to work
        # even if the server doesn't require basic auth
        req.basic_auth("#{@user}", "#{@pass}")
        data = YAML.load(@http.request(req).body) || {}

        return { 'classes' => data['classes'] }.merge(data['parameters'])
      end

      def lookup_smartvars(fqdn)
        Hiera.debug("Performing Foreman SmartVar lookup on #{fqdn}")

        path = URI.escape("#{@url}/hosts/#{fqdn}/lookup_keys")
        req  = Net::HTTP::Get.new(path)
        resp = nil

        req.basic_auth("#{@user}", "#{@pass}")
        req['Content-Type'] = 'application/json'
        req['Accept']       = 'application/json'

        Timeout::timeout(5) do
          resp = @http.request(req).body
        end

        if resp && resp.length >= 2
          data = JSON.parse(resp)
        else
          data = {}
        end

        return data
      end
  
    end
  end
end
