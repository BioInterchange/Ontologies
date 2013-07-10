#!/usr/bin/ruby

base = nil
ontology_base = nil
namespace = nil
external_namespaces = {}
type = nil

term = nil
terms = {}
terms[:object_property] = {}
terms[:datatype_property] = {}
terms[:class] = {}
terms[:named_individual] = {}

current_term = {}

STDIN.each { |line|
  line.chomp!
  line.strip!

  if line.start_with?('<rdf:RDF xmlns="http://www.biointerchange.org/') then
    base = line.sub(/^[^"]+"/, '').sub(/".*$/, '')
    ontology_base = base.sub(/\#$/, '')
    namespace = base.sub(/^.*\//, '').sub(/\#$/, '')
    next
  elsif line.start_with?('<owl:ObjectProperty rdf:about="http://www.biointerchange.org/') then
    type = :object_property
    term = line.sub(/^[^#]+#/, '').sub(/".*$/, '')
    terms[type][term] = {}
    next
  elsif line.start_with?('<owl:DatatypeProperty rdf:about="http://www.biointerchange.org/') then
    type = :datatype_property
    term = line.sub(/^[^#]+#/, '').sub(/".*$/, '')
    terms[type][term] = {}
    next
  elsif line.start_with?('<owl:Class rdf:about="http://www.biointerchange.org/') then
    type = :class
    term = line.sub(/^[^#]+#/, '').sub(/".*$/, '')
    terms[type][term] = {}
    next
  elsif line.start_with?('<owl:NamedIndividual rdf:about="http://www.biointerchange.org/') then
    type = :named_individual
    term = line.sub(/^[^#]+#/, '').sub(/".*$/, '')
    terms[type][term] = {}
    next
  elsif line.start_with?('xmlns:') then
    external_namespaces[line.sub(/^[^:]+:/, '').sub(/=.*$/, '')] =  line.sub(/^[^"]+"/, '').sub(/".*$/, '')
    next
  elsif line.empty? then
    type = nil
    next
  end

  next unless type

  if line.start_with?('<rdfs:label>') then
    terms[type][term][:label] = line.sub(/^[^>]+>/, '').sub(/<.*$/, '')
    next
  elsif line.start_with?('<rdfs:comment xml:lang="en">') then
    terms[type][term][:comment] = line.sub(/^[^>]+>/, '').sub(/<[^<]+$/, '')
    next
  elsif line.start_with?('<rdfs:subClassOf rdf:resource="http://www.biointerchange.org/') then
    terms[type][term][:subclassof] = line.sub(/^[^#]+#/, '').sub(/"[^"]+$/, '')
    next
  elsif line.start_with?('<rdf:type rdf:resource="http://www.biointerchange.org/') then
    terms[type][term][:type] = line.sub(/^[^#]+#/, '').sub(/"[^"]+$/, '')
    next
  elsif line.start_with?('<rdfs:domain ') then
    if line.start_with?('<rdfs:domain rdf:resource="http://www.biointerchange.org/') then
      terms[type][term][:local_domain] = line.sub(/^[^#]+#/, '').sub(/"[^"]+$/, '')
    else
      terms[type][term][:external_domain] =  line.sub(/^[^"]+"/, '').sub(/".*$/, '')
    end
    next
  elsif line.start_with?('<rdfs:range ') or line.start_with?('<owl:onDatatype') then
    if line.start_with?('<rdfs:range rdf:resource="http://www.biointerchange.org/') then
      terms[type][term][:local_range] = line.sub(/^[^#]+#/, '').sub(/"[^"]+$/, '')
    else
      terms[type][term][:external_range] =  "#{external_namespaces[line.sub(/^[^&]+&/, '').sub(/;.*$/, '')]}#{line.sub(/^.+;/, '').sub(/".*$/, '')}"
    end
    next
  elsif line.start_with?('<owl:withRestrictions') then
    terms[type][term][:has_restrictions] = true
    next
  end
}

puts '<p>'
puts "  Ontology namespace \"#{namespace}\": #{base}"
puts '</p>'

puts '<h2>Classes</h2>'

terms[:class].keys.sort.each { |term|
  puts '<p>'
  puts "  <h3 id=\"#class#{term}\">Class #{namespace}:#{term}</h3>"
  puts "  <div><i>Subclass of:</i> <a href=\"#class#{terms[:class][term][:subclassof]}\">#{terms[:class][term][:subclassof]}</a></div>" if terms[:class][term][:subclassof]
  related = []
  terms[:named_individual].keys.sort.each { |named_individual|
    related << "<a href=\"#namedIndividual#{named_individual}\">#{named_individual}</a>" if terms[:named_individual][named_individual][:type] == term
  }
  puts "  <div><i>Individuals:</i> #{related.join(', ')}</div>" unless related.empty?
  puts "  <div><i>Label:</i> #{terms[:class][term][:label]}</div>"
  puts "  <div><i>Comment:</i> #{terms[:class][term][:comment]}</div>"
  puts '</p>'
}

puts '<h2>Named Individuals (Constants, Enumerations)</h2>'

terms[:named_individual].keys.sort.each { |term|
  puts '<p>'
  puts "  <h3 id=\"#namedIndividual#{term}\">Named Individual #{namespace}:#{term}</h3>"
  puts "  <div><i>Type:</i> #{terms[:named_individual][term][:type]}</div>"
  puts "  <div><i>Label:</i> #{terms[:named_individual][term][:label]}</div>"
  puts "  <div><i>Comment:</i> #{terms[:named_individual][term][:comment]}</div>"
  puts '</p>'
}

puts '<h2>Object Properties (Referencing other Class Instances)</h2>'

terms[:object_property].keys.sort.each { |term|
  puts '<p>'
  puts "  <h3 id=\"#objectProperty#{term}\">Object Property #{namespace}:#{term}</h3>"
  puts "  <div><i>Domain:</i> <a href=\"#class#{terms[:object_property][term][:local_domain]}\">#{terms[:object_property][term][:local_domain]}</a></div>" if terms[:object_property][term][:local_domain]
  puts "  <div><i>Domain:</i> <a href=\"#{terms[:object_property][term][:external_domain]}\">#{terms[:object_property][term][:external_domain]}</a></div>" if terms[:object_property][term][:external_domain]
  puts "  <div><i>Range:</i> <a href=\"#class#{terms[:object_property][term][:local_range]}\">#{terms[:object_property][term][:local_range]}</a></div>" if terms[:object_property][term][:local_range]
  puts "  <div><i>Range:</i> <a href=\"#{terms[:object_property][term][:external_range]}\">#{terms[:object_property][term][:external_range]}</a></div>" if terms[:object_property][term][:external_range]
  puts "  <div><i>Label:</i> #{terms[:object_property][term][:label]}</div>"
  puts "  <div><i>Comment:</i> #{terms[:object_property][term][:comment]}</div>"
  puts '</p>'
}

puts '<h2>Datatype Properties (Strings, Numbers, Dates, etc.)</h2>'

terms[:datatype_property].keys.sort.each { |term|
  puts '<p>'
  puts "  <h3 id=\"#datatypeProperty#{term}\">Datatype Property #{namespace}:#{term}</h3>"
  puts "  <div><i>Domain:</i> <a href=\"#class#{terms[:datatype_property][term][:local_domain]}\">#{terms[:datatype_property][term][:local_domain]}</a></div>" if terms[:datatype_property][term][:local_domain]
  puts "  <div><i>Domain:</i> <a href=\"#{terms[:datatype_property][term][:external_domain]}\">#{terms[:datatype_property][term][:external_domain]}</a></div>" if terms[:datatype_property][term][:external_domain]
  puts "  <div><i>Range:</i> <a href=\"#class#{terms[:datatype_property][term][:local_range]}\">#{terms[:datatype_property][term][:local_range]}</a></div>" if terms[:datatype_property][term][:local_range]
  puts "  <div><i>Range:</i> <a href=\"#{terms[:datatype_property][term][:external_range]}\">#{terms[:datatype_property][term][:external_range]}</a></div>" if terms[:datatype_property][term][:external_range]
  puts "  <div>The data range has restrictions imposed on it. Please refer to the <a href=\"#{ontology_base}\">OWL file</a> for further details.</div>" if terms[:datatype_property][term][:has_restrictions]
  puts "  <div><i>Label:</i> #{terms[:datatype_property][term][:label]}</div>"
  puts "  <div><i>Comment:</i> #{terms[:datatype_property][term][:comment]}</div>"
  puts '</p>'
}

