# frozen_string_literal: true

require "test_helper"

class CreatureControllerTest < ActionDispatch::IntegrationTest
  test "it can show me the details of a creature" do
    flunk("Test not done yet")

    assert_response :ok
  end

  test "it can delete a creature" do
    c = creatures(:one)
    assert_difference("Creature.count", -1) do
      delete creature_path(c), as: :json
    end

    assert_response :no_content
  end

  test "it can create a creature" do
    flunk("Test not done yet")
    assert_response :ok
  end

  test "it can list creatures" do
    flunk("Test not done yet")
    assert_response :ok
  end
end
