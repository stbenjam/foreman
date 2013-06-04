module Orchestration::Realm
  def self.included(base)
    base.send :include, InstanceMethods
    base.class_eval do
      attr_reader :realm
      after_validation :queue_realm
      before_destroy :queue_realm_destroy unless Rails.env == "test"
    end
  end

  module InstanceMethods

    protected
#    def initialize_realm
#      logger.debug "Initializing Realm"
#      return unless realm?
#      return unless Setting[:manage_realm]
#      @realm = ProxyAPI::Realm.new :url => realm_proxy.url
#      true
#    rescue => e
#      failure _("Failed to initialize the Realm proxy: %s") % e
#    end

    # Removes the host's registration from the Kerberos server
    def delRegistration
      logger.info "Delete Realm registration for #{name}"
      realm.del_host name
    rescue => e
      failure _("Failed to remove %{name}'s Realm registration: %{e}") % { :name => name, :e => proxy_error(e) }
    end

    # Empty method for rollbacks - maybe in the future we would support creating the registrations directly
    def setRegistration
      logger.info "Add Realm registration for #{name}"
      realm.add_host name
    rescue => e
      failure _("Failed to remove %{name}'s Realm registration: %{e}") % { :name => name, :e => proxy_error(e) }
    end

    # Adds the host's name to the otp.conf file
    def setOtp
      logger.info "Adding otp entry for #{name}"
      realm.set_otp otp
    rescue => e
      failure _("Failed to add %{name} to otp file: %{e}") % { :name => name, :e => proxy_error(e) }
    end

    # Removes the host's name from the otp.conf file
    def delOtp
      logger.info "Delete the otp entry for #{name}"
      realm.del_otp otp
    rescue => e
      failure _("Failed to remove %{self} from the otp file: %{e}") % { :self => self, :e => proxy_error(e) }
    end

    private

    def queue_realm
      logger.debug "Queueing Realm"
      return unless realm? and errors.empty?
      return unless Setting[:manage_realm]
      new_record? ? queue_realm_create : queue_realm_update
    end

    # Realm is set only when a provisioning script (such as a kickstart) is being requested.
    def queue_realm_create
      # Host has been built --> remove host from realm
        queue.create(:name => _("Delete otp entry for %s") % self, :priority => 50,
                     :action => [self, :delOtp])
    end

    # we don't perform any actions upon update
    def queue_realm_update; end

    def queue_realm_destroy
      return unless realm? and errors.empty?
      return unless Setting[:manage_realm]
      queue.create(:name => _("Delete Realm registration for %s") % self, :priority => 50,
                   :action => [self, :delRegistration])
      queue.create(:name => _("Delete Realm registration for %s") % self, :priority => 55,
                   :action => [self, :delOtp])
    end
  end
end
