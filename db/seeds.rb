# frozen_string_literal: true
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

if Creature.count > 0
  warn "Looks like the database is already seeded"
  exit 0
end

file_path = File.join(Rails.root, "data", "pokemon.csv")
raise "File #{file_path} does not exist" unless File.exist?(file_path)

Creature.update_from_csv(file_path, nil, "#", { noPrompt: true, dontUpdate: true })
