 
module Ipizza::Provider
    class Estcard
	
	class << self
	    attr_accessor :service_url, :id
	end
	
	def payment_request(payment, action = 'gaf', order_id = 0)
	    req = Ipizza::PaymentRequest.new
	    req.service_url = self.class.service_url
	    req.sign_params = {
              'action' => action.to_s,
              "ver"  => '002',
              "id" => self.class.id,
              "ecuno" => sprintf("%012s", 100000 + order_id),
              "eamount"=> payment.amount,
              "cur" => 'EUR',
              "datetime"=> Time.now.strftime("%Y%m%d%H%M%S")
	    }

	    req.extra_params = {}
	    @mac = req.mac = generate_mac_string(req.sign_params)
	    p @mac
	    signature = Ipizza::Util.sign(self.class.file_key, self.class.key_secret, param_order)
	    req.merge({"mac" => signature.split(//).unpack('H*')})
	    req
	end
	
	def payment_response(params)
	    response = Ipizza::PaymentResponse.new(params)
	    @mac = response.mac = generate_mac_string(params)
	    response.valid = Ipizza::Util.verify_signature(self.class.file_cert, params["mac"].split(//).pack('H*'), @mac)
	    
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
	      result << fields["ver"]+fields["id"]+fields["ecuno"]+fields["eamount"]+fields["cur"]+fields["datetime"];
	    elsif(fields["action"] == "afb")
	    fields["ver"] = sprintf("%03s", fields['ver'])
	    fields['eamount'] = sprintf("%012s", fields['eamount'])
	    fields['ecuno'] = sprintf("%012s", fields['ecuno'])
	    fields['receipt_no'] = sprintf("%06s", fields['receipt_no'])
	    fields['msgdata'] = sprintf("%-40s", fields['msgdata'])
	    fields['actiontext'] = sprintf("%-40s", fields['actiontext'])
	    fields['id'] = sprintf("%010s", fields['id']);
	    result << fields["ver"]+fields["id"]+fields["ecuno"]+fields["receipt_no"]+fields["eamount"]+fields["cur"]+fields["respcode"]+fields["datetime"]+fields["msgdata"]+fields["actiontext"]
	    end
	    result
	end
    end
end