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
	#pobieranie z expekta
	c = Curl::Easy.perform("http://www.expekt.com/sports/results/list.do?categoryCode=SOC%25&datePeriod=168&sortOrderCode=2")
	puts "Polaczenie ustanowione! Rozpoczynam przetwarzanie danych.."
	@a = c.body_str.split('<tr class="odds_row">')
	@wyd = []
	for i in 1..@a.length-1 do 
		@b = @a[i].split('<tr class="odds_row bg-vvvlightgrey">')
		if(i%50 == 0) then
			puts "* Ukonczono " + i.to_s + "/" + @a.length.to_s
		end
		@b.each do |row|		
			# konwersja
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
			else @wyn = '0'
			end
			
			# dopis do sedny i nadpisanie eventów
			Sedna.connect :database => "test" do |sedna|
				sedna.transaction do
					sedna.execute " update replace $wynik in collection('wyniki')/wyniki/rezultat[matches(nazwa,'"+@name[0]+"')]/wynik with <wynik>"+@wyn+"</wynik>"
				end
			end
			@e = Event.where(:match_name => @name[0], :result => -1)
			@e.each do |row|
				row.result = @wyn
				row.save
			end
		end
	end
	
	puts "Rozliczam kursy.."
	
	#rozliczenie kuponów
	@coupon = Coupon.where(:wygrana => -1)
	@coupon.each do |row|
		@rozstrzygniety = 1
		@wygrany = 1
		@mnoznik = 1
		@event = Event.where(:coupon_id => row.id)
		@event.each do |roww|
			if(roww.result == '-1')
				@rozstrzygniety = 0
			elsif(roww.choice != roww.result)
				@wygrany = 0
			else
				@mnoznik *= roww.multiple
			end
		end
		if(@rozstrzygniety == 1)
			if(@wygrany == 1)
				@user = User.find(row.user_id)
				@user.stan_konta += row.stawka * @mnoznik
				row.wygrana = row.stawka * @mnoznik
				row.save
				@user.save
			else
				row.wygrana = 0
				row.save
			end
		end
	end
	
	puts 'Rozliczanie kursów ukończone!'
	puts 'Zakonczono cykl! Rozpoczynam od nowa za 10 sekund..'
	sleep 10
	
end
  
