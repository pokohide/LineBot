class RecipesController < ApplicationController
  include ActionView::Helpers::OutputSafetyHelper
  require 'erb'
  
  def show
    @recipe = Recipe.find_by(rid: params[:rid])
    @steps = @recipe.steps.map{|s| [s.turn.to_i+1, s.image, s.content]}
    #render html: erb('materials', {title: @recipe.name, portion: @recipe.portion, image: @recipe.image, time: @recipe.time, fee: @recipe.fee, materials: @materials}), layout: false
    render html: erb('show', {title: @recipe.name, portion: @recipe.portion, image: @recipe.image, time: @recipe.time, fee: @recipe.fee, steps: @steps}), layout: false
  end

  def materials
    @recipe = Recipe.find_by(rid: params[:rid])
    @materials = @recipe.materials.map {|m| [m.name, m.quantity, m.id]}

    render html: erb('materials', {title: @recipe.name, portion: @recipe.portion, image: @recipe.image, time: @recipe.time, fee: @recipe.fee, materials: @materials}), layout: false
  end

  private
  def erb(fname, opts)
    html = <<TEXT_END
      <% steps = #{opts[:steps] || []} %>
      <% title = '#{opts[:title]}' %>
      <% portion = '#{opts[:portion]}' %>
      <% image = '#{opts[:image]}' %>
      <% fee = '#{opts[:fee]}' %>
      <% time = '#{opts[:time]}' %>
      <% materials = #{opts[:materials] || []} %>
TEXT_END
    html += File.open("#{Rails.root}/app/views/recipes/#{fname}.html.erb", 'r').read
    ERB.new(html).result.html_safe
  end
end
