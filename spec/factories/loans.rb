FactoryBot.define do
  factory :loan do
    association :book
    association :borrower
    borrowed_at { Time.current }
    due_date { Time.current + 20.days }
    status { 'active' }

    trait :overdue do
      borrowed_at { 35.days.ago }
      due_date { 35.days.ago + 25.days }
      status { 'overdue' }
    end

    trait :returned do
      borrowed_at { 20.days.ago }
      due_date { 20.days.ago + 25.days }
      returned_at { 5.days.ago }
      status { 'returned' }
    end

    trait :due_soon do
      borrowed_at { 25.days.ago }
      due_date { 5.days.from_now }
    end
  end
end
