require 'dynamoid'

class Article
  include Dynamoid::Document
  field :title, :string
  field :author, :string
  field :date, :string
  field :tags, :text
  field :link, :string

  def self.destroy(id)
    find(id).destroy
  end

  def self.delete_all
    all.each(&:delete)
  end
end
