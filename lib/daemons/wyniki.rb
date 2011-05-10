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
	
	#1 Pobieranie z expekta i zapis do bazy wyników
	c = Curl::Easy.perform("http://www.expekt.com/sports/results/list.do?categoryCode=SOC%25&datePeriod=168&sortOrderCode=2")
	@a = c.body_str.split('<tr class="odds_row">')
	for i in 1..@a.length-1 do 
		@b = @a[i].split('<tr class="odds_row bg-vvvlightgrey">')
		puts "Wykonywanie " + i.to_s + "/" + @a.length.to_s
		@b.each do |row|
			@c = row.split('<span>')
			@name = @c[1].split('</span>')
			@name[0].gsub!(",","")
			@name[0].gsub!("'","")
			@name[0].gsub!(")","")
			@name[0].gsub!("(","")
			@name[0].gsub!("/","")
			@name[0].gsub!("&","")
			@d = row.split('<td style="width: 50px;">')
			@wynik = @d[1].split('</td>')
			@wynik = @wynik[0].split("-")
			@rez1 = @wynik[0].to_i
			@rez2 = @wynik[1].to_i
			if(@rez1 > @rez2) then
				@wyn = '1';
			elsif(@rez1 < @rez2) then
				@wyn = '2'
			else @wyn = 'x'
			end
			#puts @name[0]+" "+@wyn.to_s
			Sedna.connect :database => "test" do |sedna|
				sedna.transaction do
					puts sedna.execute "for $i in collection('mecze')/punter-odds/game[matches(description,'"+ @name[0] +"')] return $i"
					sedna.execute " 
					update replace $wynik in collection('wyniki')/wyniki/rezultat[matches(nazwa,'"+@name[0]+"')]
					with <wynik>"+@wyn+"</wynik>"
				end
			end
		end
	end
	
	#2 Rozliczanie kuponów
	@usr = User.find(:all, :order => "stan_konta DESC", :limit => 5);
	puts @usr
	# Sedna.connect :database => "test" do |sedna|
		# sedna.transaction do
			# puts sedna.execute "for $i in collection('mecze') return $i"
			# sedna.execute 'UPDATE delete collection("wyniki")/wyniki'
			# sedna.execute 'UPDATE insert <wyniki></wyniki> into collection("wyniki")'
			# puts sedna.execute "for $i in collection('wyniki')/wyniki return $i"
		# end
	# end
	
	puts 'ok'
	# c.body_str.gsub!('&lt;BR/&gt;',' ')
	# c.body_str.gsub!('&lt;span&gt;','')
	# c.body_str.gsub!('&lt;/span&gt;','')
	# c.body_str.force_encoding('UTF-8')
	# Sedna.connect :database => "test" do |sedna|
		# sedna.transaction do
			# sedna.execute 'DROP DOCUMENT "new" IN COLLECTION "mecze"'
			# sedna.load_document c.body_str, "new", "mecze"
			# sedna.execute 'UPDATE delete collection("mecze")/punter-odds/game[data(type/@id)!="0"]'
			# puts sedna.execute "collection('mecze')"
			# sleep 10
			# match_short = sedna.execute "for $i in collection('mecze')/punter-odds/game return <rezultat id=\"{data($i/@id)}\"><nazwa>{data($i/description)}</nazwa><wynik></wynik></rezultat>"
			# match_short.each do |row|
				# mecz = XmlSimple.xml_in(row)
				# sedna.execute "
					# update insert if(count(collection('wyniki')/wyniki[data(rezultat/@id) = "+mecz['id']+"])=0) 
					# then "+row+" else() into collection(\"wyniki\")/wyniki"
			# end
			# puts sedna.execute "collection('wyniki')"
		# end
	# end
	# Rails.logger.info "This daemon is still running at #{Time.now}.\n"
	sleep 2
end
  
