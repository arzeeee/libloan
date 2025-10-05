class Api::LoansController < ApplicationController
  before_action :set_loan, only: [:show, :update, :destroy, :return_book]

  # GET /api/loans
  def index
    @loans = Loan.includes(:book, :borrower).all
    
    # Allow filtering by status
    @loans = @loans.where(status: params[:status]) if params[:status].present?
    
    render json: @loans.map { |loan| loan_json(loan) }
  end

  # GET /api/loans/:id
  def show
    render json: loan_json(@loan)
  end

  # POST /api/loans (Borrow a book)
  def create
    @loan = Loan.new(loan_params)
    
    if @loan.save
      render json: loan_json(@loan), status: :created
    else
      render json: { errors: @loan.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT/PATCH /api/loans/:id
  def update
    if @loan.update(loan_params)
      render json: loan_json(@loan)
    else
      render json: { errors: @loan.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/loans/:id
  def destroy
    if @loan.status == 'active'
      render json: { error: "Cannot delete active loan. Please return the book first." }, status: :unprocessable_entity
    else
      @loan.destroy
      head :no_content
    end
  end

  # POST /api/loans/:id/return (Return a book)
  def return_book
    if @loan.status != 'active'
      render json: { error: "This loan is not active" }, status: :unprocessable_entity
      return
    end

    begin
      @loan.return_book!
      render json: loan_json(@loan)
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # GET /api/loans/overdue (Get overdue loans)
  def overdue
    overdue_loans = Loan.includes(:book, :borrower)
                       .where(status: 'active')
                       .where('due_date < ?', Time.current)
    
    # Mark them as overdue
    overdue_loans.each(&:mark_overdue!)
    
    render json: overdue_loans.map { |loan| loan_json(loan) }
  end

  private

  def set_loan
    @loan = Loan.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Loan not found" }, status: :not_found
  end

  def loan_params
    params.require(:loan).permit(:book_id, :borrower_id, :due_date)
  end

  def loan_json(loan)
    {
      id: loan.id,
      book: {
        id: loan.book.id,
        title: loan.book.title,
        isbn: loan.book.isbn
      },
      borrower: {
        id: loan.borrower.id,
        name: loan.borrower.name,
        id_card_number: loan.borrower.id_card_number
      },
      borrowed_at: loan.borrowed_at,
      due_date: loan.due_date,
      returned_at: loan.returned_at,
      status: loan.status,
      overdue: loan.overdue?,
      days_overdue: loan.days_overdue,
      created_at: loan.created_at,
      updated_at: loan.updated_at
    }
  end
end
