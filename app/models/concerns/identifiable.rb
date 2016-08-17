# Helper to generate a unique identifier for a model
module Identifiable
 extend ActiveSupport::Concern

  def identifier
    [self.class.to_s, self.id].join("|")
  end

  def identifier=(identifier)
    (class_name, id) = identifier.split("|")
    return nil unless class_name && id

    object = class_name.constantize.find(id)

    if self.respond_to?("#{class_name.downcase}=")
      self.send("#{class_name.downcase}=", object)
    end
  end

  def self.from_identifier(identifier)
    (class_name, id) = identifier.split("|")
    return nil unless class_name && id

    class_name.constantize.find(id)
  end
end
