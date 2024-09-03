class ItemsGroup < ApplicationRecord
  belongs_to :template
  has_many :item
  validates :name, presence: true
  validates :name, format: { with: /\A[^0-9]/, message: "cannot start with a number" }
  validates :name, format: { with: /\A[a-zA-Z0-9_]+\z/, message: "only allows A-Z,a-z,0-9,_ " }
  validates :template_id, presence: true
end
