 
module Ipizza::Provider
    class Estcard
	
	class << self
	    attr_accessor :service_url, :id, :file_key, :file_cert, :key_secret
	end
	
	def payment_request(payment, action = 'gaf', order_id = 0)
	    req = Ipizza::PaymentRequest.new
	    req.service_url = self.class.service_url
	    req.sign_params = {
              'action' => action.to_s,
              "ver"  => '002',
              "id" => self.class.id.to_s,
              "ecuno" => sprintf("%012i", 100000 + payment.stamp),
              "eamount"=> sprintf("%012i",payment.amount*100), #in cents
              "cur" => 'EUR',
              "datetime"=> Time.now.strftime("%Y%m%d%H%M%S")#
	    }

	    req.extra_params = {
               "lang"=>:en
              }
	    @mac = req.mac = generate_mac_string(req.sign_params).strip
            privkey = File.open(self.class.file_key, 'r') { |f| f.read }
            privkey = OpenSSL::PKey::RSA.new(privkey.gsub(/  /, ''), self.class.key_secret)

            signature = privkey.sign(OpenSSL::Digest::SHA1.new, req.mac)
# 	    signature = Ipizza::Util.sign(self.class.file_key, self.class.key_secret, req.mac)
	    req.extra_params["mac"] = signature.unpack('H*')
	    req
	end
	
	def payment_response(params)
          #http://zorro.ee:3000/bank/estcard/return?action=afb&ver=2&id=Progroup&ecuno=100049&receipt_no=00245&eamount=50&cur=EUR&respcode=000&datetime=20110412180817&msgdata=Vladimir&actiontext=OK%2C+approved&mac=5497715417E60AF190D0A1FDDE94ECF3464596EF5B1B7287D4FABBC670CBA2219EC490D504DAF4317814DD3678A1FD8E71DA86F51C8A6D4309356EFDFE090162697E3D27B51F09ED4570F69F0A7C46C5DFC3AB663A3965D3DF466EEB222854EE0C6BD9019DE532DF9C24D4A6A3E10A3AD4F580C046D74D88D7A5650C3C317B4B
	    params["action"] = "afb"
            response = Ipizza::PaymentResponse.new(params)
	    @mac = generate_mac_string(params)
            response.mac = @mac
            
            #verifying
            certificate = OpenSSL::PKey::RSA.new(File.read(self.class.file_cert).gsub(/  /, '')).public_key
            return response unless params["respcode"].eql?("000")
            return response unless params["id"].to_s.eql?(self.class.id.to_s)
            
            response.valid = certificate.verify(OpenSSL::Digest::SHA1.new, [params["mac"]].pack('H*'), response.mac)
	    return response
	end

	private
	def generate_mac_string(fields)
	    return '' unless fields.is_a?(Hash)
	    temp = {}
	    fields.each{|key,value| temp[key.to_s] = value.to_s }
	    fields = temp
	    
	    result = '';
	    if(fields["action"] == "gaf")
	      result << fields["ver"]
              result << sprintf("%-10s", fields['id'])
              result << fields["ecuno"]
              result << fields["eamount"]
              result << fields["cur"]
              result << fields["datetime"];
	    elsif(fields["action"] == "afb")
              fields["ver"]        = sprintf("%03i", fields['ver'])
              fields['eamount']    = sprintf("%012i", fields['eamount'].to_i)
              fields['ecuno']      = sprintf("%012i", fields['ecuno'].to_i)
              fields['receipt_no'] = sprintf("%06i", fields['receipt_no'].to_i)
              fields['msgdata']    = sprintf("%-40s", fields['msgdata'])
              fields['actiontext'] = sprintf("%-40s", fields['actiontext'])
              fields['id']         = sprintf("%-10s", fields['id'])
              result << fields["ver"]+fields["id"]+fields["ecuno"]+fields["receipt_no"]+fields["eamount"]+fields["cur"]+fields["respcode"]+fields["datetime"]+fields["msgdata"]+fields["actiontext"]
	    end
	    result
	end
    end
end