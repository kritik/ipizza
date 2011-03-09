module Ipizza
  class Request
    
    attr_accessor :extra_params
    attr_accessor :sign_params
    attr_accessor :service_url
    attr_accessor :mac
    
    def sign(privkey_path, privkey_secret, order, mac_param = 'VK_MAC')
      @mac = Ipizza::Util.mac_data_string(sign_params, order, 'UTF-8', 'UTF-8', @extra_params)
      signature = Ipizza::Util.sign(privkey_path, privkey_secret, @mac)
      self.sign_params[mac_param] = signature
    end
    
    def request_params
      sign_params.merge(extra_params)
    end
  end
end
