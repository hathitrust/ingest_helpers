#!ruby

require 'nokogiri'
require 'open-uri'
require 'uri'

uri = ARGV[0]
namespace = ARGV[1]
raise("usage: get_filenames.rb uri") if !uri
uri_last = URI(uri).path.split('/').last
File.open("#{namespace}_#{uri_last}.txt","w") do |output|
  doc = Nokogiri::HTML(open(uri))
  doc.css('a').map { |a| a.attr('href') }.select { |href| href.match('zip') }
    .map { |href| URI(href).path.split('/').last.tr('+=',':/').sub('.zip','') }.uniq
    .each { |objid| output.puts objid }
end
