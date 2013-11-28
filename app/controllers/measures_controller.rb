class MeasuresController < ApplicationController
  before_filter :authenticate_user!, :only => [:destroy]
  load_and_authorize_resource :only => [:destroy]
  before_action :set_measure, only: [:show, :destroy]
  protect_from_forgery :only => [:destroy]

  # GET /measures/:id
  def show
  end

  # GET /measures
  def index
    @measures = Measure.all
  end

  # POST /measures
  def create

    # @todo write spec and use normalize_ardiuno_params
    @measure = Measure.new(measure_params)

    respond_to do |format|
      if @measure.save
        format.html { redirect_to @measure, notice: 'Measure was successfully created.' }
        format.json { render action: 'show', status: :created, location: station_measure_path(@measure.station, @measure) }
      else
        format.html { return }
        format.json { render json: @measure.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /measures/:id
  def destroy
    @measure.destroy
    respond_to do |format|
      format.html { redirect_to measures_path }
      format.json { head :no_content }
    end
  end

  private
  # Never trust parameters from the scary internet, only allow the white list through.
  def measure_params
    ## Handle short form params
    if params[:m]
      return params.require(:m).permit(:i,:s,:d,:min,:max)
    end
    params.require(:measure).permit(
        :id, :station_id, :direction, :speed, :min_wind_speed, :max_wind_speed
    )
  end

  def set_measure
    @measure = Measure.find(params[:id])
  end
end
