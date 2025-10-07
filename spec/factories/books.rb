FactoryBot.define do
  factory :book do
    sequence(:title) { |n| "Book Title #{n}" }
    sequence(:isbn) { |n| "978-0-#{n.to_s.rjust(9, '0')}" }
    stock { 5 }

    trait :out_of_stock do
      stock { 0 }
    end

    trait :low_stock do
      stock { 1 }
    end
  end
end
