FactoryBot.define do
  factory :borrower do
    sequence(:id_card_number) { |n| "ID#{n.to_s.rjust(6, '0')}" }
    sequence(:name) { |n| "Borrower Name #{n}" }
    sequence(:email) { |n| "borrower#{n}@example.com" }
  end
end
