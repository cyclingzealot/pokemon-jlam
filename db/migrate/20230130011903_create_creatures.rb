# frozen_string_literal: true

class CreateCreatures < ActiveRecord::Migration[7.0]
  def change
    create_table :creatures do |t|
      t.integer :no, null: false
      t.string :name, null: false
      t.integer :type1, null: false
      t.integer :type2, null: true
      t.integer :total, null: false
      t.integer :hp, null: false
      t.integer :attack, null: false
      t.integer :defense, null: false
      t.integer :special_attack, null: false
      t.integer :special_defense, null: false
      t.integer :speed, null: false
      t.integer :genneration, null: false, default: 1
      t.boolean :legendary, null: false, default: false

      t.timestamps
    end
  end
end
