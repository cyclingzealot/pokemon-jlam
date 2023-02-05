class RenameGennerationToGenerationInCreatures < ActiveRecord::Migration[7.0]
  def change
    rename_column :creatures, :genneration, :generation
  end
end
