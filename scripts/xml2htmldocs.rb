#!/usr/bin/ruby

def origin_tag(uri)
  return '<span style="margin-right: 4px;" class="badge alert-danger">GFF3</span>' if uri == 'http://sequenceontology.org/resources/gff3.html'
  return '<span style="margin-right: 4px;" class="badge alert-info">GTF</span>' if uri == 'http://www.ensembl.org/info/website/upload/gff.html'
  return '<span style="margin-right: 4px;" class="badge alert-success">GVF</span>' if uri == 'http://sequenceontology.org/resources/gvf.html'
  return '<span style="margin-right: 4px;" class="badge alert-warning">VCF</span>' if uri == 'http://www.1000genomes.org/wiki/Analysis/Variant%20Call%20Format/vcf-variant-call-format-version-41'
  return "<i>#{uri}</i>"
end

def create_linkouts(type, links)
  if type == :class then
    return links.map { |link|
      accession = link.sub(/^&sio;/, '')
      "<a href=\"http://bioportal.bioontology.org/ontologies/SIO/?p=classes&conceptid=http%3A%2F%2Fsemanticscience.org%2Fresource%2F#{accession}\">#{accession}</a>"
    }.join(',')
  end
  return links.join(',').gsub(/&sio;/, '')
end

def comment(text, terms)
  quotations = text.scan(/&quot;[^&]+&quot;/)
  quotations.each { |quote|
    purported_label = quote[6..-7]
    terms[:class].keys.each { |term| text.gsub!(quote, "<a href=\"#class#{term}\">#{purported_label}</a>") if terms[:class][term][:label] == purported_label }
    terms[:named_individual].keys.each { |term| text.gsub!(quote, "<a href=\"#namedIndividual#{term}\">#{purported_label}</a>") if terms[:named_individual][term][:label] == purported_label }
    terms[:object_property].keys.each { |term| text.gsub!(quote, "<a href=\"#objectProperty#{term}\">#{purported_label}</a>") if terms[:object_property][term][:label] == purported_label }
    terms[:datatype_property].keys.each { |term| text.gsub!(quote, "<a href=\"#datatypeProperty#{term}\">#{purported_label}</a>") if terms[:datatype_property][term][:label] == purported_label }
  }
  return text
end

left_margin_items = '16px'
bottom_margin_items = '16px'

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
collection = []

state = :idle

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

  terms[type][term][:defined_by] = [] unless terms[type][term][:defined_by]
  terms[type][term][:equivalent_class] = [] unless terms[type][term][:equivalent_class]
  terms[type][term][:equivalent_property] = [] unless terms[type][term][:equivalent_property]

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
      terms[type][term][:local_domain] = [ line.sub(/^[^#]+#/, '').sub(/"[^"]+$/, '') ]
    else
      terms[type][term][:external_domain] = line.sub(/^[^"]+"/, '').sub(/".*$/, '')
    end
    next
  elsif line.start_with?('<rdfs:domain>') then
    collection = []
    state = :domain
    next
  elsif line.start_with?('<owl:Class>') and state == :domain then
    state = :class
  elsif line.start_with?('<owl:unionOf rdf:parseType="Collection">') and state == :class then
    state = :union
    next
  elsif line.start_with?('</rdfs:domain') then
    terms[type][term][:local_domain] = collection
    state = :idle
    next
  elsif line.start_with?('<rdf:Description ') and state == :union then
    # Assuming local domain/range here.
    collection << line.sub(/^[^#]+#/, '').sub(/"[^"]+$/, '')
    next
  elsif line.start_with?('<rdfs:range ') or line.start_with?('<owl:onDatatype') then
    if line.start_with?('<rdfs:range rdf:resource="http://www.biointerchange.org/') then
      terms[type][term][:local_range] = line.sub(/^[^#]+#/, '').sub(/"[^"]+$/, '')
    else
      if line.start_with?('<rdfs:range rdf:resource="http://') then
        terms[type][term][:external_range] = line.sub(/^[^"]+"/, '').sub(/".*$/, '')
      else
        terms[type][term][:external_range] = "#{external_namespaces[line.sub(/^[^&]+&/, '').sub(/;.*$/, '')]}#{line.sub(/^.+;/, '').sub(/".*$/, '')}"
      end
    end
    next
  elsif line.start_with?('<rdfs:isDefinedBy ') then
    terms[type][term][:defined_by] << line.sub(/^[^"]+"/, '').sub(/".*$/, '')
    next
  elsif line.start_with?('<owl:withRestrictions') then
    terms[type][term][:has_restrictions] = true
    next
  elsif line.start_with?('<owl:equivalentClass') then
    terms[type][term][:equivalent_class] << line.sub(/^[^"]+"/, '').sub(/".*$/, '')
    next
  elsif line.start_with?('<owl:equivalentProperty') then
    terms[type][term][:equivalent_property] << line.sub(/^[^"]+"/, '').sub(/".*$/, '')
    next
  elsif line.start_with?('<rdfs:seeAlso') then
    terms[type][term][:see_also] = line.sub(/^[^>]+>/, '').sub(/<.*$/, '')
    next
  end
}

puts '<p>'
puts "  Ontology namespace \"#{namespace}\": #{base}"
puts '</p>'

puts '<h4>Classes</h4>' unless terms[:class].keys.empty?

terms[:class].keys.sort.each { |term|
  puts '<p>'
  puts "  <h5 id=\"class#{term}\">Class \"#{term}\"</h5>"
  puts "  <div style=\"margin-left: #{left_margin_items}; margin-bottom: #{bottom_margin_items}\">"
  puts "  <div><i>Subclass of:</i> <a href=\"#class#{terms[:class][term][:subclassof]}\">#{terms[:class][term][:subclassof]}</a></div>" if terms[:class][term][:subclassof]
  related = []
  terms[:named_individual].keys.sort.each { |named_individual|
    related << "<a href=\"#namedIndividual#{named_individual}\">#{named_individual}</a>" if terms[:named_individual][named_individual][:type] == term
  }
  puts "  <div><i>Individuals:</i> #{related.join(', ')}</div>" unless related.empty?
  puts "  <div><i>Label:</i> #{terms[:class][term][:label]}</div>"
  puts "  <div><i>Comment:</i> #{comment(terms[:class][term][:comment], terms)}</div>" if terms[:class][term][:comment]
  puts "  <div><i>Wikipedia reference:</i> <a href=\"#{terms[:class][term][:see_also]}\">#{terms[:class][term][:see_also]}</a></div>" if terms[:class][term][:see_also]
  puts "  <div><i>Semanticscience Integrated Ontology class equivalence:</i> #{create_linkouts(:class, terms[:class][term][:equivalent_class])}</div>" unless terms[:class][term][:equivalent_class].empty?
  puts "  <div>#{terms[:class][term][:defined_by].map { |uri| origin_tag(uri) }.sort.uniq.join('')}</div>" if terms[:class][term][:defined_by]
  puts "  </div>"
  puts '</p>'
}

puts '<h4>Named Individuals (Constants, Enumerations)</h4>' unless terms[:named_individual].keys.empty?

terms[:named_individual].keys.sort.each { |term|
  puts '<p>'
  puts "  <h5 id=\"namedIndividual#{term}\">Named Individual \"#{term}\"</h5>"
  puts "  <div style=\"margin-left: #{left_margin_items}; margin-bottom: #{bottom_margin_items}\">"
  puts "  <div><i>Type:</i> <a href=\"#class#{terms[:named_individual][term][:type]}\">#{terms[:named_individual][term][:type]}</a></div>"
  puts "  <div><i>Label:</i> #{terms[:named_individual][term][:label]}</div>"
  puts "  <div><i>Comment:</i> #{comment(terms[:named_individual][term][:comment], terms)}</div>" if terms[:named_individual][term][:comment]
  puts "  <div><i>Semanticscience Integrated Ontology property equivalence:</i> #{create_linkouts(:named_individual, terms[:named_individual][term][:equivalent_property])}</div>" if terms[:named_individual][term][:equivalent_property]
  puts "  <div>#{terms[:named_individual][term][:defined_by].map { |uri| origin_tag(uri) }.sort.uniq.join('')}</div>" if terms[:named_individual][term][:defined_by]
  puts "  </div>"
  puts '</p>'
}

puts '<h4>Object Properties</h4>' unless terms[:object_property].keys.empty?

terms[:object_property].keys.sort.each { |term|
  puts '<p>'
  puts "  <h5 id=\"objectProperty#{term}\">Object Property \"#{term}\"</h5>"
  puts "  <div style=\"margin-left: #{left_margin_items}; margin-bottom: #{bottom_margin_items}\">"
  puts "  <div><i>Domain:</i> #{terms[:object_property][term][:local_domain].map { |domain| "<a href=\"#class#{domain}\">#{domain}</a>"}.join(', ') }</div>" if terms[:object_property][term][:local_domain]
  puts "  <div><i>Domain:</i> <a href=\"#{terms[:object_property][term][:external_domain]}\">#{terms[:object_property][term][:external_domain]}</a></div>" if terms[:object_property][term][:external_domain]
  puts "  <div><i>Range:</i> <a href=\"#class#{terms[:object_property][term][:local_range]}\">#{terms[:object_property][term][:local_range]}</a></div>" if terms[:object_property][term][:local_range]
  puts "  <div><i>Range:</i> <a href=\"#{terms[:object_property][term][:external_range]}\">#{terms[:object_property][term][:external_range]}</a></div>" if terms[:object_property][term][:external_range]
  puts "  <div><i>Label:</i> #{terms[:object_property][term][:label]}</div>"
  puts "  <div><i>Comment:</i> #{comment(terms[:object_property][term][:comment], terms)}</div>" if terms[:object_property][term][:comment]
  puts "  <div><i>Semanticscience Integrated Ontology property equivalence:</i> #{create_linkouts(:object_property, terms[:object_property][term][:equivalent_property])}</div>" if terms[:object_property][term][:equivalent_property]
  puts "  <div>#{terms[:object_property][term][:defined_by].map { |uri| origin_tag(uri) }.sort.uniq.join('')}</div>" if terms[:object_property][term][:defined_by]
  puts "  </div>"
  puts '</p>'
}

puts '<h4>Datatype Properties</h4>' unless terms[:datatype_property].keys.empty?

terms[:datatype_property].keys.sort.each { |term|
  puts '<p>'
  puts "  <h5 id=\"datatypeProperty#{term}\">Datatype Property \"#{term}\"</h5>"
  puts "  <div style=\"margin-left: #{left_margin_items}; margin-bottom: #{bottom_margin_items}\">"
  puts "  <div><i>Domain:</i> #{terms[:datatype_property][term][:local_domain].map { |domain| "<a href=\"#class#{domain}\">#{domain}</a>"}.join(', ') }</div>" if terms[:datatype_property][term][:local_domain]
  puts "  <div><i>Domain:</i> <a href=\"#{terms[:datatype_property][term][:external_domain]}\">#{terms[:datatype_property][term][:external_domain]}</a></div>" if terms[:datatype_property][term][:external_domain]
  puts "  <div><i>Range:</i> <a href=\"#class#{terms[:datatype_property][term][:local_range]}\">#{terms[:datatype_property][term][:local_range]}</a></div>" if terms[:datatype_property][term][:local_range]
  puts "  <div><i>Range:</i> <a href=\"#{terms[:datatype_property][term][:external_range]}\">#{terms[:datatype_property][term][:external_range]}</a></div>" if terms[:datatype_property][term][:external_range]
  puts "  <div>The data range has restrictions imposed on it. Please refer to the <a href=\"#{ontology_base}\">OWL file</a> for further details.</div>" if terms[:datatype_property][term][:has_restrictions]
  puts "  <div><i>Label:</i> #{terms[:datatype_property][term][:label]}</div>"
  puts "  <div><i>Comment:</i> #{comment(terms[:datatype_property][term][:comment], terms)}</div>" if terms[:datatype_property][term][:comment]
  puts "  <div><i>Semanticscience Integrated Ontology property equivalence:</i> #{create_linkouts(:datatype_property, terms[:datatype_property][term][:equivalent_property])}</div>" if terms[:datatype_property][term][:equivalent_property]
  puts "  <div>#{terms[:datatype_property][term][:defined_by].map { |uri| origin_tag(uri) }.sort.uniq.join('')}</div>" if terms[:datatype_property][term][:defined_by]
  puts "  </div>"
  puts '</p>'
}

