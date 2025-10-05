class ApplicationController < ActionController::Base
  # Skip CSRF protection for API requests
  protect_from_forgery with: :null_session
  
  # Handle common exceptions
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  
  private
  
  def record_not_found
    render json: { error: "Record not found" }, status: :not_found
  end
  
  def parameter_missing(exception)
    render json: { error: exception.message }, status: :bad_request
  end
end
