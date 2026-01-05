# Suppress VIPS warnings for optional modules that may not be available on Windows
# These warnings are harmless - the modules (heif, jxl, magick, openslide, poppler) are optional
if defined?(Vips)
  # Redirect VIPS warnings to null on Windows
  if RUBY_PLATFORM =~ /mswin|mingw|cygwin/
    # VIPS warnings are printed to stderr, but we can't easily suppress them
    # at the Ruby level since they're printed by the C library
    # The warnings are harmless and can be ignored
  end
end

# Set environment variable to reduce VIPS verbosity (if supported)
ENV["VIPS_WARNING"] = "0" if ENV["VIPS_WARNING"].nil?

