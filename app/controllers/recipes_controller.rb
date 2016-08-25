class RecipesController < ApplicationController
  include ActionView::Helpers::OutputSafetyHelper
  require 'erb'

  HOST = 'https://mighty-shelf-27620.herokuapp.com'
  
  def show
    @recipe = Recipe.find_by(rid: params[:rid])
    @steps = @recipe.steps.map{|s| [s.turn.to_i+1, s.image, s.content]}
    render html: erb('show', {title: @recipe.name, portion: @recipe.portion, image: @recipe.image, time: @recipe.time, fee: @recipe.fee, steps: @steps}), layout: false
  end

  def materials
    @recipe = Recipe.find_by(rid: params[:rid])
    @materials = @recipe.materials.map {|m| [m.name, m.quantity, m.id]}

    render html: erb('materials', {title: @recipe.name, portion: @recipe.portion, image: @recipe.image, time: @recipe.time, fee: @recipe.fee, materials: @materials}), layout: false
  end

  def cut
    result = tech_url('cut', params[:id])
    render html: tech_erb(result['cut'])
  end

  def yaku
    result = tech_url('yaku', params[:id])
    render html: tech_erb(result['yaku'])
  end

  def share
    ua = request.env["HTTP_USER_AGENT"]
    if ua.include?('Mobile')
      redirect_to 'intent://hoge.com#Intent;scheme=twitter;package=twitter.activity;end'
    elsif ua.include?('Android')
      render html: File.open("#{Rails.root}/app/views/recipes/share.html.erb")
    else
      render json: {rid: params[:rid]}
    end
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

  def tech_erb(opts)
    html = <<TEXT_END
      <% name = '#{opts["name"]}' %>
      <% image = '#{opts["image"] || ""}' %>
      <% explanation = '#{opts["explanation"]}' %>
TEXT_END
    html += File.open("#{Rails.root}/app/views/recipes/tech.html.erb", 'r').read
    ERB.new(html).result.html_safe
  end

  def tech_url(tech, id)
    uri = URI.parse("#{HOST}/#{tech}/#{id}")
    json = Net::HTTP.get(uri)
    JSON.parse(json)
  end
end
