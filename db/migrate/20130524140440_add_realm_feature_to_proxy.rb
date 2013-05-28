class AddRealmFeatureToProxy < ActiveRecord::Migration
  def self.up
    Feature.find_or_create_by_name("Realm")
  end

  def self.down
  end
end
