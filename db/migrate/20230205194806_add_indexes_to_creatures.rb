class AddIndexesToCreatures < ActiveRecord::Migration[7.0]
  def change
    add_index :creatures, :name, unique: true
    add_index :creatures, :no
    add_index :creatures, :type1
    add_index :creatures, :type2
    add_index :creatures, :hp
    add_index :creatures, :attack
    add_index :creatures, :defense
    add_index :creatures, :generation
    add_index :creatures, :legendary
  end
end
