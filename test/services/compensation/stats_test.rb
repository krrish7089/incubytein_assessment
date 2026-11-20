require "test_helper"

class Compensation::StatsTest < ActiveSupport::TestCase
  test "average and median round half up in minor units" do
    assert_equal 2, Compensation::Stats.average([ 1, 2 ])
    assert_equal 2, Compensation::Stats.average([ 1, 2, 2 ])
    assert_equal 1, Compensation::Stats.average([ 1, 1, 2 ])
    assert_equal 2, Compensation::Stats.median([ 1, 2, 3 ])
    assert_equal 3, Compensation::Stats.median([ 1, 2, 3, 4 ])
    assert_nil Compensation::Stats.median([])
  end
end
