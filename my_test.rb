require 'minitest/autorun'
require_relative 'my_'

class MyTest < MiniTest::Unit::TestCase
  def setup
    # Do nothing
  end

  def teardown
    # Do nothing
  end

  def test_weight_shuffle_zero_first
    l = weight_shuffle(
     [
        SRV.new(2, 0, 22424, "d"),
        SRV.new(2, 20, 22424, "cc"),
        SRV.new(2, 10, 22424, "aa"),
        SRV.new(2, 100, 22424, "bnbb"),
      ]
    )
    assert_equal SRV.new(2, 0, 22424, "d"), l[0]
  end

  def test_weight_shuffle_zero_firs
    l = weight_shuffle(
        [
            SRV.new(2, 0, 22424, "d"),
            SRV.new(2, 20, 22424, "cc"),
            SRV.new(2, 10, 22424, "aa"),
            SRV.new(2, 100, 22424, "bnbb"),
        ]
    )
    assert_equal SRV.new(2, 0, 22424, "d"), l[0]
  end
end