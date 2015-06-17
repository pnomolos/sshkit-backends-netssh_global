require 'sshkit/command_sudo_ssh_forward'

module SSHKit
  module Backend
    class NetsshGlobal < Netssh
      class Configuration < Netssh::Configuration
        attr_accessor :owner, :directory
        attr_writer :ssh_commands

        def ssh_commands
          @ssh_commands || [:ssh, :git, :'ssh-add', :bundle]
        end
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
          execute :chown, property(:owner), remote
        end
      end

      private

      def user
        @user || property(:owner)
      end

      def pwd
        @pwd.nil? ? property(:directory) : File.join(@pwd)
      end

      def property(name)
        host.properties.public_send(name) || self.class.config.public_send(name)
      end

      def with_ssh
        host.ssh_options = NetsshGlobal.config.ssh_options.merge(host.ssh_options || {})
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
        options.merge!(
          in: pwd,
          env: @env,
          host: @host,
          user: user,
          group: @group,
          ssh_commands: property(:ssh_commands)
        )
        SSHKit::CommandSudoSshForward.new(*[*args, options])
      end
    end
  end
end
