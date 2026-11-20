require "test_helper"

class MoneyTest < ActiveSupport::TestCase
  test "parses decimal major units into minor units" do
    money = Money.from_major("1000.50", "USD")

    assert_equal 100_050, money.minor_units
    assert_equal "$1,000.50", money.formatted
    assert_equal "1000.50", money.major_string
  end

  test "accepts a whole yen amount and rejects a yen fraction" do
    yen = Money.from_major("5000000", "JPY")

    assert_equal 5_000_000, yen.minor_units
    assert_equal "¥5,000,000", yen.formatted

    error = assert_raises(Money::Error) { Money.from_major("5000000.5", "JPY") }
    assert_match "too many decimal places", error.message
  end

  test "rejects blank, zero, and non numeric amounts" do
    assert_raises(Money::Error) { Money.from_major("", "USD") }
    assert_raises(Money::Error) { Money.from_major("0", "USD") }
    assert_raises(Money::Error) { Money.from_major("-10", "USD") }
    assert_raises(Money::Error) { Money.from_major("10.555", "USD") }
    assert_raises(Money::Error) { Money.from_major("1e2", "USD") }
  end

  test "converts to indicative usd cents with half up rounding" do
    rupees = Money.from_major("83000", "INR")

    assert_equal 100_000, rupees.to_usd_cents("83")

    two_units = Money.from_major("2", "USD")
    assert_equal 67, two_units.to_usd_cents("3")
  end
end
