ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

ENV['DISABLE_BOOTSNAP_LOAD_PATH_CACHE'] = '1'
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
