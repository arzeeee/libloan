class Api::BorrowersController < ApplicationController
  before_action :set_borrower, only: [:show, :update, :destroy]

  # GET /api/borrowers
  def index
    @borrowers = Borrower.all
    render json: @borrowers.map { |borrower| borrower_json(borrower) }
  end

  # GET /api/borrowers/:id
  def show
    render json: borrower_json(@borrower)
  end

  # POST /api/borrowers
  def create
    @borrower = Borrower.new(borrower_params)
    
    if @borrower.save
      render json: borrower_json(@borrower), status: :created
    else
      render json: { errors: @borrower.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT/PATCH /api/borrowers/:id
  def update
    if @borrower.update(borrower_params)
      render json: borrower_json(@borrower)
    else
      render json: { errors: @borrower.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/borrowers/:id
  def destroy
    if @borrower.has_active_loan?
      render json: { error: "Cannot delete borrower with active loans" }, status: :unprocessable_entity
    else
      @borrower.destroy
      head :no_content
    end
  end

  private

  def set_borrower
    @borrower = Borrower.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Borrower not found" }, status: :not_found
  end

  def borrower_params
    params.require(:borrower).permit(:id_card_number, :name, :email)
  end

  def borrower_json(borrower)
    {
      id: borrower.id,
      id_card_number: borrower.id_card_number,
      name: borrower.name,
      email: borrower.email,
      has_active_loan: borrower.has_active_loan?,
      can_borrow: borrower.can_borrow?,
      active_loan: borrower.active_loan&.id,
      created_at: borrower.created_at,
      updated_at: borrower.updated_at
    }
  end
end
