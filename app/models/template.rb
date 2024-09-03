class Template < ApplicationRecord
  has_many :items_group
  validates :name, presence: true
  validates :basename, presence: true
  validates :basename, format: { with: /\A[a-zA-Z0-9_]+\z/, message: "only allows letters, numbers, and underscores" }
  validates :filetype, presence: true
  validates :content, presence: true
end
