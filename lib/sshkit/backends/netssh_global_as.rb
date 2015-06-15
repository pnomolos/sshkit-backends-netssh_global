module SSHKit
  module Backend
    class NetsshGlobalAs < Netssh
      class Configuration < Netssh::Configuration
        attr_accessor :owner
      end

      class << self
        def config
          @config ||= Configuration.new
        end
      end

      @pool = SSHKit::Backend::ConnectionPool.new

      def upload!(local, remote, options = {})
        super
        as :root do
          # Required as uploaded file is owned by SSH user, not owner
          execute :chown, owner, remote
        end
      end

      private

      def user
        @user || owner
      end

      def owner
        self.class.config.owner
      end
    end
  end
end
