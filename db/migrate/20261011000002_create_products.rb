class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.integer :total_stock, null: false
      t.integer :available_stock, null: false
      t.integer :reserved_stock, null: false

      t.timestamps
    end

    add_check_constraint :products, "total_stock >= 0",
      name: "products_total_stock_non_negative"
    add_check_constraint :products, "available_stock >= 0",
      name: "products_available_stock_non_negative"
    add_check_constraint :products, "reserved_stock >= 0",
      name: "products_reserved_stock_non_negative"
    add_check_constraint :products, "available_stock + reserved_stock = total_stock",
      name: "products_stock_conservation"
  end
end
