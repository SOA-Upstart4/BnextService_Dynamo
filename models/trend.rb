require 'dynamoid'

class Trend
  include Dynamoid::Document
  table :name => :trends, :key => :id, :read_capacity => 1, :write_capacity => 1
  field :description, :string
  field :categories, :set

  def self.destroy(id)
    find(id).destroy
  end

  def self.delete_all
    all.each(&:delete)
  end
end
