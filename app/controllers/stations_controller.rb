class StationsController < ApplicationController

  # Security exceptions:
  DO_NOT_AUTHORIZE =  [:show, :index, :measures, :search, :embed, :find, :update_balance]

  skip_before_filter :authenticate_user!, only: DO_NOT_AUTHORIZE
  authorize_resource except: DO_NOT_AUTHORIZE
  skip_authorization_check only: DO_NOT_AUTHORIZE

  skip_before_filter :get_all_stations, except: [:index, :show, :new, :edit, :search]
  before_action :set_station, except: [:new, :index, :create, :find]

  # Skip CSRF protection since station does not send CSRF token.
  protect_from_forgery except: [:create, :update_balance]

  # GET /stations
  # GET /stations.json
  def index
    @title = "Stations"
    @stations = @all_stations
  end

  # GET /stations/1
  # GET /stations/1.json
  def show
    @title = @station.name
    @measures = @station.measures
      .limit(10)
      .order(created_at: :desc)
      .load
    @station.latest_measure = @measures.first

    respond_to do |format|
      format.html #show.html.erb
    end
  end

  # GET /stations/new
  def new
    @station = Station.new
  end

  # GET /stations/1/edit
  def edit
    @title = "Editing #{@station.name}"
  end

  # POST /stations
  # POST /stations.json
  def create
    @station = Station.new(station_params)

    unless params[:station][:show].nil?
      @station.show = params[:station][:show] == 'yes'
    end

    respond_to do |format|
      if @station.save
        #expire_fragment('all_stations')
        format.html { redirect_to @station, notice: 'Station was successfully created.' }
        format.json { render action: 'show', status: :created, location: @station }
      else
        format.html { render action: 'new' }
        format.json { render json: @station.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /stations/1
  # PATCH/PUT /stations/1.json
  def update
    @station = Station.friendly.find(params[:id])
    unless params[:station][:show].nil?
      params[:station][:show] = params[:station][:show] == 'yes'
    end

    respond_to do |format|
      if @station.update(station_params)
        expire_fragment('all_stations')
        format.html { redirect_to @station, notice: 'Station was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @station.errors, status: :unprocessable_entity }
      end
    end
  end

  # @throws ActiveRecord::RecordNotFound if no station
  # PUT /s/:station_id
  def update_balance

    sp = params.require(:s).permit(:b)
    @station.balance = sp[:b] if sp[:b].present?

    respond_to do |format|
      if @station.balance_changed? && @station.save
        format.any { render nothing: true, status: :ok }
        # check station balance after reply has been sent
        @station.check_balance
      else
        logger.error( "Someone attemped to update #{@station.name} balance with invalid data ('#{params[:s][:b]}') from #{request.remote_ip}" )
        format.any { render nothing: true, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /stations/1
  # DELETE /stations/1.json
  def destroy
    @station.destroy
    expire_fragment('all_stations')
    respond_to do |format|
      format.html { redirect_to stations_url }
      format.json { head :no_content }
    end
  end

  # GET /stations/search?lat=x&lon=x&radius
  def search
    radius = params[:radius] || 20
    @stations = Station.near([params[:lat], params[:lon]], radius, units: :km)
  end

  # GET /stations/:id/embed
  def embed
    @measure = @station.current_measure

    @embed_options = {
      css: (params[:css].in?(['true', 'TRUE'])),
      type: params[:type] || 'table',
      height: params[:height] || 350,
      width: params[:width] || 500
    }

    unless @embed_options[:type].in? ['chart','table']
      @message = "Sorry buddy, I don´t know how to render \"#{@embed_options[:type]}\"."
      @embed_options[:type] = 'error'
    end

    respond_to do |format|
      format.html { render "/stations/embeds/#{@embed_options[:type]}", layout: false }
    end
  end

  # Used by Ardiuno to lookup station ID
  # GET /stations/search?lat&lon&(radius)
  def find
    @station = Station.find_by(hw_id: params[:hw_id])

    if(@station.nil?)
      respond_to do |format|
        format.html { head :not_found }
        format.json { head :not_found }
        format.yaml { head :not_found, :content_type => 'text/x-yaml'}
      end
    else
      respond_to do |format|
        format.html { redirect_to action: :show, status: :found }
        format.json  { render json: @station, status: :found }
        format.yaml {render json:  {
            id:    @station.id,
            hw_id: @station.hw_id
        },
            content_type: 'text/x-yaml'
        }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_station
      # Look in @all_stations for station to avoid query
      @station = @all_stations.select_by_slug_or_id(params[:id]) if defined? @all_stations
      # Get station normally if no @all_stations
      @station = Station.friendly.find(params[:id]) unless defined? @station
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def station_params
      params.require(:station).permit(:name, :hw_id, :latitude, :longitude, :user_id, :slug, :show, :speed_calibration)
    end
end