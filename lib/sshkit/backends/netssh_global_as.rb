require 'sshkit/command_sudo_ssh_forward'

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

      def pwd
        @pwd.nil? ? nil : File.join(@pwd)
      end

      def ssh_commands
        [:'ssh-add']
      end

      def with_ssh
        host.ssh_options = NetsshGlobalAs.config.ssh_options.merge(host.ssh_options || {})
        conn = self.class.pool.checkout(
          String(host.hostname),
          host.username,
          host.netssh_options,
          &Net::SSH.method(:start)
        )
        begin
          yield conn.connection
        ensure
          self.class.pool.checkin conn
        end
      end

      def command(*args)
        options = args.extract_options!
        SSHKit::CommandSudoSshForward.new(*[*args, options.merge({in: pwd, env: @env, host: @host, user: user, group: @group, ssh_commands: ssh_commands})])
      end
    end
  end
end
