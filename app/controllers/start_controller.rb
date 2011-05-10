class StartController < ApplicationController

  def index	
	@match_h = []
	@match_t = []
	Sedna.connect :database => "test" do |sedna|
		sedna.transaction do
			@rows = sedna.execute "distinct-values( collection('mecze')/punter-odds/game/description/category/text() ) "
			@highlite = sedna.execute "for $mecz in (collection('mecze')/punter-odds/game)[position() < 3] order by $mecz/description descending return $mecz"
			@top = sedna.execute "for $mecz in (collection('mecze')/punter-odds/game)[position() < 7] order by $mecz/@time return $mecz"
			#puts sedna.execute "for $i in doc('mecz5')/punter-odds/game return if (contains($i/description/text(), 'Atromitos - AEK')) then $i else()"
		end
	end
	@usr = User.find(:all, :order => "stan_konta DESC", :limit => 5);
	if(current_user)
		@coupon_count = Coupon.where(:user_id => current_user.id).count
		@c = Coupon.where(:user_id => current_user.id, :stawka => -1)
		@c.each do |row|
			@event_count = Event.where(:coupon_id => row.id).count
		end
	end
	@highlite.each do |row|
		@c = Hash.from_xml(row)
		@d = @c['game']['description'].split('-')
		@c['game']['first'] = @d[0]
		@c['game']['second'] = @d[1]
		@e = row.split('odds="')
		for i in 1..@e.length-1 do
			@f = @e[i].split('" team')
			case i
				when 1 then @c['game']['alt1'] = @f[0]
				when 2 then @c['game']['altx'] = @f[0]
				when 3 then @c['game']['alt2'] = @f[0]
			end
		end
		@match_h.push(@c)
	end
	@top.each do |row|
		@c = Hash.from_xml(row)
		@c['game']['time'].insert(2,':')
		@e = row.split('odds="')
		for i in 1..@e.length-1 do
			@f = @e[i].split('" team')
			case i
				when 1 then @c['game']['alt1'] = @f[0]
				when 2 then @c['game']['altx'] = @f[0]
				when 3 then @c['game']['alt2'] = @f[0]
			end
		end
		@match_t.push(@c)
	end
	puts @match_h[0]
	@rows.sort!
	respond_to do |format|
	   format.js
	   format.html
    end
  end
  
  
  def lista
	@comp = params[:league]
	@i = 0
	
	Sedna.connect :database => "test" do |sedna|
		sedna.transaction do
			@game_list = sedna.execute ("for $i in collection('mecze')/punter-odds/game where ($i/description/category/text() = '"+@comp+"') return $i")
		end
	end
	
	@match = calibrate(@game_list)
	
	respond_to do |format|
	   format.html
    end
  end
  
  
  def xmlgenerate
	if(current_user) 
		@event = []
		@coupon = Coupon.where(:user_id => current_user.id) 
		@coupon.each do |row|
			@e = Event.where(:coupon_id => row.id)
			@event.push(@e)
		end
	end
	respond_to do |format|
	   format.html
    end
  end
  
  
  def getkupon
	if(current_user)
		if(params[:act] == 'add' and params[:typ] and params[:match] and params[:multiple] and params[:name])
			if(Coupon.where(:user_id => current_user.id, :stawka => -1).count < 1)
				@k = Coupon.new(:user_id => current_user.id, :stawka => -1, :finished => false)
				@k.save
			end
			@kupon = Coupon.where(:user_id => current_user.id, :stawka => -1)
			@kupon.each do |row|
				@event = Event.new(:coupon_id => row.id, :match_id => params[:match], :match_name => params[:name], :choice => params[:typ], :multiple => params[:multiple], :result => -1)
				@event.save
			end
		elsif(params[:act] == 'rem' and params[:match])
			@kupon = Coupon.where(:user_id => current_user.id, :stawka => -1)
			@kupon.each do |row|
				Event.where(:coupon_id => row.id, :match_id => params[:match]).delete_all
			end
		elsif(params[:act] == 'akt' and params[:stawka])
			current_user.stan_konta -= params[:stawka].to_f
			current_user.save
			@kupon = Coupon.where(:user_id => current_user.id, :stawka => -1)
			@kupon.each do |row|
				row.stawka = params[:stawka]
				row.save
			end
		end
		@tab = []
		@c = Coupon.where(:user_id => current_user.id, :stawka => -1)
		@kurs_laczny = 1.0;
		@c.each do |row|
			@e = Event.where(:coupon_id => row.id)
			@e.each do |row|
				Sedna.connect :database => "test" do |sedna|
					sedna.transaction do
						@sed = sedna.execute (" for $i in collection('mecze')/punter-odds/game where ($i/@id = "+row.match_id.to_i.to_s+") 
						return <e><n>{data($i/description)}</n><d>{data($i/@date)}</d><t>{data($i/@time)}</t></e> ")
						@sed.each do |rowww|
							@c = Hash.from_xml(rowww)
							@c["e"]["id"] = row.match_id
							@c["e"]["c"] = row.choice
							@c["e"]["m"] = row.multiple
							@kurs_laczny *= @c["e"]["m"]
							@tab.push(@c)
						end
					end
				end
			end
		end
		@coup_all = Coupon.where(:user_id => current_user.id)
	end
	respond_to do |format|
		format.html
    end
  end
  
  private
  def calibrate(game_list)
	@match = []
	game_list.each do |row|
		@odd = []
		@i += 1
		row.to_s
		@matchid_start = row.split('id="')
		@match_id = (@matchid_start[1].split('"'))[0]
		@date_start = row.split('date="')
		@date_end = @date_start[1].split('" time="') #$date = $date_end[0]
		@event_date = @date_end[0].insert(4,'-')
		@event_date = @event_date.insert(7,'-')
		@time_end = @date_end[1].split('">') #$time = $time_end[0]
		@time = @time_end[0].insert(2,':')
		@category_end = @time_end[2].split('</category>') 
		@name_end = @category_end[1].split('</description>') #@name = @category_end[0] + " " + @name_end[0]
		@name = @name_end[0]
		for @j in 2..@time.length-1 do
			@odds_start = @time_end[@j].split('odds="') #@odd[@j] = @odds_end[0]
			@odds_end = @odds_start[1].split('" team')
			@odd[@j - 2] = @odds_end[0]
		end
		@match.push([@event_date, @time, @name, @odd[0], @odd[1], @odd[2], @match_id])
		puts @event_date +" "+ @time +" "+ @name +" "+ @odd[0] +" "+ @odd[1] +" "+ @odd[2] + " "+@match_id
	end
	return @match
  end
end

