class RecipesController < ApplicationController
  include ActionView::Helpers::OutputSafetyHelper
  def show
    @recipe = Recipe.find_by(rid: params[:rid])
    
    render text: erb('show')
  end

  def materials
    @recipe = Recipe.find_by(rid: params[:rid])
    @materials = @recipe.materials.map {|m| [m.name, m.quantity, m.id]}

    render html: erb('materials', {title: @recipe.name, portion: @recipe.portion, image: @recipe.image, time: @recipe.time, fee: @recipe.fee, materials: @materials}), layout: false
  end

  private
  def erb(fname, opts)
    require 'erb'
    html = <<TEXT_END
      <% title = '#{opts[:title]}' %>
      <% portion = '#{opts[:portion]}' %>
      <% image = '#{opts[:image]}' %>
      <% fee = '#{opts[:fee]}' %>
      <% time = '#{opts[:time]}' %>
      <% materials = #{opts[:materials]} %>
TEXT_END
    html += File.open("#{Rails.root}/app/views/recipes/#{fname}.html.erb", 'r').read
    ERB.new(html).result.html_safe
  end
end
