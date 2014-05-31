class StationsController < ApplicationController

  # Security exceptions:
  DO_NOT_AUTHORIZE =  [:show, :index, :measures, :search, :embed, :find, :update_balance]

  skip_before_filter :authenticate_user!, only: DO_NOT_AUTHORIZE
  authorize_resource except: DO_NOT_AUTHORIZE
  skip_authorization_check only: DO_NOT_AUTHORIZE

  before_action :set_station, except: [:new, :index, :create, :find, :search]

  # Skip CSRF protection since station does not send CSRF token.
  protect_from_forgery except: [:create, :update_balance]

  # GET /stations
  # GET /stations.json
  def index
    @title = "Stations"
    @last_updated = Station.order("updated_at asc").last

    if stale?(@last_updated, last_modified: @last_updated.try(:updated_at))
      @stations = all_with_latest_observation
      respond_to do |format|
        format.html
        format.json { render json: @stations }
      end
    end

  end

  # GET /stations/1
  # GET /stations/1.json
  def show
    @title = @station.name

    if stale?(@station, last_modified: @station.updated_at)
      @observations = @station.observations
      .limit(10)
      .order(created_at: :desc)
      .load
      @station.latest_observation = @observations.first

      respond_to do |format|
        format.html #show.html.erb
        format.json { render json: @station }
      end
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
        format.html { redirect_to station_path(@station), notice: 'Station was successfully created.' }
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
    @stations = Station.all.near([params[:lat], params[:lon]], radius, units: :km)
  end

  # GET /stations/:id/embed
  def embed
    @observation = @station.current_observation
    @observations = [@observation]

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

    # Temporary fix to allow iframe from http://www.gotlandssurfcenter.se
    response.headers['X-Frame-Options'] = 'ALLOW-FROM http://www.gotlandssurfcenter.se'

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
  # Get all stations with the latest observation preloaded
  # @return array
  def all_with_latest_observation
    if user_signed_in? && current_user.has_role?(:admin)
      stations = Station.all.load
    end
    stations ||= Station.where(show: true).load

    if stations.size
      observations = Observation.find_by_sql(%Q{
        SELECT DISTINCT ON(m.station_id)
          m.*
        FROM observations m
        ORDER BY m.station_id, m.created_at DESC
      })

      stations.each do |station|
        # Setup has_one relationship between station and observation
        # Prevents +1 queries
        observation = observations.find { |m| m.station_id == station.id  }
        if observation
          observation.station = station
          station.latest_observation = observation
        end
      end
    end
  end

  def set_station
    @station = Station.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def station_params
    params.require(:station).permit(:name, :hw_id, :latitude, :longitude,
                                    :user_id, :slug, :show, :speed_calibration)
  end
end