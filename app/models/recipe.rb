class Recipe < ApplicationRecord
  scope :like, -> (keyword) { where("name like ? or description like ?", "%#{keyword}%", "%#{keyword}%") }
end
