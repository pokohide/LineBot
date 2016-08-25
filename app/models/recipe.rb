class Recipe < ApplicationRecord  
  has_many :materials
  has_many :steps
  scope :like, -> (keyword) { where("name like ? or description like ?", "%#{keyword}%", "%#{keyword}%") }
end
