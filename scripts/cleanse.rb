#!/usr/bin/ruby

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

# There will be SIO/SO classes/properties in the file. Remember owl:equivalentClass 
# and owl:equivalentProperty references to GFVO and get rid of the SIO/SO definitions in here.
read_ext_mapping = nil
ext_mapping = {}

STDIN.each { |line|
  line.chomp!

  # If this is the version number, then increase the patch level by one.
  if line.strip.match(/<owl:versionInfo>\d+\.\d+\.\d+<\/owl:versionInfo>/) then
    major_version, minor_version, patch_level = line.strip.scan(/(\d+)\.(\d+)\.(\d+)/).flatten
    puts "#{line.sub(/\S.*$/, '')}<owl:versionInfo>#{major_version}.#{minor_version}.#{patch_level.to_i + 1}</owl:versionInfo>"
    next
  end

  # Find SIO/SO class definitions, remember the equivalence in the next line and skip the rest.
  if line.match(/^\s*<(owl:Class|rdf:Description) rdf:about="&sio;SIO_/) or
     line.match(/^\s*<(owl:Class|rdf:Description) rdf:about="&obo;SO_/) then
    read_ext_mapping = line.sub(/^[^"]*"/, '').sub(/".*$/, '')
    skip_until_matching = "#{line.sub(/\S.*$/, '')}</#{line.scan(/owl:Class|rdf:Description/)[0]}>"
    next
  end

  # Read actual mapping to SIO/SO (see previous if-then).
  if read_ext_mapping then
    assigned_class = line.sub(/^[^"]*"/, '').sub(/".*$/, '')
    if ext_mapping.has_key?(assigned_class) then
      ext_mapping[assigned_class] += [ read_ext_mapping ]
    else
      ext_mapping[assigned_class] = [ read_ext_mapping ]
    end
    read_ext_mapping = nil
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

  # If this is a class with SIO/SO mapping, then output the mapping here.
  if line.strip.start_with?('<owl:Class rdf:about="http://www.biointerchange.org/') then
    defined_class = line.sub(/^[^"]*"/, '').sub(/".*$/, '')
    if ext_mapping.has_key?(defined_class) then
      indent = line.sub(/\S.*$/, '')
      ext_mapping[defined_class].each { |resource|
        line << "\n#{indent}    <owl:equivalentClass rdf:resource=\"#{resource}\"/>"
      }
    end
  end

  # If this is a property with SIO/SO mapping, then output the mapping here.
  if line.match(/^\s*<owl:(Datatype|Object)Property rdf:about="http:\/\/www\.biointerchange\.org\//) then
    defined_property = line.sub(/^[^"]*"/, '').sub(/".*$/, '')
    if ext_mapping.has_key?(defined_property) then
      indent = line.sub(/\S.*$/, '')
      ext_mapping[defined_property].each { |resource|
        line << "\n#{indent}    <owl:equivalentProperty rdf:resource=\"#{resource}\"/>"
      }
    end
  end

  puts line

  # Remember whether this line was an empty line. Used for supressing the output of
  # consecutive empty lines.
  was_empty_line = line.strip.empty?
}

