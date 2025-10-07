require 'rails_helper'

RSpec.describe Loan, type: :model do
  describe 'associations' do
    it { should belong_to(:book) }
    it { should belong_to(:borrower) }
  end

  describe 'validations' do
    it 'has presence validation for borrowed_at' do
      loan = Loan.new(book: create(:book), borrower: create(:borrower), due_date: Time.current + 20.days, status: 'active')
      loan.define_singleton_method(:set_defaults) {}
      loan.valid?
      expect(loan.errors[:borrowed_at]).to include("can't be blank")
    end

    it 'has presence validation for due_date' do
      loan = Loan.new(book: create(:book), borrower: create(:borrower), borrowed_at: Time.current, status: 'active')
      loan.define_singleton_method(:set_defaults) {}
      loan.valid?
      expect(loan.errors[:due_date]).to include("can't be blank")
    end

    it 'has presence validation for status' do
      loan = Loan.new(book: create(:book), borrower: create(:borrower), borrowed_at: Time.current, due_date: Time.current + 20.days)
      loan.define_singleton_method(:set_defaults) {}
      loan.valid?
      expect(loan.errors[:status]).to include("can't be blank")
    end

    it { should validate_inclusion_of(:status).in_array(%w[active returned overdue]) }
  end

  describe 'scopes' do
    let(:book1) { create(:book) }
    let(:book2) { create(:book) }
    let(:book3) { create(:book) }
    let(:borrower1) { create(:borrower) }
    let(:borrower2) { create(:borrower) }
    let(:borrower3) { create(:borrower) }
    
    let!(:active_loan) { create(:loan, book: book1, borrower: borrower1, status: 'active') }
    let!(:returned_loan) { create(:loan, :returned, book: book2, borrower: borrower2) }
    let!(:overdue_loan) { create(:loan, :overdue, book: book3, borrower: borrower3) }

    it 'filters active loans' do
      expect(Loan.active).to include(active_loan)
      expect(Loan.active).not_to include(returned_loan, overdue_loan)
    end

    it 'filters returned loans' do
      expect(Loan.returned).to include(returned_loan)
      expect(Loan.returned).not_to include(active_loan, overdue_loan)
    end

    it 'filters overdue loans' do
      expect(Loan.overdue).to include(overdue_loan)
      expect(Loan.overdue).not_to include(active_loan, returned_loan)
    end
  end

  describe 'before_validation callbacks' do
    describe 'set_defaults' do
      let(:loan) { build(:loan, borrowed_at: nil, due_date: nil, status: nil) }

      it 'sets borrowed_at to current time' do
        loan.valid?
        expect(loan.borrowed_at).to be_present
        expect(loan.borrowed_at).to be_within(1.second).of(Time.current)
      end

      it 'sets status to active' do
        loan.valid?
        expect(loan.status).to eq('active')
      end

      it 'sets due_date to 30 days from borrowed_at' do
        loan.borrowed_at = Time.current
        loan.valid?
        expect(loan.due_date).to be_within(1.second).of(Time.current + 30.days)
      end
    end
  end

  describe 'custom validations' do
    describe 'due_date_within_limit' do
      let(:book) { create(:book) }
      let(:borrower) { create(:borrower) }

      context 'when due date is within 30 days' do
        it 'is valid' do
          loan = build(:loan, book: book, borrower: borrower, 
                       borrowed_at: Time.current, due_date: Time.current + 25.days)
          expect(loan).to be_valid
        end
      end

      context 'when due date is exactly 30 days' do
        it 'is valid' do
          borrowed = Time.current
          loan = build(:loan, book: book, borrower: borrower,
                       borrowed_at: borrowed, due_date: borrowed + 30.days)
          expect(loan).to be_valid
        end
      end

      context 'when due date exceeds 30 days' do
        it 'is invalid' do
          loan = build(:loan, book: book, borrower: borrower,
                       borrowed_at: Time.current, due_date: Time.current + 31.days)
          expect(loan).to be_invalid
          expect(loan.errors[:due_date]).to include("cannot be more than 30 days from borrowed date")
        end
      end
    end

    describe 'borrower_can_borrow' do
      let(:borrower) { create(:borrower) }
      let(:book) { create(:book) }

      context 'when borrower has no active loans' do
        it 'is valid' do
          loan = build(:loan, borrower: borrower, book: book)
          expect(loan).to be_valid
        end
      end

      context 'when borrower already has an active loan' do
        before { create(:loan, borrower: borrower) }

        it 'is invalid' do
          loan = build(:loan, borrower: borrower, book: book)
          expect(loan).to be_invalid
          expect(loan.errors[:borrower]).to include("already has an active loan")
        end
      end

      context 'when borrower has an overdue loan' do
        before { create(:loan, :overdue, borrower: borrower) }

        it 'is invalid' do
          loan = build(:loan, borrower: borrower, book: book)
          expect(loan).to be_invalid
          expect(loan.errors[:borrower]).to include("already has an active loan")
        end
      end

      context 'when borrower has only returned loans' do
        before { create(:loan, :returned, borrower: borrower, book: create(:book)) }

        it 'is valid' do
          loan = build(:loan, borrower: borrower, book: book)
          expect(loan).to be_valid
        end
      end
    end

    describe 'book_is_available' do
      let(:borrower) { create(:borrower) }

      context 'when book has available stock' do
        let(:book) { create(:book, stock: 3) }

        it 'is valid' do
          loan = build(:loan, book: book, borrower: borrower)
          expect(loan).to be_valid
        end
      end

      context 'when book has no stock' do
        let(:book) { create(:book, stock: 0) }

        it 'is invalid' do
          loan = build(:loan, book: book, borrower: borrower)
          expect(loan).to be_invalid
          expect(loan.errors[:book]).to include("is not available (no stock)")
        end
      end

      context 'when all book stock is loaned out' do
        let(:book) { create(:book, stock: 1) }
        
        before { create(:loan, book: book) }

        it 'is invalid' do
          loan = build(:loan, book: book, borrower: borrower)
          expect(loan).to be_invalid
          expect(loan.errors[:book]).to include("is not available (no stock)")
        end
      end
    end
  end

  describe '#return_book!' do
    let(:loan) { create(:loan, status: 'active', returned_at: nil) }

    it 'sets returned_at to current time' do
      loan.return_book!
      expect(loan.returned_at).to be_present
      expect(loan.returned_at).to be_within(1.second).of(Time.current)
    end

    it 'sets status to returned' do
      loan.return_book!
      expect(loan.status).to eq('returned')
    end

    it 'persists the changes' do
      loan.return_book!
      loan.reload
      expect(loan.status).to eq('returned')
      expect(loan.returned_at).to be_present
    end
  end

  describe '#overdue?' do
    context 'when loan is active and past due date' do
      let(:loan) { create(:loan, status: 'active', due_date: 5.days.ago) }

      it 'returns true' do
        expect(loan.overdue?).to be true
      end
    end

    context 'when loan has overdue status and past due date' do
      let(:loan) { create(:loan, :overdue) }

      it 'returns true' do
        expect(loan.overdue?).to be true
      end
    end

    context 'when loan is active but not past due date' do
      let(:loan) { create(:loan, status: 'active', due_date: 5.days.from_now) }

      it 'returns false' do
        expect(loan.overdue?).to be false
      end
    end

    context 'when loan is returned' do
      let(:loan) { create(:loan, :returned, due_date: 5.days.ago) }

      it 'returns false' do
        expect(loan.overdue?).to be false
      end
    end
  end

  describe '#days_overdue' do
    context 'when loan is overdue' do
      let(:loan) { create(:loan, status: 'overdue', due_date: 10.days.ago) }

      it 'returns the number of days past due date' do
        expect(loan.days_overdue).to eq(10)
      end
    end

    context 'when loan is active and overdue' do
      let(:loan) { create(:loan, status: 'active', due_date: 5.days.ago) }

      it 'returns the number of days past due date' do
        expect(loan.days_overdue).to eq(5)
      end
    end

    context 'when loan is not overdue' do
      let(:loan) { create(:loan, status: 'active', due_date: 5.days.from_now) }

      it 'returns 0' do
        expect(loan.days_overdue).to eq(0)
      end
    end

    context 'when loan is returned' do
      let(:loan) { create(:loan, :returned, due_date: 10.days.ago) }

      it 'returns 0' do
        expect(loan.days_overdue).to eq(0)
      end
    end
  end

  describe '#mark_overdue!' do
    context 'when loan is active and past due date' do
      let(:loan) { create(:loan, status: 'active', due_date: 5.days.ago) }

      it 'updates status to overdue' do
        loan.mark_overdue!
        expect(loan.status).to eq('overdue')
      end

      it 'persists the change' do
        loan.mark_overdue!
        loan.reload
        expect(loan.status).to eq('overdue')
      end
    end

    context 'when loan is not overdue' do
      let(:loan) { create(:loan, status: 'active', due_date: 5.days.from_now) }

      it 'does not change status' do
        loan.mark_overdue!
        expect(loan.status).to eq('active')
      end
    end
  end
end
