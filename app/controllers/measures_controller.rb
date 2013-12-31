class MeasuresController < ApplicationController
  before_filter :authenticate_user!, :only => [:destroy]
  load_and_authorize_resource :only => [:destroy]
  protect_from_forgery :only => [:destroy]

  # POST /measures
  def create
    @measure = Measure.new(measure_params)
    respond_to do |format|
      if @measure.save
        # Station must be present for measure to validate, no need to check
        @station = @measure.station
        @station.update_attributes(last_measure_received_at: @measure.created_at)
        if @station.down
          latest = Measure.last(4)
          if 4 > latest.length
            # got fewer than 4 measures which means the station has not been up for long, set it to online immediately
            @station.update_attributes(down: true)
          elsif latest[2].created_at < 1.hour.ago
            # online due to last measure was received over an hour ago
            @station.update_attributes(down: true)
          elsif latest[1].created_at > 60.minutes.ago
            # online due to the second last measure was within an hour
            @station.update_attributes(down: true)
          end
          # if not down anymore notify owner
          if !@station.down
            StationMailer.notify_about_station_up(@station.user, @station)
          end
        end

        format.html { render nothing: true, status: :success }
        format.json { render action: 'show', status: :created, location: station_measure_path(@measure.station, @measure) }
        format.yaml { render nothing: true, status: :created }
      else
        format.html { render nothing: true, status: :unprocessable_entity }
        format.json { render json: @measure.errors, status: :unprocessable_entity }
        format.yaml { render nothing: true, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /measures/:id
  def destroy
    @measure = Measure.find(params[:id])
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
end
