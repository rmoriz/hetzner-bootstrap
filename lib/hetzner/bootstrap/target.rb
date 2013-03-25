require 'erubis'
require 'net/ssh'
require 'socket'
require 'timeout'

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
      attr_accessor :post_install_remote
      attr_accessor :public_keys
      attr_accessor :bootstrap_cmd
      attr_accessor :logger

      def initialize(options = {})
        @rescue_os     = 'linux'
        @rescue_os_bit = '64'
        @retries       = 0
        @bootstrap_cmd = 'export TERM=xterm; /root/.oldroot/nfs/install/installimage -a -c /tmp/template'
        @login         = 'root'

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
          @password = result['rescue']['password']
          reset_retries
          logger.info "IP: #{ip} => password: #{@password}"
        elsif @retries > 3
          logger.error "rescue system could not be activated"
          raise CantActivateRescueSystemError, result
        else
          @retries += 1

          logger.warn "problem while trying to activate rescue system (retries: #{@retries})"
          @api.disable_rescue! @ip

          rolling_sleep
          enable_rescue_mode options
        end
      end

      def reset(options = {})
        result = @api.reset! @ip, :hw

        if result.success?
          reset_retries
        elsif @retries > 3
          logger.error "resetting through webservice failed."
          raise CantResetSystemError, result
        else
          @retries += 1
          logger.warn "problem while trying to reset/reboot system (retries: #{@retries})"
          rolling_sleep
          reset options
        end
      end

      def port_open? ip, port
        ssh_port_probe = TCPSocket.new ip, port
        IO.select([ssh_port_probe], nil, nil, 2)
        ssh_port_probe.close
        true
      end

      def wait_for_ssh_down(options = {})
        loop do
          sleep 2
          Timeout::timeout(4) do
            if port_open? @ip, 22
              logger.debug "SSH UP"
            else
              raise Errno::ECONNREFUSED
            end
          end
        end
      rescue Timeout::Error, Errno::ECONNREFUSED
        logger.debug "SSH DOWN"
      end

      def wait_for_ssh_up(options = {})
        loop do
          Timeout::timeout(4) do
            if port_open? @ip, 22
              logger.debug "SSH UP"
              return true
            else
              raise Errno::ECONNREFUSED
            end
          end
        end
      rescue Errno::ECONNREFUSED, Timeout::Error
        logger.debug "SSH DOWN"
        sleep 2
        retry
      end

      def installimage(options = {})
        template = render_template

        remote do |ssh|
          ssh.exec! "echo \"#{template}\" > /tmp/template"
          logger.info "remote executing: #{@bootstrap_cmd}"
          output = ssh.exec!(@bootstrap_cmd)
          logger.info output
        end
      end

      def reboot(options = {})
        remote do |ssh|
          ssh.exec!("reboot")
        end
      end

      def verify_installation(options = {})
        remote do |ssh|
          working_hostname = ssh.exec!("cat /etc/hostname")
          unless @hostname == working_hostname.chomp
            raise InstallationError, "hostnames do not match: assumed #{@hostname} but received #{working_hostname}"
          end
        end
      end

      def copy_ssh_keys(options = {})
        if @public_keys
          remote do |ssh|
            ssh.exec!("mkdir /root/.ssh")
            Array(@public_keys).each do |key|
              pub = File.read(File.expand_path(key))
              ssh.exec!("echo \"#{pub}\" >> /root/.ssh/authorized_keys")
            end
          end
        end
      end

      def update_local_known_hosts(options = {})
        remote(:paranoid => true) do |ssh|
          # dummy
        end
      rescue Net::SSH::HostKeyMismatch => e
        e.remember_host!
        logger.info "remote host key added to local ~/.ssh/known_hosts file."
      end

      def post_install(options = {})
        return unless @post_install

        post_install = render_post_install
        logger.info "executing post_install:\n #{post_install}"

        output = local do
          `#{post_install}`
        end

        logger.info output
      end

      def post_install_remote(options = {})
        remote do |ssh|
          @post_install_remote.split("\n").each do |cmd|
            cmd.chomp!
            logger.info "executing #{cmd}"
            ssh.exec!(cmd)
          end
        end
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

      def use_api(api_obj)
        @api = api_obj
      end

      def use_logger(logger_obj)
        @logger = logger_obj
        @logger.formatter = default_log_formatter
      end

      def remote(options = {}, &block)

        default = { :paranoid => false, :password => @password }
        default.merge! options

        Net::SSH.start(@ip, @login, default) do |ssh|
          block.call ssh
        end
      end

      def local(&block)
        block.call
      end

      def reset_retries
        @retries = 0
      end

      def rolling_sleep
        sleep @retries * @retries * 3 + 1 # => 1, 4, 13, 28, 49, 76, 109, 148, 193, 244, 301, 364 ... seconds
      end

      def default_log_formatter
         proc do |severity, datetime, progname, msg|
           caller[4]=~/`(.*?)'/
           "[#{datetime.strftime "%H:%M:%S"}][#{sprintf "%-15s", ip}][#{$1}] #{msg}\n"
         end
      end

      class NoTemplateProvidedError < ArgumentError; end
      class CantActivateRescueSystemError < StandardError; end
      class CantResetSystemError < StandardError; end
      class InstallationError < StandardError; end
    end
  end
end
