require 'optparse'
require 'vagrant/util/safe_puts'

module VagrantPlugins
  module VagrantWinRM
    class WinRM < Vagrant.plugin('2', :command)
      def self.synopsis
        'connects to machine via WinRM'
      end

      def execute
        options = { shell: :powershell }

        opts = OptionParser.new do |o|
          o.banner = 'Usage: vagrant winrm [options] [name]'
          o.separator 'Options:'

          o.on('-c', '--command COMMAND', 'Execute a WinRM command directly') do |c|
            options[:command] = Array.new if options[:command].nil?
            options[:command].push c
          end

          o.on('-e', '--elevated', 'Run all commands with elevated credentials') do |e|
            options[:elevated] = true
          end

          o.on('-s', '--shell SHELL', [:powershell, :cmd], 'Use the specified shell (powershell, cmd)') do |s|
            options[:shell] = s
          end

          o.on('--plugin-version', 'Print the version of the plugin and exit') do
            options[:version] = true
          end
        end

        # Parse the options and return if we don't have any target.
        argv = parse_options(opts)
        return unless argv

        if options[:version]
          require "#{VagrantPlugins::VagrantWinRM.source_root}/lib/version"
          safe_puts "Vagrant-winrm plugin #{VERSION}"
          return 0
        end

        return 0 unless options[:command]

        # Execute the actual WinRM command
        with_target_vms(argv, single_target: true) do |vm|

          raise Errors::ConfigurationError, { :communicator => vm.config.vm.communicator } if vm.config.vm.communicator != :winrm

          exit_code = 0
          @logger.debug("Executing a batch of #{options[:command].length} on remote machine with #{options[:shell]}")

          options[:command].each do |c|
            @logger.debug("Executing command: #{c}")
            exit_code |= vm.communicate.execute(c, shell: options[:shell], elevated: options[:elevated], error_check: false) { |type, data| (type == :stderr ? $stderr : $stdout).print data }
          end
          return exit_code
        end
      end
    end
  end
end
