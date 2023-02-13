# frozen_string_literal: true

class CreatureController < ApplicationController
  before_action :set_creature

  def show
    respond_to do |format|
      format.json { render json: @creature.attributes }
    end
  end

  def update
    respond_to do |format|
      if @creature.update(creature_params)
        format.json { render json: @creature.attributes, status: :ok }
      else
        format.json { render json: @creature.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    status (@create.save ? :no_content : :unprocessable_entity)
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

  def creature_params
    params.require(:creature).permit(:name, :type1, :type2, :total, :hp, :attack, :defense, :special_attack, :special_defense, :speed, :generation, :legendary)
  end
end
