require 'spec_helper'

describe MeasuresHelper do



  describe "#degrees_and_cardinal" do
    subject do
      degrees_and_cardinal(5)
    end

    it { should eq "N (5°)" }
  end

  describe "speed_min_max" do

    let(:measure){ { :speed => 1, :min_wind_speed => 2, :max_wind_speed => 3} }

    it "formats the wind speed values according to speed(min/max)" do
      expect(speed_min_max(measure)).to eq "1 (2-3)m/s"
    end

  end

  describe "#time_in_24h" do
    it "outputs hours and minutes" do
      expect(time_in_24h Time.new(2002, 10, 31, 13, 22, 2)).to eq "13:22"
    end
  end


end