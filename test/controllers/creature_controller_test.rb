# frozen_string_literal: true

require 'test_helper'

class CreatureControllerTest < ActionDispatch::IntegrationTest
  test 'it can show me the details of a creature' do
    c = creatures(:one)
    get creature_url(c), as: :json
    assert_response :ok
  end

  test 'it can delete a creature' do
    c = creatures(:one)
    assert_difference('Creature.count', -1) do
      delete creature_path(c), as: :json
    end

    assert_response :no_content
  end

  #   test "it can handle a wrong type" do
  #     error_params = {
  #       type1: "Metal",
  #     }
  #     assert_difference("Creature.count") do
  #       post creature_index_path, params: { creature: create_params }, as: :json
  #       assert_equal create_params, Creature.last.attributes.slice(*create_params.keys.map(&:to_s))
  #       assert_response :ok
  #     end
  #   end

  test 'it can handle wrong type on creation of a creature' do
    create_params = {
      name: 'Marc',
      type1: 'Metal',
      type2: 'Ground',
      total: 100,
      hp: 20,
      attack: 30,
      defense: 200,
      special_attack: 65,
      special_defense: 50,
      speed: 20,
      generation: 8,
      legendary: true
    }.transform_keys(&:to_s)
    assert_no_difference('Creature.count') do
      post creature_index_path, params: { creature: create_params }, as: :json
      assert_response :unprocessable_entity
    end
  end

  test 'it can create a creature' do
    create_params = {
      name: 'Marc',
      type1: 'Electric',
      type2: 'Ground',
      total: 100,
      hp: 20,
      attack: 30,
      defense: 200,
      special_attack: 65,
      special_defense: 50,
      speed: 20,
      generation: 8,
      legendary: true
    }.transform_keys(&:to_s)
    assert_difference('Creature.count') do
      post creature_index_path, params: { creature: create_params }, as: :json
      assert_equal create_params, Creature.last.attributes.slice(*create_params.keys.map(&:to_s))
      assert_response :ok
    end
  end

  test 'it can list creatures' do
    flunk('Test not done yet')
    assert_response :ok
  end

  test 'it can update a creature' do
    c = creatures(:one)
    update_params = {
      name: 'Sutcliffe',
      type1: 'Water',
      type2: 'Normal',
      total: 500,
      hp: 90,
      attack: 90,
      defense: 100,
      special_attack: 95,
      special_defense: 70,
      speed: 10,
      generation: 7,
      legendary: false
    }.transform_keys(&:to_s)

    patch creature_path(c), params: { creature: update_params }, as: :json

    assert_equal update_params, c.reload.attributes.slice(*update_params.keys.map(&:to_s))
    assert_response :ok
  end
end
