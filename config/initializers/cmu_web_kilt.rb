# The site's settings for the Carnegie Mellon Web Kilt's layout
# (cmu-web-kilt). See CmuWebKilt::Configuration for each one.
CmuWebKilt.configure do |config|
  config.site_name = "Seminars & Programs"
  # The parent, linked to its home page
  config.tagline = '<a href="https://www.cmu.edu/teaching/">Eberly Center</a>'.html_safe
  config.roof = :white

  # The footer's address lines, under the site name
  config.footer_lines = [ "Eberly Center", "Carnegie Mellon University", "Tepper Quad, Suite 1310",
                         "4765 Forbes Avenue, Pittsburgh, PA 15213",
                         '<a href="mailto:eberly-assist@andrew.cmu.edu">Contact Us</a>'.html_safe ]
  # A contact address for the footer and the sign-in page; none when nil
  config.contact_email = nil

  # A logo beside the site name: an image in app/assets/images, the words
  # that say where its link goes, and that link
  # config.logo = "logo.png"
  # config.logo_alt = "Your office's home page"
  # config.logo_url = "https://www.cmu.edu/your-office/"

  # The site's own icon, in app/assets/images; CMU's when nil
  config.favicon = nil
  # A Google Tag Manager container (GTM-...), loaded in production only
  config.google_tag = nil
  # Keep the menu closed when a page opens; on a wide screen the template
  # opens it on a page in a submenu
  config.menu_closed = false
  # The app's own stylesheets, after the kit's: names, or :app for all of
  # app/assets/stylesheets (Propshaft 1.0 and later)
  config.stylesheets = [ :app ]
end
