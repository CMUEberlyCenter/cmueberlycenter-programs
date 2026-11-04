# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def document_title
    update_document_title unless content_for? :document_title
    content_for :document_title
  end

  def update_document_title(add: [], sep: ' - ')
    document_title = Array(add).join(sep)
    document_title += sep unless document_title.empty?

    document_title += if content_for? :document_title
                        content_for :document_title
                      else
                        ['Seminars & Workshops',
                         'Eberly Center',
                         'Carnegie Mellon University'].join(sep)
                      end

    content_for(:document_title, document_title, flush: true)
  end

  def breadcrumbs
    content_for :breadcrumbs
  end

  def update_breadcrumbs(add: [], sep: '&nbsp;›&nbsp;')
    unless content_for? :breadcrumbs
      content_for :breadcrumbs do
        [
          link_to('Eberly Center', eberly_url),
          link_to('Seminars & Workshops', root_url)
        ].join(sep).html_safe
      end
    end

    return if add.blank?

    content_for(:breadcrumbs, Array(add).join(sep).prepend(sep).html_safe)
  end

  def flash_css_class(name)
    "flash-#{name} " + case name
                       when 'success'
                         'green invert'
                       when 'error'
                         'red invert'
                       else
                         'gold'
                       end
  end

  def sidebar_note
    content_for :sidebar_note
  end

  def update_sidebar_note(note)
    content_for(:sidebar_note, note.html_safe)
  end
end
