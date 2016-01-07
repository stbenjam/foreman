class Setting::Email < Setting
  def self.load_defaults
    return unless super
    smtp_options = ActionMailer::Base.smtp_settings || {}
    method = ActionMailer::Base.delivery_method
    self.transaction do
      [
        self.set('email_yaml', N_("Uses email.yaml configurations instead"), false, N_('YAML conifguration')),
        self.set('delivery_method', N_("Delivery method can be smtp or sendmail"), method, N_('Delivery Method')),
        self.set('smtp_address', N_("SMTP server address"), smtp_options[:address], N_('Address')),
        self.set('smtp_port', N_("SMTP server port"), smtp_options[:port], N_('Port')),
        self.set('smtp_auth', N_("Authentication type, can be none, plain, login and cram_md5."), smtp_options[:authentication], N_('Authentication')),
        self.set('smtp_user', N_("Required when the authentication type is not none"), smtp_options[:user_name], N_('Username')),
        self.set('smtp_password', N_("Required when the authentication type is not none"), smtp_options[:password], N_('Password'))
      ].compact.each { |s| self.create! s.update(:category => "Setting::Email")}
      true
    end
  end
end
