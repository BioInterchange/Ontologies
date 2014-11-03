#!/usr/bin/env ruby

require 'rexml/document'
require 'rexml/xpath'

# Determines the median value of a non-empty array.
def median(array)
  return (array[(array.length - 1) / 2] + array[array.length / 2]) / 2.0
end

# Reads an ontology in RDF/XML and calculates some basic statistics about words in comments.
def count(filename, comment_query, class_query, namespaces)
  doc = REXML::Document.new(File.new(filename))

  words = 0
  word_list = []
  matches = REXML::XPath.match(doc, comment_query, namespaces)
  matches.each { |element|
    words_in_element = element.text.split(/[^a-zA-Z0-9-]/).select { |token| token[/[a-zA-Z0-9-]+/] }.length
    words += words_in_element
    word_list << words_in_element
  }

  matches = REXML::XPath.match(doc, class_query, namespaces)
  classes = matches.length
  word_list.sort!

  return {
    :words => words,
    :classes => classes,
    :min => word_list[0],
    :max => word_list[-1],
    :median => median(word_list),
    :ratio => words.to_f/classes
  }
end

# Namespaces that are used in the ontologies.
namespaces = { 'cls' => 'http://www.w3.org/2002/07/owl#', 'c' => 'http://www.w3.org/2000/01/rdf-schema#', 'd' => 'http://purl.org/dc/terms/' }

# Calculate word statistics in FALDO, GFVO, SIO, SO, and VariO.
#
# Note: requires a version of VariO with object properties removed, because VariO uses
#       annotation properties for documentation and they are hard to filter on.
faldo = count('gfvo_paper_2014/faldo.xml', '//cls:Class[@about]//c:comment', '//cls:Class[@about]', namespaces)
gfvo = count('gfvo.xml', '//cls:Class[@about]//c:comment', '//cls:Class[@about]', namespaces)
sio = count('gfvo_paper_2014/sio.xml', '//cls:Class[@about]//d:description', '//cls:Class[@about]', namespaces)
so = count('gfvo_paper_2014/so-xp-simple.xml', '//cls:Class[@about]//c:comment', '//cls:Class[@about]', namespaces)
vario = count('gfvo_paper_2014/vario-classes-only.xml', '//cls:Axiom//cls:annotatedTarget', '//cls:Class[@about]', namespaces)

# Output:
#  1. total number of words
#  2. total number of classes
#  3. word/class ratio
#  4. minimum number of words in a comment
#  5. median number of words across all comments
#  6. maximum number of words in a comment
puts "FALDO: #{faldo[:words]} (#{faldo[:classes]} classes, #{faldo[:ratio]} word/class ratio, #{faldo[:min]} min, #{faldo[:median]} median, #{faldo[:max]} max)"
puts "GFVO : #{gfvo[:words]} (#{gfvo[:classes]} classes, #{gfvo[:ratio]} word/class ratio, #{gfvo[:min]} min, #{gfvo[:median]} median, #{gfvo[:max]} max)"
puts "SIO  : #{sio[:words]} (#{sio[:classes]} classes, #{sio[:ratio]} word/class ratio, #{sio[:min]} min, #{sio[:median]} median, #{sio[:max]} max)"
puts "SO   : #{so[:words]} (#{so[:classes]} classes, #{so[:ratio]} word/class ratio, #{so[:min]} min, #{so[:median]} median, #{so[:max]} max)"
puts "VariO: #{vario[:words]} (#{vario[:classes]} classes, #{vario[:ratio]} word/class ratio, #{vario[:min]} min, #{vario[:median]} median, #{vario[:max]} max)"

