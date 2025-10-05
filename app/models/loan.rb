class Loan < ApplicationRecord
  belongs_to :book
  belongs_to :borrower

  validates :borrowed_at, presence: true
  validates :due_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[active returned overdue] }
  validate :borrower_can_borrow, on: :create
  validate :book_is_available, on: :create
  validate :due_date_within_limit, on: :create
  validate :one_book_per_loan, on: :create

  before_validation :set_defaults, on: :create

  scope :active, -> { where(status: 'active') }
  scope :returned, -> { where(status: 'returned') }
  scope :overdue, -> { where(status: 'overdue') }

  def return_book!
    update!(returned_at: Time.current, status: 'returned')
  end

  def overdue?
    status == 'active' && due_date < Time.current
  end

  def days_overdue
    return 0 unless overdue?
    (Time.current.to_date - due_date.to_date).to_i
  end

  def mark_overdue!
    update!(status: 'overdue') if overdue?
  end

  private

  def set_defaults
    self.borrowed_at ||= Time.current
    self.status ||= 'active'
    
    if due_date.blank? && borrowed_at.present?
      self.due_date = borrowed_at + 30.days
    end
  end

  def borrower_can_borrow
    return unless borrower

    if borrower.has_active_loan?
      errors.add(:borrower, "already has an active loan")
    end
  end

  def book_is_available
    return unless book

    unless book.available?
      errors.add(:book, "is not available (no stock)")
    end
  end

  def due_date_within_limit
    return unless borrowed_at && due_date

    max_due_date = borrowed_at + 30.days
    if due_date > max_due_date
      errors.add(:due_date, "cannot be more than 30 days from borrowed date")
    end
  end

  def one_book_per_loan
  end
end
