require 'rails_helper'

RSpec.describe Borrower, type: :model do
  describe 'associations' do
    it { should have_many(:loans).dependent(:destroy) }
    it { should have_many(:books).through(:loans) }
  end

  describe 'validations' do
    subject { build(:borrower) }
    
    it { should validate_presence_of(:id_card_number) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:id_card_number) }
    it { should allow_value('test@example.com').for(:email) }
    it { should_not allow_value('invalid_email').for(:email) }
  end

  describe '#has_active_loan?' do
    let(:borrower) { create(:borrower) }

    context 'when borrower has no loans' do
      it 'returns false' do
        expect(borrower.has_active_loan?).to be false
      end
    end

    context 'when borrower has an active loan' do
      before { create(:loan, borrower: borrower, status: 'active') }

      it 'returns true' do
        expect(borrower.has_active_loan?).to be true
      end
    end

    context 'when borrower has an overdue loan' do
      before { create(:loan, :overdue, borrower: borrower) }

      it 'returns true' do
        expect(borrower.has_active_loan?).to be true
      end
    end

    context 'when borrower has only returned loans' do
      before { create(:loan, :returned, borrower: borrower, book: create(:book)) }

      it 'returns false' do
        expect(borrower.has_active_loan?).to be false
      end
    end
  end

  describe '#can_borrow?' do
    let(:borrower) { create(:borrower) }

    context 'when borrower has no active loans' do
      it 'returns true' do
        expect(borrower.can_borrow?).to be true
      end
    end

    context 'when borrower has an active loan' do
      before { create(:loan, borrower: borrower, status: 'active') }

      it 'returns false' do
        expect(borrower.can_borrow?).to be false
      end
    end

    context 'when borrower has an overdue loan' do
      before { create(:loan, :overdue, borrower: borrower) }

      it 'returns false' do
        expect(borrower.can_borrow?).to be false
      end
    end
  end

  describe '#active_loan' do
    let(:borrower) { create(:borrower) }

    context 'when borrower has an active loan' do
      let!(:loan) { create(:loan, borrower: borrower, status: 'active') }

      it 'returns the active loan' do
        expect(borrower.active_loan).to eq(loan)
      end
    end

    context 'when borrower has an overdue loan' do
      let!(:loan) { create(:loan, :overdue, borrower: borrower) }

      it 'returns the overdue loan' do
        expect(borrower.active_loan).to eq(loan)
      end
    end

    context 'when borrower has no active or overdue loans' do
      it 'returns nil' do
        expect(borrower.active_loan).to be_nil
      end
    end
  end
end
