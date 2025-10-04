class Book < ApplicationRecord
  has_many :loans, dependent: :destroy
  has_many :borrowers, through: :loans

  validates :title, presence: true
  validates :isbn, presence: true, uniqueness: true
  validates :stock, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def available_stock
    stock - active_loans.count
  end

  def available?
    available_stock > 0
  end

  private

  def active_loans
    loans.where(status: 'active')
  end
end
