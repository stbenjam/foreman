module ProxyAPI
  class Realm < Resource

    def initialize args
      @url  = args[:url] + "/realm"
      super args
    end

    # Creates a Realm Host entry
    # [+fqdn+] : String containing the FQDN of the host
    # Returns  : String containing join password
    def set args
      parse post(args, "")
      return response.body.present? ? JSON.parse(response.body) : true
    end

    # Deletes a Realm Host entry
    # [+key+] : String containing a FQDN
    # Returns    : Boolean status
    def delete key
      parse(super("#{key}"))
    rescue RestClient::ResourceNotFound
      # entry doesn't exists anyway
      return true
    end
  end


end
