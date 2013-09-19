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

        results = lookup_enc(fqdn, key)
        if results.nil?
          results = lookup_smartvars(fqdn, key)
        end
        unless results.nil?
          begin
            case resolution_type
              when :array
                if results.kind_of?(Array)
                  data = results
                else
                  data = results.gsub(/, /, ',').split(',')
                end
              when :hash
                data = results.split(',')
              else
                data = results
            end
          end
        end
        data || nil
      end

      def lookup_enc(fqdn, key)
        Hiera.debug("Performing Foreman ENC lookup on #{fqdn} for #{key}")

        path = URI.parse("#{@url}/node/#{fqdn}?format=yml")
        req  = Net::HTTP::Get.new(path.request_uri)

        # Using interpolated strings allows this to work
        # even if the server doesn't require basic auth
        req.basic_auth("#{@user}", "#{@pass}")
        data = YAML.load(@http.request(req).body) || {}

        case key
        when 'classes'
          if data['classes']:
            results = data['classes'].keys
          else
            results = []
          end
          Hiera.debug("returning classes")
        else
          if data['parameters'] and data['parameters'].has_key?(key):
            results = data['parameters'][key]
          else
            results = nil
          end
        end
        return results
      end

      def lookup_smartvars(fqdn, key)
        Hiera.debug("Performing Foreman SmartVar lookup on #{fqdn} for #{key}")

        path = URI.escape("#{@url}/hosts/#{fqdn}/lookup_keys/#{key}")
        req  = Net::HTTP::Get.new(path)
        resp = nil

        req.basic_auth("#{@user}", "#{@pass}")
        req['Content-Type'] = 'application/json'
        req['Accept']       = 'application/json'

        Timeout::timeout(5) do
          resp = @http.request(req).body
        end

        if resp && resp.length >= 2
          data = JSON.parse(resp)["value"]
        else
          data = nil
        end

        return data
      end
  
    end
  end
end

