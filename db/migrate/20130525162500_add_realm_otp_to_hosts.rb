class AddRealmOtpToHosts < ActiveRecord::Migration
  def self.up
    add_column :hosts, :realm_otp, :string
  end

  def self.down
    remove_column :hosts, :realm_otp
  end
end
