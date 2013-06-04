class AddRealmMemberToHost < ActiveRecord::Migration
  def change
    add_column :hosts, :realm_member, :boolean
  end
end
