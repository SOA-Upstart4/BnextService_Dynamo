require 'dynamoid'

class Article
  include Dynamoid::Document
  table :name => :articles, :key => :id, :read_capacity => 3, :write_capacity => 3
  field :title, :string
  field :author, :string
  field :date, :string
  field :tags, :set
  field :link, :string

  def self.destroy(id)
    find(id).destroy
  end

  def self.delete_all
    all.each(&:delete)
  end
end
