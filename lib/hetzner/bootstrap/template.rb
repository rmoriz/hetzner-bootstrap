module Hetzner
  class Bootstrap
    class Template
      attr_accessor :raw_template

      def initialize(param)
        # Available templating configurations can be found after
        # manually booting the rescue system, then reading the
        # hetzner templates at:
        #
        #   /root/.oldroot/nfs/install/configs/
        #
        # also run:   $ installimage -h
        #
        if param.is_a? Hetzner::Bootstrap::Template
          return param
        elsif param.is_a? String
          @raw_template = param
        end
      end

      def to_s
        @raw_template
      end
    end
  end
end