class AddOsHashToConfigTemplate < ActiveRecord::Migration
  def change
    add_column :config_templates, :os_hash, :text
  end
end
