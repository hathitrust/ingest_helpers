#!/usr/bin/env ruby
require('nokogiri')

NAMESPACES = {
  'xsi'      => 'http://www.w3.org/2001/XMLSchema-instance',
  'METS'     => 'http://www.loc.gov/METS/',
  'PREMIS'   => 'info:lc/xmlns/premis-v2',
  'xlink'    => 'http://www.w3.org/1999/xlink',
  'HT'       => 'http://www.hathitrust.org/ht_extension',
  'HTPREMIS' => 'http://www.hathitrust.org/premis_extension',
  'gbs'      => 'http://books.google.com/gbs',
}

class MinimalMets
  attr_reader :capture_date, :creation_agent, :creation_date, :pagedata,
    :reading_order, :scanning_order

  def initialize xml
    @xml = Nokogiri::XML(xml)
    get_creation
    get_read_order
    get_pagedata
  end

  private

  def get_creation
    creation = xpath("//PREMIS:event[PREMIS:eventType='creation']").first
    if creation.nil?
      capture = xpath("//PREMIS:event[PREMIS:eventType='capture']").first
      @capture_date = capture.xpath("PREMIS:eventDateTime").text
    else
      @creation_date = creation.xpath('PREMIS:eventDateTime').text
      @creation_agent = creation.xpath('PREMIS:linkingAgentIdentifier/PREMIS:linkingAgentIdentifierValue').text
    end
  end

  def get_read_order
    read_order = xpath("//METS:mdWrap[@LABEL='reading order']/METS:xmlData").first
    unless read_order.nil?
      @scanning_order = read_order.xpath("gbs:scanningOrder").text
      @reading_order = read_order.xpath("gbs:readingOrder").text
    end
  end

  def get_pagedata
    @pagedata = {}
    get_filenames_by_id

    xpath("/METS:mets/METS:structMap/METS:div[@TYPE='volume']/METS:div[@TYPE='page']").each do |div|
      if div_has_tags?(div)
        get_tags_from_div(div)
      end
    end
  end

  def get_filenames_by_id
    @filenames_by_id = {}
    xpath("/METS:mets/METS:fileSec/METS:fileGrp[@USE='image']/METS:file").each do |file|
      id = file.attributes['ID'].value
      @filenames_by_id[id] = file.xpath('METS:FLocat/@xlink:href').first.value
    end
  end

  def div_has_tags?(div)
    div.attributes.has_key? 'ORDERLABEL' or div.attributes.has_key? 'LABEL'
  end

  def get_tags_from_div(div)
    tags = {}
    tags[:orderlabel] = div.attributes['ORDERLABEL'].value if div.attributes.has_key? 'ORDERLABEL'
    tags[:label] = div.attributes['LABEL'].value if div.attributes.has_key? 'LABEL'
    @pagedata[div_filename(div)] = tags
  end

  def div_filename(div)
    div.xpath('METS:fptr/@FILEID').each do |item|
      if @filenames_by_id.has_key?(item.value)
        return @filenames_by_id[item.value]
      end
    end
  end

  def xpath(path)
    @xml.xpath(path, NAMESPACES)
  end
end

if $0 == __FILE__ and ARGV.length == 1
  mets = nil
  File.open(ARGV[0]) { |f| mets = MinimalMets.new(f.read) }
  puts "capture_date:   #{mets.capture_date}" unless mets.capture_date.nil?
  puts "creation_date:  #{mets.creation_date}" unless mets.creation_date.nil?
  puts "creation_agent: #{mets.creation_agent}" unless mets.creation_agent.nil?
  puts "scanning_order: #{mets.scanning_order}" unless mets.scanning_order.nil?
  puts "reading_order:  #{mets.reading_order}" unless mets.reading_order.nil?
  unless mets.pagedata.empty?
    puts "pagedata:"
    mets.pagedata.to_a.sort.each do |page, tags|
      puts "  #{page}:"
      tags.to_a.sort.each do |tag, value|
        puts "    #{tag}: '#{value}'"
      end
    end
  end
end

# Here are the tests, although you'll have to find the fixtures yourself.
#
# require "mets_to_yaml"
#
# def file_fixture(filename)
#   path = "#{__FILE__.sub(%r{[^/]+$}, '')}fixtures/files/#{filename}"
#
#   File.open(path, 'r') do |file|
#     file.read
#   end
# end
#
# describe MinimalMets do
#   context 'when created with 39015079132588.mets.xml (no tags)' do
#     subject(:mets) do
#       MinimalMets.new(file_fixture('39015079132588.mets.xml'))
#     end
#
#     it { is_expected.to have_attributes(capture_date: '2010-03-17T13:31:46Z') }
#     it { is_expected.to have_attributes(creation_date: nil) }
#     it { is_expected.to have_attributes(creation_agent: nil) }
#     it { is_expected.to have_attributes(scanning_order: nil) }
#     it { is_expected.to have_attributes(reading_order: nil) }
#     it { is_expected.to have_attributes(pagedata: {}) }
#   end
#
#   context 'when created with 39015089739968.mets.xml (born digital, page numbers)' do
#     subject(:mets) do
#       MinimalMets.new(file_fixture('39015089739968.mets.xml'))
#     end
#
#     it { is_expected.to have_attributes(capture_date: nil) }
#     it { is_expected.to have_attributes(creation_date: '2018-02-12T14:48:49-05:00') }
#     it { is_expected.to have_attributes(creation_agent: 'MiU') }
#     it { is_expected.to have_attributes(scanning_order: nil) }
#     it { is_expected.to have_attributes(reading_order: nil) }
#
#     describe '#pagedata' do
#       subject { mets.pagedata }
#
#       it { is_expected.to have_attributes(size: 192) }
#       it { is_expected.to include('00000001.tif' => {:orderlabel => '1'}) }
#       it { is_expected.to include('00000077.jp2' => {:orderlabel => '77'}) }
#     end
#   end
#
#   context 'when created with 39015098803482.mets.xml (fully tagged)' do
#     subject(:mets) do
#       MinimalMets.new(file_fixture('39015098803482.mets.xml'))
#     end
#
#     it { is_expected.to have_attributes(capture_date: '2017-06-14T18:03:11-05:00') }
#
#     describe '#pagedata' do
#       subject { mets.pagedata }
#
#       it { is_expected.to have_attributes(size: 261) }
#       it { is_expected.to include('00000001.jp2' => {:label => 'FRONT_COVER'}) }
#       it { is_expected.to include('00000009.tif' => {:label => 'TITLE', :orderlabel => 'iii'}) }
#       it { is_expected.to include('00000010.tif' => {:orderlabel => 'iv'}) }
#       it { is_expected.to include('00000262.jp2' => {:label => 'BACK_COVER'}) }
#     end
#   end
#
#   context 'when created with 39015079132810.mets.xml (rtl)' do
#     subject(:mets) do
#       MinimalMets.new(file_fixture('39015079132810.mets.xml'))
#     end
#
#     it { is_expected.to have_attributes(scanning_order: 'right-to-left') }
#     it { is_expected.to have_attributes(reading_order: 'right-to-left') }
#   end
# end
