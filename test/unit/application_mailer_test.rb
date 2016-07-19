require 'test_helper'

class ApplicationMailerTest < ActiveSupport::TestCase
  setup do
    ActionMailer::Base.deliveries = []
    Setting::Email.load_defaults
    Setting[:delivery_method] = :test
  end

  class TestMailer < ::ApplicationMailer
    def test
      mail(:to => 'nobody@example.com', :subject => 'Danger, Will Robinson!') do |format|
        format.html { render :text =>  html_mail }
      end
    end

    def html_mail
      %|<html>
          <head>
            <meta content="text/html; charset=UTF-8" http-equiv="Content-Type" />
            <link href="/assets/unimported/email.css" media="screen" rel="stylesheet" />
          </head>
          <body>
            <h2 class="headline"><b>Foreman</b> test email</h2>
          </body>
        </html>|.html_safe
    end
  end

  def mail
    TestMailer.test.deliver_now
    ActionMailer::Base.deliveries.last
  end

  test 'foreman server header is set' do
    assert_equal mail.header['X-Foreman-Server'].to_s, 'foreman.some.host.fqdn'
  end

  test 'application mailer can use external css' do
    assert mail.body.include? 'style='
  end

  test 'foreman subject prefix is attached' do
    Setting[:email_subject_prefix] = '[foreman-production]'
    assert_match /^\[foreman-production\]/, mail.subject
  end

  # The ActionMailer default is only evaluated at initialization so changes
  # were only registered after a restart.  The from address is now a lambda.
  test 'reply address evalulated at send time' do
    new_from = 'foreman@widgets.example.com'
    Setting[:email_reply_address] = new_from
    assert_equal mail.from.first, new_from
  end

  test 'email settings are configured dynamically' do
    Setting[:delivery_method] = 'smtp'
    Setting[:smtp_address] = 'smtp.example.com'
    mail_obj = TestMailer.test
    assert_instance_of Mail::SMTP, mail_obj.delivery_method
    assert_equal mail_obj.delivery_method.settings[:address], 'smtp.example.com'
  end
end
