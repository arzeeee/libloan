class CreateBorrowers < ActiveRecord::Migration[7.1]
  def change
    create_table :borrowers do |t|
      t.string :id_card_number
      t.string :name
      t.string :email

      t.timestamps
    end
  end
end
