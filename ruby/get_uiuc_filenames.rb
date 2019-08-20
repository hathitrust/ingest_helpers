#!ruby

require 'nokogiri'
require 'open-uri'
require 'uri'

uri = ARGV[0]
raise("usage: get_filenames.rb uri") if !uri
uri_last = URI(uri).path.split('/').last
File.open("#{uri_last}.txt","w") do |output|
  doc = Nokogiri::HTML(open(uri))
  doc.css('a').map { |a| a.attr('href') }.select { |href| href.match('zip') }.each do  |href|
    output.puts URI(href).path.split('/').last.sub('.zip','')
  end
end
