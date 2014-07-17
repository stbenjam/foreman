class AddAttrsToConfigTemplate < ActiveRecord::Migration
  def change
    add_column :config_templates, :attrs, :text
  end
end
