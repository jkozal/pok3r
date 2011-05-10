#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../../config/application"
require 'xmlsimple'

Rails.application.require_environment!

$running = true
Signal.trap("TERM") do 
  $running = false
end

while($running)
	# Replace this with your code
	Rails.logger.auto_flushing = true
	
	puts "Probuje polaczyc z expekt.com.."
	c = Curl::Easy.perform("http://www.expekt.com/exportServlet?category=SOC%25")
	puts "Połączenie ustanowione! Rozpoczynam przetwarzanie danych"
	c.body_str.gsub!('&lt;BR/&gt;',' ')
	c.body_str.gsub!("'",'')
	c.body_str.gsub!('&lt;span&gt;','')
	c.body_str.gsub!('&lt;/span&gt;','')
	c.body_str.force_encoding('UTF-8')
	Sedna.connect :database => "test" do |sedna|
		sedna.transaction do
			sedna.execute 'DROP DOCUMENT "new" IN COLLECTION "mecze"'
			sedna.load_document c.body_str, "new", "mecze"
			sedna.execute 'UPDATE delete collection("mecze")/punter-odds/game[data(type/@id)!="0"]'
			puts sedna.execute "collection('mecze')"
			match_short = sedna.execute "for $i in collection('mecze')/punter-odds/game return <rezultat id=\"{data($i/@id)}\"><nazwa>{data($i/description)}</nazwa><wynik></wynik></rezultat>"
			match_short.each do |row|
				mecz = XmlSimple.xml_in(row)
				sedna.execute "
					update insert if(count(collection('wyniki')/wyniki[data(rezultat/@id) = "+mecz['id']+"])=0) 
					then "+row+" else() into collection(\"wyniki\")/wyniki"
			end
			puts sedna.execute "collection('wyniki')"
		end
	end
	Rails.logger.info "This daemon is still running at #{Time.now}.\n"
	puts "Cykl zakonczony. Ponowienie za 10 sekund.."
	sleep 10
end
  
