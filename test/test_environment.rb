# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require 'secure_web_token'

require 'coerce_boolean'
require 'active_support'
require 'active_support/test_case'
require 'minitest/reporters'

Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(:color => true)]

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

require 'minitest/autorun'
