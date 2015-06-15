require 'helper'
require 'securerandom'

require 'sshkit/backends/netssh_global_as'

module SSHKit
  module Backend
    class TestNetsshGlobalAsFunctional < FunctionalTest
      def setup
        super
        NetsshGlobalAs.configure do |config|
          config.owner = 'owner'
        end
      end

      def a_host
        VagrantWrapper.hosts['one']
      end

      def test_upload_file
        file_contents = ""
        file_owner = nil
        file_name = File.join("/tmp", SecureRandom.uuid)
        File.open file_name, 'w+' do |f|
          f.write 'example_file'
        end

        NetsshGlobalAs.new(a_host) do
          upload!(file_name, file_name)
          file_contents = capture(:cat, file_name)
          file_owner = capture(:stat, '-c', '%U',  file_name)
        end.run

        assert_equal 'example_file', file_contents
        assert_equal 'owner', file_owner
      end
    end
  end
end
