class CreateBeers < ActiveRecord::Migration
  def change
    create_table :beers do |t|
      t.string :brewery
      t.string :location
      t.string :name
      t.string :style
      t.integer :year
      t.integer :quantity
      t.string :notes
      t.integer :untappd

      t.timestamps
    end
  end
end
