# frozen_string_literal: true

class Creature < ApplicationRecord
  extend Loadable
  TYPES = {
    Normal: 1,
    Bug: 2,
    Dark: 3,
    Dragon: 4,
    Electric: 5,
    Fairy: 6,
    Fighting: 7,
    Fire: 8,
    Flying: 9,
    Ghost: 10,
    Grass: 11,
    Ground: 12,
    Ice: 13,
    Poison: 14,
    Psychic: 15,
    Rock: 16,
    Steel: 17,
    Water: 18
  }.freeze

  enum :type1, TYPES.clone
  enum :type2, TYPES.clone, prefix: true

  IMPORT_MAPPING = {
    no: '#',
    name: 'Name',
    type1: 'Type 1',
    type2: 'Type 2',
    total: 'Total',
    hp: 'HP',
    attack: 'Attack',
    defense: 'Defense',
    special_attack: 'Sp. Atk',
    special_defense: 'Sp. Def',
    speed: 'Speed',
    generation: 'Generation',
    legendary: 'Legendary'
  }
end
