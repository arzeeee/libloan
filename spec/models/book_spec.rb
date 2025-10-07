require 'rails_helper'

RSpec.describe Book, type: :model do
  describe 'associations' do
    it { should have_many(:loans) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:isbn) }
    it { should validate_presence_of(:stock) }
    
    describe 'uniqueness' do
      it 'validates uniqueness of title' do
        existing_book = create(:book, title: 'Test Book')
        duplicate_book = build(:book, title: 'Test Book')
        expect(duplicate_book).not_to be_valid
        expect(duplicate_book.errors[:title]).to include('has already been taken')
      end
      
      it 'validates uniqueness of isbn' do
        existing_book = create(:book, isbn: '978-0-123456789')
        duplicate_book = build(:book, isbn: '978-0-123456789')
        expect(duplicate_book).not_to be_valid
        expect(duplicate_book.errors[:isbn]).to include('has already been taken')
      end
    end
    
    it 'validates stock is a non-negative integer' do
      book = build(:book, stock: -1)
      expect(book).not_to be_valid
      expect(book.errors[:stock]).to include('must be greater than or equal to 0')
    end
  end

  describe '#available_stock' do
    let(:book) { create(:book, stock: 5) }

    context 'when there are no active loans' do
      it 'returns the total stock' do
        expect(book.available_stock).to eq(5)
      end
    end

    context 'when there are active loans' do
      before do
        create(:loan, book: book, status: 'active')
        create(:loan, book: book, status: 'active')
      end

      it 'returns stock minus active loans' do
        expect(book.available_stock).to eq(3)
      end
    end

    context 'when there are returned loans' do
      before do
        create(:loan, :returned, book: book, borrower: create(:borrower))
      end

      it 'does not count returned loans' do
        expect(book.available_stock).to eq(5)
      end
    end

    context 'when there are overdue loans' do
      before do
        create(:loan, :overdue, book: book, borrower: create(:borrower))
      end

      it 'counts overdue loans as unavailable' do
        expect(book.available_stock).to eq(4)
      end
    end
  end

  describe '#available?' do
    let(:book) { create(:book, stock: 2) }

    context 'when available stock is greater than 0' do
      it 'returns true' do
        expect(book.available?).to be true
      end
    end

    context 'when all stock is loaned out' do
      before do
        create(:loan, book: book, status: 'active')
        create(:loan, book: book, status: 'active')
      end

      it 'returns false' do
        expect(book.available?).to be false
      end
    end

    context 'when stock is 0' do
      let(:book) { create(:book, stock: 0) }

      it 'returns false' do
        expect(book.available?).to be false
      end
    end
  end
end
