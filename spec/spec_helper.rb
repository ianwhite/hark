$LOAD_PATH.unshift File.dirname('../lib')

require 'rspec'

begin
  require 'coveralls'
  Coveralls.wear!
rescue LoadError
end
