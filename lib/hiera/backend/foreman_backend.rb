class Hiera
  module Backend
    class Foreman_backend
      def initialize
        require 'pry'
        require 'yaml'
        require 'rest_client'
        Hiera.debug("Hiera Foreman backend starting")
      end

      def lookup(key, scope, order_override, resolution_type)
        Hiera.debug("Looking up #{key} in Foreman backend")
        answer = Backend.empty_answer(resolution_type)
        #Hiera.debug("Checking scope #{scope.inspect} with #{order_override.inspect} (looking for #{resolution_type})")

        Hiera.debug("Connecting to #{Config[:foreman][:url]}")
        foreman = RestClient::Resource.new(Config[:foreman][:url])

        Backend.datasources(scope, order_override) do |source|
          Hiera.debug("Looking for data source #{source}")
          #binding.pry
          foreman["#{source}?format=yaml"].get
        end
      end
    end
  end
end
