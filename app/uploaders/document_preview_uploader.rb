# encoding: utf-8

class DocumentPreviewUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  # storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def default_url
    # For Rails 3.1+ asset pipeline compatibility:
    ("fallback/docs/" + [version_name, "default.png"].compact.join('_'))
  end

  process :resize_to_fit => [1000, 1000]

  version :large do
    process :resize_and_pad => [570, 410]
  end

  version :medium_wide, from: :large do
    process :resize_and_pad => [320, 180]
  end

  version :medium, from: :large do
    process :resize_and_pad => [150, 150]
  end

  version :small, from: :medium do
    process :resize_and_pad => [50, 50]
  end
end
