class Item < ApplicationRecord
  belongs_to :template
  validates :name, presence: true, uniqueness: true
  validates :template_id, presence: true
  validates :dsl_info, presence: true
end
