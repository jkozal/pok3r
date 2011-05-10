class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.references :coupon
      t.float :match_id
      t.string :choice
      t.float :multiple

      t.timestamps
    end
  end

  def self.down
    drop_table :events
  end
end
