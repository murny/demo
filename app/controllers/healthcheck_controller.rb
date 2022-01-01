class HealthcheckController < ApplicationController

  def index
    render json: { code: 200, status: 'OK' }, status: :ok
  end

end
