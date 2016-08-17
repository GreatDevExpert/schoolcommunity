class Battles::NameItemsForm < Reform::Form  
  property :first_item_name
  property :second_item_name
  property :description
  # property :battle_length

  validates :first_item_name,  presence: true
  validates :second_item_name,  presence: true
  validates :description,  presence: true

end