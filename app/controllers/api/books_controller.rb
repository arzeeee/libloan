class Api::BooksController < ApplicationController
  before_action :set_book, only: [:show, :update, :destroy]

  # GET /api/books
  def index
    @books = Book.all
    render json: @books.map { |book| book_json(book) }
  end

  # GET /api/books/:id
  def show
    render json: book_json(@book)
  end

  # POST /api/books
  def create
    @book = Book.new(book_params)
    
    if @book.save
      render json: book_json(@book), status: :created
    else
      render json: { errors: @book.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT/PATCH /api/books/:id
  def update
    if @book.update(book_params)
      render json: book_json(@book)
    else
      render json: { errors: @book.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/books/:id
  def destroy
    if @book.loans.active.any?
      render json: { error: "Cannot delete book with active loans" }, status: :unprocessable_entity
    else
      @book.destroy
      head :no_content
    end
  end

  private

  def set_book
    @book = Book.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Book not found" }, status: :not_found
  end

  def book_params
    params.require(:book).permit(:title, :isbn, :stock)
  end

  def book_json(book)
    {
      id: book.id,
      title: book.title,
      isbn: book.isbn,
      stock: book.stock,
      available_stock: book.available_stock,
      available: book.available?,
      created_at: book.created_at,
      updated_at: book.updated_at
    }
  end
end
