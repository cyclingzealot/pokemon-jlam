# frozen_string_literal: true

class Creature < ApplicationRecord
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
end
