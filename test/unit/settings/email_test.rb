require 'test_helper'

module Settings
  class EmailTest < ActiveSupport::TestCase

    context 'with email.yaml' do
      setup do
        email_yaml_hash = {"delivery_method"=>"smtp", "smtp_settings"=>{"address"=>"smtp.example.com", "port"=>465, "tls"=>true, "enable_starttls_auto"=>false, "authentication"=>"none"}}
        Setting::Email.stubs(:mailconfig).returns(email_yaml_hash.with_indifferent_access)
        Setting::Email.load_defaults
      end

      test 'should import settings' do
        assert_equal 'smtp', Setting[:delivery_method]
        assert_equal 'smtp.example.com', Setting[:smtp_address]
        assert_equal 465, Setting[:smtp_port]
        assert_equal true, Setting[:smtp_tls]
        assert_equal false, Setting[:smtp_enable_starttls_auto]
        assert_equal 'none', Setting[:smtp_authentication]
      end

      test 'should mark settings read only' do
        assert Setting.find_by(:name => 'smtp_address').readonly?
      end
    end

    context 'without email.yaml' do
      setup do
        Setting::Email.stubs(:mailconfig).returns({})
        Setting::Email.load_defaults
      end

      test 'settings are not read-noly' do
        refute Setting.find_by(:name => 'smtp_address').readonly?
      end
    end
  end
end
