class CreateOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.boolean :paid, :default => false
      t.string :name
      t.string :token
      t.float :price
      t.string :currency
      t.bigint :user_id

      t.timestamps
    end
  end
end
