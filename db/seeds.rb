# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

Loan.destroy_all
Book.destroy_all
Borrower.destroy_all

books = Book.create!([
  { title: "The Great Gatsby", isbn: "978-0-7432-7356-5", stock: 5 },
  { title: "To Kill a Mockingbird", isbn: "978-0-06-112008-4", stock: 3 },
  { title: "1984", isbn: "978-0-452-28423-4", stock: 4 },
  { title: "Pride and Prejudice", isbn: "978-0-14-143951-8", stock: 2 },
  { title: "The Catcher in the Rye", isbn: "978-0-316-76948-0", stock: 6 }
])

borrowers = Borrower.create!([
  { id_card_number: "ID001", name: "John Doe", email: "john.doe@email.com" },
  { id_card_number: "ID002", name: "Jane Smith", email: "jane.smith@email.com" },
  { id_card_number: "ID003", name: "Bob Johnson", email: "bob.johnson@email.com" },
  { id_card_number: "ID004", name: "Alice Brown", email: "alice.brown@email.com" },
  { id_card_number: "ID005", name: "Charlie Wilson", email: "charlie.wilson@email.com" }
])

loan1 = Loan.create!(
  book: books[0],
  borrower: borrowers[0],
  borrowed_at: 5.days.ago,
  due_date: 5.days.ago + 20.days,
  status: 'active'
)


loan2 = Loan.create!(
  book: books[1],
  borrower: borrowers[1],
  borrowed_at: 35.days.ago,
  due_date: 35.days.ago + 25.days,
  status: 'active'
)
loan2.update_column(:status, 'overdue')

loan3 = Loan.create!(
  book: books[2],
  borrower: borrowers[2],
  borrowed_at: 20.days.ago,
  due_date: 20.days.ago + 15.days,
  status: 'active'
)
loan3.return_book!

puts "Seeded database count:"
puts "- #{Book.count} books"
puts "- #{Borrower.count} borrowers" 
puts "- #{Loan.count} loans"
