require 'erubis'
require 'net/ssh'
require 'socket'

module Hetzner
  class Bootstrap
    class Target
      attr_accessor :ip
      attr_accessor :login
      attr_accessor :password
      attr_accessor :template
      attr_accessor :rescue_os
      attr_accessor :rescue_os_bit
      attr_accessor :actions
      attr_accessor :hostname
      attr_accessor :post_install
      attr_accessor :public_keys
      attr_accessor :bootstrap_cmd
      
      def initialize(options = {})
        @rescue_os     = 'linux'
        @rescue_os_bit = '64'
        @retries       = 0
        @bootstrap_cmd = '/root/.oldroot/nfs/install/installimage -a -c /tmp/template'
        
        if tmpl = options.delete(:template)
          @template = Template.new tmpl
        else
          raise NoTemplateProvidedError.new 'No imageinstall template provided.'
        end
        
        options.each_pair do |k,v|
          self.send("#{k}=", v)
        end
      end

      def enable_rescue_mode(options = {})
        result = @api.enable_rescue! @ip, @rescue_os, @rescue_os_bit

        if result.success? && result['rescue']
          @login    = 'root'
          @password = result['rescue']['password']
          reset_retries
          puts "IP: #{ip} => password: #{@password}"
        elsif @retries > 3
          raise CantActivateRescueSystemError, result
        else
          @retries += 1

          puts "problem while trying to activate rescue system (retries: #{@retries})"
          @api.disable_rescue! @ip
          
          sleep @retries * 5 # => 5, 10, 15s
          enable_rescue_mode options
        end
      end

      def reset(options = {})
        result = @api.reset! @ip, :hw

        if result.success?
          reset_retries
          sleep 10
        elsif @retries > 3
          raise CantResetSystemError, result
        else
          @retries += 1
          rolling_sleep
          puts "problem while trying to reset/reboot system (retries: #{@retries})"
          reset options
        end
      end

      def wait_for_ssh(options = {})
        ssh_port_probe = TCPSocket.new @ip, 22
        return if IO.select([ssh_port_probe], nil, nil, 5)

      rescue Errno::ECONNREFUSED
        @retries += 1
        print "."
        STDOUT.flush

        if @retries > 20
          raise CantSshAfterResetError
        else
          rolling_sleep
          wait_for_ssh options
        end
      rescue => e
        puts "Exception: #{e.class} #{e.message}"
      ensure
        puts ""
        ssh_port_probe && ssh_port_probe.close
      end

      def installimage(options = {})
        template = render_template

        Net::SSH.start(@ip, @login, :password => @password) do |ssh|
          ssh.exec!("echo \"#{template}\" > /tmp/template")
          puts "remote executing: #{@bootstrap_cmd}"
          output = ssh.exec!(@bootstrap_cmd)
          puts output
          ssh.exec!("reboot")
          sleep 4
        end
      rescue Net::SSH::HostKeyMismatch => e
        e.remember_host!
        retry
      end

      def verify_installation(options = {})
        Net::SSH.start(@ip, @login, :password => @password) do |ssh|
          working_hostname = ssh.exec!("cat /etc/hostname")
          unless @hostname == working_hostname.chomp
            raise InstallationError, "hostnames do not match: assumed #{@hostname} but received #{working_hostname}"
          end
        end
      rescue Net::SSH::HostKeyMismatch => e
        e.remember_host!
        retry
      end

      def copy_ssh_keys(options = {})
        if @public_keys
          Net::SSH.start(@ip, @login, :password => @password) do |ssh|
            ssh.exec!("mkdir /root/.ssh")
            @public_keys.to_a.each do |key|
              pub = File.read(File.expand_path(key))
              ssh.exec!("echo \"#{pub}\" >> /root/.ssh/authorized_keys")
            end
          end
        end
      rescue Net::SSH::HostKeyMismatch => e
        e.remember_host!
        retry
      end

      def post_install(options = {})
        return unless @post_install
        post_install = render_post_install
        puts "executing:\n #{post_install}"
        `#{post_install}`
      end

      def render_template
        eruby = Erubis::Eruby.new @template.to_s

        params = {}
        params[:hostname] = @hostname
        params[:ip]       = @ip

        return eruby.result(params)
      end

      def render_post_install
        eruby = Erubis::Eruby.new @post_install.to_s

        params = {}
        params[:hostname] = @hostname
        params[:ip]       = @ip
        params[:login]    = @login
        params[:password] = @password
        
        return eruby.result(params)
      end

      def use_api(api)
        @api = api
      end

      def reset_retries
        @retries = 0
      end

      def rolling_sleep
        sleep @retries * @retries * 3 + 1 # => 1, 4, 13, 28, 49, 76, 109, 148, 193, 244, 301, 364 ... seconds
      end

      class NoTemplateProvidedError < ArgumentError; end
      class CantActivateRescueSystemError < StandardError; end
      class CantResetSystemError < StandardError; end
      class InstallationError < StandardError; end
    end
  end
end
