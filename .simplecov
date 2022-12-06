if ENV['COVERAGE']
  SimpleCov.start do
    enable_coverage :branch # available in ruby >= 2.5, already required by actionpack 6
    add_filter '/spec/'
  end
end
