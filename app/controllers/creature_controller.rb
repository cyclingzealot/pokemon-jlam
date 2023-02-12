class CreatureController < ApplicationController
  before_action :set_creature

  def show
  end

  def update
  end

  def create
    if @create.save
      status :no_content
    else
    end
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