class AddUntappdIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :untappd_id, :string
  end
end
