require 'action_view/helpers'

module DocumentHelper

  def file_icon(file_name)
    return if file_name.nil?
    extension = File.extname(file_name)
    case extension
      when '.pdf'
        fa_icon 'file-pdf-o 5x'
      when '.xls', '.xlsx'
        fa_icon 'file-excel-o 5x'
      when '.doc', '.docx'
        fa_icon 'file-word-o 5x'
      else
        fa_icon 'file-text-o 5x'
    end
  end

end