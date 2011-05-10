class SednaController < ApplicationController
  require 'sedna'
  
  def index
	Sedna.connect :database => "test" do |sedna|
		sedna.transaction do
			File.open "D:/mecz.xml" do |file|
				#sedna.load_document file, "mecz5"
				@rows = sedna.execute "distinct-values( doc('mecz5')/punter-odds/game/description/category/text() ) "
			end
		end
	end
	@rows.sort!
	
	respond_to do |format|
      format.html # index.html.erb
    end
  end
  
end
