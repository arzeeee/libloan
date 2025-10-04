class CreateLoans < ActiveRecord::Migration[7.1]
  def change
    create_table :loans do |t|
      t.references :book, null: false, foreign_key: true
      t.references :borrower, null: false, foreign_key: true
      t.datetime :borrowed_at
      t.datetime :due_date
      t.datetime :returned_at
      t.string :status

      t.timestamps
    end
  end
end
