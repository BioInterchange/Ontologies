#!/usr/bin/ruby

require 'optparse'

# Reads GFVO from STDIN and outputs a "cleaned" version of it.
# "Clean" means that it does not contain classes or individuals that fall
# outside the scope of our ontologies context (like, Gene Ontology abbreviation
# collection URIs).
# The script also increases the patch version number automatically, since
# this script should only be run when generating a fresh version of GFVO.

# Remembers whether the last line was an empty line. Used for preventing the
# output of multiple empty lines in a row.
was_empty_line = false

# String that needs to be matched in order to turn on output again. Is used to
# supress output that stretches over multiple lines.
skip_until_matching = nil

# There will be SIO classes in the file. Remember owl:equivalentCLass references
# to GFVO and get rid of the SIO class definition in here.
read_sio_mapping = nil
sio_mapping = {}

STDIN.each { |line|
  line.chomp!

  # If this is the version number, then increase the patch level by one.
  if line.strip.match(/<owl:versionInfo>\d+\.\d+\.\d+<\/owl:versionInfo>/) then
    major_version, minor_version, patch_level = line.strip.scan(/(\d+)\.(\d+)\.(\d+)/).flatten
    puts "#{line.sub(/\S.*$/, '')}<owl:versionInfo>#{major_version}.#{minor_version}.#{patch_level.to_i + 1}</owl:versionInfo>"
    next
  end

  # Find SIO class definitions, remember the equivalence in the next line and skip the rest.
  if line.strip.start_with?('<owl:Class rdf:about="&sio;SIO_') then
    read_sio_mapping = line.sub(/^[^"]*"/, '').sub(/".*$/, '')
    skip_until_matching = "#{line.sub(/\S.*$/, '')}</owl:Class>"
    next
  end

  # Read actual mapping to SIO (see previous if-then).
  if read_sio_mapping then
    sio_mapping[line.sub(/^[^"]*"/, '').sub(/".*$/, '')] = read_sio_mapping
    read_sio_mapping = nil
    next
  end

  # If there is a string set for matching, then do not output anything
  # until the string is matched (see below).
  next if skip_until_matching and not line == skip_until_matching

  # If there is a string set for matching, and it actually matches, then
  # do not output it, but turn on the default behaviour of outputting every
  # line again.
  if skip_until_matching and line == skip_until_matching then
    skip_until_matching = nil
    next
  end

  # If a comment or one-line definition do not refer to a BioInterchange URI,
  # then do not output them.
  next if line.strip.match(/^<!-- http:.*-->$/) and not line.match(/http:\/\/www\.biointerchange\.org/)
  next if line.strip.match(/^<owl:Class.*\/>/) and not line.match(/http:\/\/www\.biointerchange\.org/)

  # If there is a top-level definition about something non-BioInterchange,
  # then skip it. Top-level is identified by four leading spaces.
  if line.start_with?('    <owl:Class rdf:about="&') or line.start_with?('    <rdf:Description rdf:about="&') then
    skip_until_matching = "    </#{line.scan(/[or][wd][lf]:[CD]\S+/)[0]}>"
    next
  end

  # If a multi-line individual is seen that falls outside the scope of BioInterchange
  # URIs, then supress its output until the matching closing XML-tag is found.
  if line.strip.match(/^<owl:Thing.*[^\/]>/) and not line.match(/http:\/\/www\.biointerchange\.org/) then
    skip_until_matching = "#{line.sub(/\S.*$/, '')}</owl:Thing>"
    next
  end

  # Consecutive empty lines are supressed, i.e. only single empty lines are permitted.
  next if line.strip.empty? and was_empty_line

  # If this is a class with SIO mapping, then output the mapping here.
  if line.strip.start_with?('<owl:Class rdf:about="http://www.biointerchange.org/') then
    defined_class = line.sub(/^[^"]*"/, '').sub(/".*$/, '')
    if sio_mapping.has_key?(defined_class) then
      line << "\n#{line.sub(/\S.*$/, '')}    <owl:equivalentClass rdf:resource=\"#{sio_mapping[defined_class]}\"/>"
    end
  end

  puts line

  # Remember whether this line was an empty line. Used for supressing the output of
  # consecutive empty lines.
  was_empty_line = line.strip.empty?
}

