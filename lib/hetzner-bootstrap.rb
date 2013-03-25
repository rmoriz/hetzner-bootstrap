require 'benchmark'
require 'logger'

require 'hetzner-api'
require 'hetzner/bootstrap/version'
require 'hetzner/bootstrap/target'
require 'hetzner/bootstrap/template'

module Hetzner
  class Bootstrap
    attr_accessor :targets
    attr_accessor :api
    attr_accessor :actions
    attr_accessor :logger

    def initialize(options = {})
      @targets     = []
      @actions     = %w(enable_rescue_mode
                        reset
                        wait_for_ssh_down
                        wait_for_ssh_up
                        installimage
                        reboot
                        wait_for_ssh_down
                        wait_for_ssh_up
                        verify_installation
                        copy_ssh_keys
                        update_local_known_hosts
                        post_install
                        post_install_remote)
      @api         = options[:api]
      @logger      = options[:logger] || Logger.new(STDOUT)
    end

    def add_target(param)
      if param.is_a? Hetzner::Bootstrap::Target
        @targets << param
      else
        @targets << (Hetzner::Bootstrap::Target.new param)
      end
    end

    def <<(param)
      add_target param
    end

    def bootstrap!(options = {})
      @targets.each do |target|
        #fork do
          target.use_api    @api
          target.use_logger @logger
          bootstrap_one_target! target
        #end
      end
      #Process.waitall
    end

    def bootstrap_one_target!(target)
      actions = (target.actions || @actions)
      actions.each_with_index do |action, index|

        loghack = "\b" * 24 # remove: "[bootstrap_one_target!] ".length
        target.logger.info "#{loghack}[#{action}] #{sprintf "%-20s", "START"}"
        d = Benchmark.realtime do
          target.send action
        end
        target.logger.info "#{loghack}[#{action}] FINISHED in #{sprintf "%.5f",d} seconds"
      end
    rescue => e
      puts "something bad happened unexpectedly: #{e.class} => #{e.message}"
    end
  end
end

