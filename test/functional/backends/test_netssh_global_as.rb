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

      def test_capture
        File.open('/dev/null', 'w') do |dnull|
          SSHKit.capture_output(dnull) do
            captured_command_result = nil
            NetsshGlobalAs.new(a_host) do |host|
              captured_command_result = capture(:uname)
            end.run

            assert captured_command_result
            assert_match captured_command_result, /Linux|Darwin/
          end
        end
      end

      def test_ssh_option_merge
        a_host.ssh_options = { paranoid: true }
        host_ssh_options = {}
        SSHKit::Backend::NetsshGlobalAs.config.ssh_options = { forward_agent: false }
        NetsshGlobalAs.new(a_host) do |host|
          capture(:uname)
          host_ssh_options = host.ssh_options
        end.run
        assert_equal({ forward_agent: false, paranoid: true }, host_ssh_options)
      end

      def test_execute_raises_on_non_zero_exit_status_and_captures_stdout_and_stderr
        err = assert_raises SSHKit::Command::Failed do
          NetsshGlobalAs.new(a_host) do |host|
            execute :echo, "\"User $(whoami) on stderr\" 1>&2; false"
          end.run
        end
        assert_equal "echo exit status: 1\necho stdout: Nothing written\necho stderr: User owner on stderr\n", err.message
      end

      def test_test_does_not_raise_on_non_zero_exit_status
        NetsshGlobalAs.new(a_host) do |host|
          test :false
        end.run
      end

      def test_test_executes_as_owner_when_command_contains_no_spaces
        result = NetsshGlobalAs.new(a_host) do |host|
          test 'test', '"$USER" = "owner"'
        end.run

        assert(result, 'Expected test to execute as "owner", but it did not')
      end

      def test_test_executes_as_ssh_user_when_command_contains_spaces
        result = NetsshGlobalAs.new(a_host) do |host|
          test 'test "$USER" = "vagrant"'
        end.run

        assert(result, 'Expected test to execute as "vagrant", but it did not')
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

      def test_upload_string_io
        file_contents = ""
        file_owner = nil
        NetsshGlobalAs.new(a_host) do |host|
          file_name = File.join("/tmp", SecureRandom.uuid)
          upload!(StringIO.new('example_io'), file_name)
          file_contents = download!(file_name)
          file_owner = capture(:stat, '-c', '%U',  file_name)
        end.run
        assert_equal "example_io", file_contents
        assert_equal 'owner', file_owner
      end

      def test_upload_large_file
        size      = 25
        fills     = SecureRandom.random_bytes(1024*1024)
        file_name = "/tmp/file-#{SecureRandom.uuid}-#{size}.txt"
        File.open(file_name, 'w') do |f|
          (size).times {f.write(fills) }
        end

        file_contents = ""
        NetsshGlobalAs.new(a_host) do
          upload!(file_name, file_name)
          file_contents = download!(file_name)
        end.run

        assert_equal File.open(file_name).read, file_contents
      end
    end
  end
end
