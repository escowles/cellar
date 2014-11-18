require 'rest-client'
require 'json'
require 'cgi'

class BeersController < ApplicationController
  before_action :set_beer, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!

  # GET /beers
  # GET /beers.json
  def index
    @beers = Beer.all
  end

  # GET /beers/1
  # GET /beers/1.json
  def show
  end

  # GET /beers/new
  def new
    @beer = Beer.new
    @options = lookup( params[:q] )
  end

  # GET /beers/1/edit
  def edit
  end

  # POST /beers
  # POST /beers.json
  def create
    @beer = Beer.new(beer_params)

    respond_to do |format|
      if @beer.save
        format.html { redirect_to beers_path, notice: 'Beer was successfully created.' }
        format.json { render :show, status: :created, location: @beer }
      else
        format.html { render :new }
        format.json { render json: @beer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /beers/1
  # PATCH/PUT /beers/1.json
  def update
    respond_to do |format|
      if @beer.update(beer_params)
        format.html { redirect_to beers_path, notice: 'Beer was successfully updated.' }
        format.json { render :show, status: :ok, location: @beer }
      else
        format.html { render :edit }
        format.json { render json: @beer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /beers/1
  # DELETE /beers/1.json
  def destroy
    @beer.destroy
    respond_to do |format|
      format.html { redirect_to beers_url, notice: 'Beer was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # GET /beers/checkout
  # fetch untappd checkins for each user and remove beers that have been
  # checked out
  def checkout
    @checkouts = Array.new
    User.all.each do |user|
      url = untappd_url('/user/checkins/' + user.untappd_id)
      if user.last_checkin.blank?
        user.last_checkin = "0"
      else
        url += "max_id=#{user.last_checkin}"
      end
      json_txt = RestClient.get(url)
      json_obj = JSON.parse(json_txt)
      user_checkouts = Array.new
      failed_checkouts = Array.new
      #checkout_keyword = "#cellar" # XXX
      checkout_keyword = "boozy"
      checkin_max = 0
      json_obj["response"]["checkins"]["items"].each do |checkin|
        checkin_id = checkin['checkin_id']
        checkin_max = checkin_id if checkin_id > checkin_max
        if checkin['checkin_comment'].include? checkout_keyword and checkin_id > user.last_checkin.to_i
          beer = Beer.find_by untappd: checkin['beer']['bid']
          if ( beer.nil? )
            failed_checkouts << checkin['beer']['beer_name']
          else
            beer.quantity = beer.quantity - 1
            beer.save
            user_checkouts << checkin['beer']['beer_name']
          end
        end
      end
      if checkin_max > user.last_checkin.to_i
        user.last_checkin = checkin_max
        user.save
      end
      @checkouts << { email: user.untappd_id,
                      user_checkouts: user_checkouts,
                      failed_checkouts: failed_checkouts }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_beer
      @beer = Beer.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def beer_params
      params.require(:beer).permit(:brewery, :location, :name, :style, :year, :quantity, :notes, :untappd)
    end

    def lookup( q )
      options = Array.new
      return options if q.blank?
      url = untappd_url('/search/beer') + "q=#{CGI.escape(q)}"
      json_txt = RestClient.get(url)
      json_obj = JSON.parse(json_txt)
      beers = json_obj["response"]["beers"]["items"]
      beers.each do |beer|
        brewery = beer['brewery']
        location = brewery['location']
        loc = brewery['country_name']
        loc += "--#{location['brewery_state']}" if loc == 'United States'
        loc += "--#{location['brewery_city']}"
        option = { id: beer["beer"]["bid"], name: beer["beer"]["beer_name"],
                   brewery: brewery['brewery_name'], location: loc,
                   style: beer["beer"]["beer_style"] }
        options << option
      end
      options
    end

    def untappd_url( path )
      return "http://api.untappd.com/v4#{path}?client_id=#{ENV['UNTAPPD_CLIENT_ID']}&client_secret=#{ENV['UNTAPPD_CLIENT_SECRET']}&"
    end
end
