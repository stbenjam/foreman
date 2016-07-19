require 'facter'

class Setting::Email < Setting
  WHITELIST = %w(send_welcome_email email_reply_address email_subject_prefix)

  def self.load_defaults
    # Check the table exists
    return unless super
    domain = Facter.value(:domain) || SETTINGS[:domain]
    email_reply_address = "Foreman-noreply@#{domain}"

    self.transaction do
      [
       self.set('email_reply_address', N_("Email reply address for emails that Foreman is sending"), email_reply_address, N_('Email reply address')),
       self.set('email_subject_prefix', N_("Prefix to add to all outgoing email"), '[foreman]', N_('Email subject prefix')),
       self.set('send_welcome_email', N_("Send a welcome email including username and URL to new users"), false, N_('Send welcome email')),

       self.set('delivery_method', N_("Method used to deliver e-mail"), 'sendmail', N_('Delivery method'), nil, { :collection => Proc.new {{'sendmail' => :sendmail, 'smtp' => :smtp}}}),
       self.set('smtp_enable_starttls_auto', N_("Use STARTTLS automatically"), false, N_('SMTP enable StartTLS auto')),
       self.set('smtp_tls', N_("Enable SSL/TLS"), false, N_('SMTP use SSL/TLS')),
       self.set('smtp_address', N_("Address to connect to"), '', N_('SMTP address')),
       self.set('smtp_port', N_("Port to connect to"), 25, N_('SMTP port')),
       self.set('smtp_domain', N_("Email domain"), '', N_('SMTP email domain')),
       self.set('smtp_user_name', N_("Username to use to authenticate, if required"), '', N_('SMTP username')),
       self.set('smtp_password', N_("Password to use to authenticate, if required"), '', N_('SMTP password')),
       self.set('smtp_authentication', N_("Specify authentication type here, if required"), 'none', N_('SMTP authentication'), nil, { :collection => Proc.new {{'plain' => :plain, 'login' => :login, 'cram_md5' => :cram_md5, 'none' => :none}}}),
       self.set('sendmail_arguments', N_("Specify additional options to sendmail"), '-i', N_('Sendmail arguments'))
      ].each { |s| self.create! s.update(:category => "Setting::Email")}
    end

    true
  end

  def self.config_file
    File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'email.yaml'))
  end
 
  def self.delivery_settings
    options = {}

    self.all.each do |setting|
      if Setting[:delivery_method] == 'smtp' && setting.name =~ /^smtp_/
        options ||= {}
        options[setting.name.to_s.gsub(/^smtp_/, '')] = setting.value
      elsif setting.name =~ /^sendmail_/
        options ||= {}
        options[setting.name.to_s.gsub(/^sendmail_/, '')] = setting.value
      end
    end

    options
  end

  # Load the configuration from email.yaml, if it exists.  Stored in class instance variable to prevent multiple reads.
  def self.mailconfig
    @mailconfig ||= File.file?(config_file) ? YAML.load_file(config_file).with_indifferent_access : {}
    @mailconfig[Rails.env] if @mailconfig.is_a?(Hash)
  end

  def self.lookup_value(name)
    if name =~ /^smtp_/ && mailconfig[:smtp_settings].is_a?(Hash)
      mailconfig[:smtp_settings][name.to_s.gsub(/^smtp_/, '')]
    elsif name =~ /^sendmail_/ && mailconfig[:sendmail_settings].is_a?(Hash)
      mailconfig[:sendmail_settings][name.to_s.gsub(/^smtp_/, '')]
    else
      mailconfig[name]
    end
  end

  def self.readonly_value(name)
    return unless !mailconfig.blank?
    lookup_value(name)
  end

  def has_readonly_value?
    !self.class.mailconfig.blank? && !WHITELIST.include?(name)
  end
end
