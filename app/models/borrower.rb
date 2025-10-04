class Borrower < ApplicationRecord
  has_many :loans, dependent: :destroy
  has_many :books, through: :loans

  validates :id_card_number, presence: true, uniqueness: true
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def has_active_loan?
    loans.where(status: 'active').exists?
  end

  def can_borrow?
    !has_active_loan?
  end

  def active_loan
    loans.find_by(status: 'active')
  end
end
