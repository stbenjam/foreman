require 'uri'

class ApplicationMailer < ActionMailer::Base
  include Roadie::Rails::Automatic
  after_filter :set_configurations unless Setting[:email_yaml]
  default :from => Proc.new { Setting[:email_reply_address] || "noreply@foreman.example.org" }
  self.delivery_method = Setting[:delivery_method] unless Setting[:email_yaml]

  def mail(headers = {}, &block)
    if headers.present?
      headers[:subject] = "#{Setting[:email_subject_prefix]} #{headers[:subject]}" if (headers[:subject] && !Setting[:email_subject_prefix].blank?)
      headers['X-Foreman-Server'] = URI.parse(Setting[:foreman_url]).host unless Setting[:foreman_url].blank?
    end
    super
  end

  protected

  def roadie_options
    url = URI.parse(Setting[:foreman_url])
    super.merge(url_options: {:host => url.host, :port => url.port, :protocol => url.scheme})
  end

  def smtp_options
    {
      address:              Setting[:smtp_address],
      port:                 Setting[:smtp_port],
      user_name:            Setting[:smtp_user],
      password:             Setting[:smtp_password],
      authentication:       Setting[:smtp_auth]
    }
  end

  private

  def set_locale_for(user)
    old_loc = FastGettext.locale
    begin
      FastGettext.set_locale(user.locale.blank? ? 'en' : user.locale)
      yield if block_given?
    ensure
      FastGettext.locale = old_loc if block_given?
    end
  end

  def set_url
    unless (@url = URI.parse(Setting[:foreman_url])).present?
      raise Foreman::Exception.new(N_(":foreman_url is not set, please configure in the Foreman Web UI (Administer -> Settings -> General)"))
    end
  end

  def set_configurations
    mail.delivery_method.settings.merge!(smtp_options)
  end
end
