# frozen_string_literal: true

class CreatureController < ApplicationController
  before_action :set_creature

  def show
    respond_to do |format|
      format.json { redner json: @creature.attributes }
    end
  end

  def update; end

  def create
    return unless @create.save

    status :no_content
  end

  def destroy
    @creature.destroy

    respond_to do |format|
      format.json { head :no_content }
    end
  end

  private

  def set_creature
    @creature = Creature.find(params[:id])
  end
end
