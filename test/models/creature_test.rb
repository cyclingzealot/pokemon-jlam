require "test_helper"

class CreatureTest < ActiveSupport::TestCase
  test "it will let me save one valid type 1" do
    c = creatures(:one)
    assert_nothing_raised {
      c.type1 = "steel"
      c.save!
    }
  end

  test "it will not let me save one of abnormal type 1" do
    c = creatures(:two)
    assert_raises {
      c.type1 = "abnormal"
      c.save!
    }
  end

  test "it defaults to generation one and false" do
    c = Creature.new
    refute c.legendary
    assert_equal 1, c.generation
  end
end
