class CreateCoupons < ActiveRecord::Migration
  def self.up
    create_table :coupons do |t|
      t.references :user
      t.float :stawka
      t.boolean :finished

      t.timestamps
    end
  end

  def self.down
    drop_table :coupons
  end
end
