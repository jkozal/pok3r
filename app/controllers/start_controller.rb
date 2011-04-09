class StartController < ActionController::Base
  def index
	respond_to do |format|
		format.html
	end
  end
  
end

