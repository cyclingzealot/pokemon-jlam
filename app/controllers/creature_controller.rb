# frozen_string_literal: true

class CreatureController < ApplicationController
  before_action :set_creature, except: %i[create index]

  def show
    respond_to do |format|
      format.json { render json: @creature.attributes, status: :ok }
    end
  end

  def index
    @creatures = Creature.all.paginate(page: params[:page])
    render json: @creatures, status: :ok
  end

  def update
    respond_to do |format|
      if @creature.update(creature_params)
        format.json { render json: @creature.reload.attributes, status: :ok }
      else
        format.json { render json: @creature.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    generate_creature

    respond_to do |format|
      if @creature.present? && @creature.save
        format.json { render json: @creature.reload.attributes, status: :ok }
      else
        format.json { render json: { errors: (@errors || @creature&.errors) }, status: :unprocessable_entity }
      end
    end
  end

  def generate_creature
    parametres = creature_params
    parametres[:no] = Creature.maximum(:no) + 1 if parametres[:no].nil?
    begin
      @creature = Creature.new(parametres)
    rescue ArgumentError => e
      @errors = e.message
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

  def creature_params
    params.require(:creature).permit(:name, :type1, :type2, :total, :hp, :attack, :defense, :special_attack,
                                     :special_defense, :speed, :generation, :legendary, :no)
  end
end
