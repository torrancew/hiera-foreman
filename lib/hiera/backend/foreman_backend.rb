class Hiera
  module Backend
    class Foreman_backend
      def initialize
        Hiera.debug("Hiera Foreman backend starting")
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = Backend.empty_answer(resolution_type)
        Hiera.debug("Looking up #{key} in Foreman backend")
        Hiera.debug("Checking scope #{scope.inspect} with #{order_override.inspect} (looking for #{resolution_type})")
      end
    end
  end
end
