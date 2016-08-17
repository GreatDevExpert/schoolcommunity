# encoding: utf-8

class AvatarUploader < CarrierWave::Uploader::Base

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

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    # For Rails 3.1+ asset pipeline compatibility:
    if model.is_a?(User)
      ("fallback/users/" + [version_name, "default.png"].compact.join('_'))
    elsif model.is_a?(School)
      ("fallback/schools/" + [version_name, "default.png"].compact.join('_'))
    elsif model.is_a?(Group)
      ("fallback/groups/" + [version_name, "default.png"].compact.join('_'))
    end
  end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:

  process :remove_animation
  process :auto_orient
  process :resize_to_fit => [500, 500]

  version :large do
    process :resize_and_pad => [300, 300]
  end

  version :medium_wide, from: :large do
    # matching the medium thumb from video_info gem
    process :resize_and_pad => [320, 180]
  end

  version :medium, from: :large do
    process :resize_and_pad => [150, 150]
  end

  version :small, from: :medium do
    process :resize_and_pad => [50, 50]
  end

  version :tiny, from: :small do
    process :resize_and_pad => [25, 25]
  end

  # some image uploads were sideways, this helps it respect the orientation of the photo
  def auto_orient
    manipulate! do |image|
      image.auto_orient
      image
    end
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png bmp)
  end

  # http://stackoverflow.com/questions/13480499/carrierwave-minimagick-how-to-squash-animated-gifs-to-their-first-frame

  def remove_animation
    manipulate! do |img|
      if img.mime_type.match /gif/
        img.collapse!
      end
      img
    end
  end


  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end
