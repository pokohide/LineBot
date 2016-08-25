class User < ApplicationRecord

  def cooking?
    self.cook
  end
end
