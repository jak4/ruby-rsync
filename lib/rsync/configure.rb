module Rsync
  module Configure
    VALID_OPTION_KEYS = [
      :host,
      :host_user,
      :src_host,
      :src_host_user
    ].freeze

    attr_accessor *VALID_OPTION_KEYS
    
    def configure
      yield self
    end    
  end
end
