require 'dynamoid'

class Trend
  include Dynamoid::Document
  field :description, :string
  field :categories, :set

  def self.destroy(id)
    find(id).destroy
  end

  def self.delete_all
    all.each(&:delete)
  end
end
