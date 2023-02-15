# frozen_string_literal: true

class CreatureController < ApplicationController
  before_action :set_creature, except: %i[create index]

  def show
    render json: @creature.attributes, status: :ok
  end

  def index
    page = params.fetch(:page, '1')
    page = page.match(/\A[0-9]+\Z/) ? page.to_i : 1
    @creatures = Creature.all.paginate(page:)
    render json: generate_hash(page), status: :ok
  end

  def generate_hash(page)
    {
      links: {
        self: request.url,
        next: creature_index_url(page: page + 1),
        last: creature_index_url(page: last_page)
      },
      data: @creatures.map do |c|
        c.attributes.merge({ links: { self: creature_url(c) } })
      end
    }
  end

  def last_page
    @last_page ||= (@creatures.size.to_f / 30).ceil
  end

  def update
    if @creature.update(creature_params)
      render json: @creature.reload.attributes, status: :ok
    else
      render json: @creature.errors, status: :unprocessable_entity
    end
  end

  def create
    generate_creature

    if @creature.present? && @creature.save
      render json: @creature.reload.attributes, status: :ok
    else
      render json: { errors: (@errors || @creature&.errors) }, status: :unprocessable_entity
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

    head :no_content
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
