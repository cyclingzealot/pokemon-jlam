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

  test "it can update a creature" do
    c = creatures(:one)
    update_params = {
      name: "Sutcliffe",
      type1: "Water",
      type2: "Normal",
      total: 500,
      hp: 90,
      attack: 90,
      defense: 100,
      special_attack: 95,
      special_defense: 70,
      speed: 10,
      generation: 7,
      legendary: false,
    }.map { |k, v| [k.to_s, v] }.to_h

    patch creature_path(c), params: { creature: update_params }, as: :json

    assert_equal update_params, c.reload.attributes.slice(*(update_params.keys.map(&:to_s)))
    assert_response :ok
  end
end
