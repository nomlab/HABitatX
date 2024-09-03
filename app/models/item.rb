class Item < ApplicationRecord
  belongs_to :items_group
  validates :name, presence: true
  validates :name, format: { with: /\A[^0-9]/, message: "cannot start with a number" }
  validates :name, format: { with: /\A[a-zA-Z0-9_]+\z/, message: "only allows A-Z,a-z,0-9,_ " }
  validates :dsl_info, presence: true
  validates :items_group_id, presence: true
end
