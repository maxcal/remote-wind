require 'spec_helper'

describe "stations/show" do
  before(:each) do
    stub_user_for_view_test
    @station = assign(:station, create(:station))
  end

  subject {
    render
    rendered
  }

  it { should have_selector('h1', :text => @station.name )}

  context "when not an admin" do
    it { should_not have_link 'Delete' }
    it { should_not have_link 'Clear all measures for this station' }
  end

  context "when an admin" do
    subject {
      @ability.can :manage, Station
      render
      rendered
    }
    it { should have_link 'Edit' }
    it { should have_link 'Clear all measures for this station' }
  end

  describe "breadcumbs" do
    it { should have_selector '.breadcrumbs .root', text: 'Home' }
    it { should have_selector '.breadcrumbs a', text: 'Stations' }
    it { should have_selector '.breadcrumbs .current', text: @station.name }
  end

  describe "map" do
    it { should have_selector "#map_canvas .marker .title", text: @station.name }
    it { should have_selector "#map_canvas .marker[data-lat='#{@station.lat}']" }
    it { should have_selector "#map_canvas .marker[data-lon='#{@station.lon}']" }
  end
end
