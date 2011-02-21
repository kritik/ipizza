module Ipizza
  class Request
    
    attr_accessor :extra_params
    attr_accessor :sign_params
    attr_accessor :service_url
    attr_accessor :mac
    
    def sign(privkey_path, privkey_secret, order, mac_param = 'VK_MAC')
      util = Ipizza::Util.new
      signature = util.sign(privkey_path, privkey_secret, util.mac_data_string(sign_params, order))
      @mac = util.mac
      self.sign_params[mac_param] = signature
    end
    
    def request_params
      sign_params.merge(extra_params)
    end
  end
end
