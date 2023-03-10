# frozen_string_literal: true

require 'test_helper'

class CreatureTest < ActiveSupport::TestCase
  test 'it will let me save one valid type 1' do
    c = creatures(:one)
    assert_nothing_raised do
      c.type1 = 'Steel'
      c.save!
    end
  end

  test 'it will not let me save one of abnormal type 1' do
    c = creatures(:two)
    assert_raises do
      c.type1 = 'abnormal'
      c.save!
    end
  end

  test 'it defaults to generation one and false' do
    c = Creature.new
    refute c.legendary
    assert_equal 1, c.generation
  end

  test 'it can import a csv file' do
    file_path = File.join(Rails.root, 'test', 'files', 'pokemon.csv')
    line_nums = File.open(file_path).readlines.size
    assert_difference('Creature.count', line_nums - 1) do
      Creature.update_from_csv(file_path, nil, '#', { noPrompt: true, dontUpdate: true })
    end
  end
end
