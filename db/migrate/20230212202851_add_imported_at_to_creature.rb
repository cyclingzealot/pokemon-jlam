# frozen_string_literal: true

class AddImportedAtToCreature < ActiveRecord::Migration[7.0]
  def change
    add_column :creatures, :imported_at, :datetime
  end
end
