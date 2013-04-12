#!/usr/bin/ruby

require 'net/ftp'

if ARGV.length != 0 then
  puts 'Usage: go_xref2xsd_pattern.rb'
  puts ''
  puts 'Retrieves GO.xref_abbs from geneontology.org and outputs its URIs as xsd:pattern.'
  exit 1
end

ftp = Net::FTP.open('ftp.geneontology.org')
ftp.login
ftp.chdir('pub/go/doc')

urls = {}
local_id_syntax = nil
ftp.retrlines('RETR GO.xrf_abbs') { |line|
  line.chomp!
  line.strip!

  # Skip comments:
  next if line.start_with?('!')

  # If there is an empty line, then we are outside of the scope of a record.
  # Reset variables and get ready for a new record...
  if line.empty? then
    local_id_syntax = nil
    url_syntax = nil
    next
  end

  # A regexp that denotes acceptable accessions/identifiers; needs to come before 'url_syntax'.
  if line.start_with?('local_id_syntax:') then
    local_id_syntax = line.sub(/^local_id_syntax:\s*\^/, '').sub(/\$$/, '')
    # Replace some regexp shorthands with explicit character classes, so that HermiT recognizes them:
    local_id_syntax.gsub!(/\\d/, '[0-9]')
    local_id_syntax.gsub!(/\\w/, '[0-9a-zA-Z_]')
    next
  end

  # The actual URL to content, which is being treated as the end of a record.
  if line.start_with?('url_syntax:') then
    url = line.sub(/^url_syntax:\s*/, '')
    # Escape characters that have a special meaning in xsd:pattern
    url.gsub!(/([\\|^?*+.{}()\[\]-])/, '\\\\\1')
    # If there is a local_id_syntax, then use it here, or otherwise allow for an arbitrary non-empty id:
    if local_id_syntax then
      url.sub!(/\\\[example_id\\\]/, local_id_syntax)
    else
      url.sub!(/\\\[example_id\\\]/, '.+')
    end
    # If there are other accession/identifier placeholders, then also replace those:
    url.gsub!(/\\\[.+?\\\]/, '.+')
    urls[url] = true
    local_id_syntax = nil
  end
}

puts urls.keys.join('|')

