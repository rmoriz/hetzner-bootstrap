require 'hetzner-api'
require 'hetzner/bootstrap/version'
require 'hetzner/bootstrap/target'
require 'hetzner/bootstrap/template'

module Hetzner
  class Bootstrap
    attr_accessor :targets
    attr_accessor :api
    attr_accessor :use_threads
    attr_accessor :actions

    def initialize(options = {})
      @targets     = []
      @actions     = %w(enable_rescue_mode
                        reset
                        wait_for_ssh
                        installimage
                        wait_for_ssh
                        verify_installation
                        copy_ssh_keys
                        post_install)
      @api         = options[:api]
      @use_threads = options[:use_threads] || true
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
      threads = []

      @targets.each do |target|
        target.use_api @api
        
        if uses_threads?
          threads << Thread.new do
            bootstrap_one_target! target
          end
        else
          bootstrap_one_target! target
        end
      end

      finalize_threads(threads) if uses_threads?
    end

    def bootstrap_one_target!(target)
      actions = (target.actions || @actions)
      actions.each_with_index do |action, index|
        
        log target.ip, action, index, 'START'
        d = Benchmark.realtime do
          target.send action
        end

        log target.ip, action, index, "FINISHED in #{sprintf "%.5f",d} seconds"
      end
    rescue => e
      puts "something bad happend: #{e.class} #{e.message}"
    end

    def uses_threads?
      @use_threads
    end

    def finalize_threads(threads)
      threads.each { |t| t.join }
    end

    def log(where, what, index, message)
      puts "[#{where}] #{what} #{' ' * (index * 4)}#{message}"
    end
  end
end