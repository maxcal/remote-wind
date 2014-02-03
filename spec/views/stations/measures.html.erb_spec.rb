require 'spec_helper'

describe "stations/measures" do

  let!(:station) { build_stubbed(:station) }

  let!(:measures) do
    # page, per_page, total_entries
    WillPaginate::Collection.create(1, 10, 50) do |pager|
      pager.replace([*1..50].map! { build_stubbed(:measure, station: station) })
    end

  end

  before(:each) do
    Measure.stub(:last).and_return(measures.last)
    assign(:station, station)
    assign(:measures, measures)
    stub_user_for_view_test
    view.stub(:url_for)
  end

  subject {
    render
    rendered
  }


  it { should match /Latest measures for #{station.name.capitalize}/ }
  it { should match /Latest measurement recieved at #{measures.last.created_at.strftime("%H:%M")}/ }
  it { should have_selector '.pagination' }
  it { should have_selector '.current' }
  it { should have_selector '.previous_page' }
  it { should have_selector '.next_page' }
end