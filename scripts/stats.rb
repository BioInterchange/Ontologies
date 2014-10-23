#!/usr/bin/env ruby

# Note: exploits that equivalences show up first when saving with Protege 4.3.

classes = 0
datatype_properties = 0
object_properties = 0

has_sio_equivalent = false
classes_sio_equivalent = 0
datatype_properties_sio_equivalent = 0
object_properties_sio_equivalent = 0

gff3_specification_linkout = 0
gtf_specification_linkout = 0
gvf_specification_linkout = 0
vcf_specification_linkout = 0

gff3_specification_linkout_sio = 0
gtf_specification_linkout_sio = 0
gvf_specification_linkout_sio = 0
vcf_specification_linkout_sio = 0

wikipedia_linkout = 0

pairwise_disjoint_classes = 0
disjoint_class_collections = 0
with_restrictions = 0

within_definition = nil

STDIN.each { |line|
  line.chomp!
  line.strip!

  if line.include?('owl:disjointWith') then
    pairwise_disjoint_classes += 1
  elsif line.include?('&owl;AllDisjointClasses') then
    disjoint_class_collections += 1
  elsif line.include?('owl:withRestriction') then
    with_restrictions += 1
  end

  if line.start_with?('<owl:Class rdf:about="http://www.biointerchange.org/gfvo#') then
    has_sio_equivalent = false
    classes += 1
    within_definition = '</owl:Class>'
  end
  if line.start_with?('<owl:DatatypeProperty rdf:about="http://www.biointerchange.org/gfvo#') then
    has_sio_equivalent = false
    datatype_properties += 1
    within_definition = '</owl:DatatypeProperty>'
  end
  if line.start_with?('<owl:ObjectProperty rdf:about="http://www.biointerchange.org/gfvo#')
    has_sio_equivalent = false
    object_properties += 1
    within_definition = '</owl:ObjectProperty>'
  end

  if within_definition == '</owl:Class>' and line.start_with?('<owl:equivalentClass rdf:resource="&sio;SIO_') then
    has_sio_equivalent = true
    classes_sio_equivalent += 1
  end

  if within_definition == '</owl:Class>' and line.start_with?('<rdfs:isDefinedBy rdf:resource="http://sequenceontology.org/resources/gvf.html"') then
    gvf_specification_linkout += 1
    gvf_specification_linkout_sio += 1 if has_sio_equivalent
  end
  if within_definition == '</owl:Class>' and line.start_with?('<rdfs:isDefinedBy rdf:resource="http://www.1000genomes.org/wiki/Analysis/Variant%20Call%20Format/vcf-variant-call-format-version') then
    vcf_specification_linkout += 1
    vcf_specification_linkout_sio += 1 if has_sio_equivalent
  end
  if within_definition == '</owl:Class>' and line.start_with?('<rdfs:isDefinedBy rdf:resource="http://www.ensembl.org/info/website/upload/gff.html') then
    gtf_specification_linkout += 1
    gtf_specification_linkout_sio += 1 if has_sio_equivalent
  end
  if within_definition == '</owl:Class>' and line.start_with?('<rdfs:isDefinedBy rdf:resource="http://sequenceontology.org/resources/gff3.html') then
    gff3_specification_linkout += 1
    gff3_specification_linkout_sio += 1 if has_sio_equivalent
  end

  if within_definition == '</owl:Class>' and line.start_with?('<rdfs:seeAlso>http://en.wikipedia.org/wiki') then
    wikipedia_linkout += 1
  end

  if within_definition == '</owl:DatatypeProperty>' and line.start_with?('<owl:equivalentProperty rdf:resource="&sio;SIO_') then
    has_sio_equivalent = true
    datatype_properties_sio_equivalent += 1
  end
  if within_definition == '</owl:ObjectProperty>' and line.start_with?('<owl:equivalentProperty rdf:resource="&sio;SIO_') then
    has_sio_equivalent = true
    object_properties_sio_equivalent += 1
  end

  if within_definition and line.start_with?(within_definition) then
    within_definition = nil
  end
}

puts "Classes                      : #{classes} (SIO equivalent: #{classes_sio_equivalent})"
puts "  from GFF3                  : #{gff3_specification_linkout} (#{gff3_specification_linkout_sio})"
puts "  from GTF                   : #{gtf_specification_linkout} (#{gtf_specification_linkout_sio})"
puts "  from GVF                   : #{gvf_specification_linkout} (#{gvf_specification_linkout_sio})"
puts "  from VCF                   : #{vcf_specification_linkout} (#{vcf_specification_linkout_sio})"
puts "Class Metadata"
puts "  Wikipedia references       : #{wikipedia_linkout}"
puts "  Pairwise disjoint axioms   : #{pairwise_disjoint_classes}"
puts "  Disjoint collection axioms : #{disjoint_class_collections}"
puts "  Property restrictions      : #{with_restrictions}"
puts "Datatype properties          : #{datatype_properties} (#{datatype_properties_sio_equivalent})"
puts "Object properties            : #{object_properties} (#{object_properties_sio_equivalent})"

puts ''

puts "<tr><td>Classes</td><td>#{classes}</td><td>#{classes_sio_equivalent}</td></tr>"
puts "<tr><td>&hellip;modeled from GFF3</td><td>#{gff3_specification_linkout}</td><td>#{gff3_specification_linkout_sio}</td></tr>"
puts "<tr><td>&hellip;modeled from GTF</td><td>#{gtf_specification_linkout}</td><td>#{gtf_specification_linkout_sio}</td></tr>"
puts "<tr><td>&hellip;modeled from GVF</td><td>#{gvf_specification_linkout}</td><td>#{gvf_specification_linkout_sio}</td></tr>"
puts "<tr><td>&hellip;modeled from VCF</td><td>#{vcf_specification_linkout}</td><td>#{vcf_specification_linkout_sio}</td></tr>"
puts "<tr><td>Class Metadata</td><td></td><td></td></tr>"
puts "<tr><td>&hellip;Wikipedia references</td><td>#{wikipedia_linkout}</td><td></td></tr>"
puts "<tr><td>&hellip;pairwise disjoint axioms</td><td>#{pairwise_disjoint_classes}</td><td></td></tr>"
puts "<tr><td>&hellip;disjoint collection axioms</td><td>#{disjoint_class_collections}</td><td></td></tr>"
puts "<tr><td>&hellip;with property restrictions</td><td>#{with_restrictions}</td><td></td></tr>"
puts "<tr><td>Datatype properties</td><td>#{datatype_properties}</td><td>#{datatype_properties_sio_equivalent}</td></tr>"
puts "<tr><td>Object properties</td><td>#{object_properties}</td><td>#{object_properties_sio_equivalent}</td></tr>"

