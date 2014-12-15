#!/usr/bin/env ruby

# Note 1: Exploits that equivalences show up first when saving with Protege 4.3.

# Note 2: Yes, this code is very simple and could be modularized and made more compact.
#         Do you think that good software design and architecture would have made an
#         acceptance to an ontology paper though? No? See: That's why this code looks
#         like it does...

classes = 0
datatype_properties = 0
object_properties = 0

has_sio_equivalent = false
classes_sio_equivalent = 0
datatype_properties_sio_equivalent = 0
object_properties_sio_equivalent = 0

has_so_equivalent = false
classes_so_equivalent = 0
datatype_properties_so_equivalent = 0
object_properties_so_equivalent = 0

joint_sio_so_classes = 0

gff3_specification_linkout = 0
gtf_specification_linkout = 0
gvf_specification_linkout = 0
vcf_specification_linkout = 0

gff3_specification_linkout_sio = 0
gtf_specification_linkout_sio = 0
gvf_specification_linkout_sio = 0
vcf_specification_linkout_sio = 0

gff3_specification_linkout_so = 0
gtf_specification_linkout_so = 0
gvf_specification_linkout_so = 0
vcf_specification_linkout_so = 0

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
    has_so_equivalent = false
    classes += 1
    within_definition = '</owl:Class>'
  end
  if line.start_with?('<owl:DatatypeProperty rdf:about="http://www.biointerchange.org/gfvo#') then
    has_sio_equivalent = false
    has_so_equivalent = false
    datatype_properties += 1
    within_definition = '</owl:DatatypeProperty>'
  end
  if line.start_with?('<owl:ObjectProperty rdf:about="http://www.biointerchange.org/gfvo#')
    has_sio_equivalent = false
    has_so_equivalent = false
    object_properties += 1
    within_definition = '</owl:ObjectProperty>'
  end

  if within_definition == '</owl:Class>' and line.start_with?('<owl:equivalentClass rdf:resource="&sio;SIO_') then
    has_sio_equivalent = true
    classes_sio_equivalent += 1
  end

  if within_definition == '</owl:Class>' and line.start_with?('<owl:equivalentClass rdf:resource="&obo;SO_') then
    has_so_equivalent = true
    classes_so_equivalent += 1
  end

  if within_definition == '</owl:Class>' and line.start_with?('<rdfs:isDefinedBy rdf:resource="http://sequenceontology.org/resources/gvf.html"') then
    gvf_specification_linkout += 1
    gvf_specification_linkout_sio += 1 if has_sio_equivalent
    gvf_specification_linkout_so += 1 if has_so_equivalent
  end
  if within_definition == '</owl:Class>' and line.start_with?('<rdfs:isDefinedBy rdf:resource="http://www.1000genomes.org/wiki/Analysis/Variant%20Call%20Format/vcf-variant-call-format-version') then
    vcf_specification_linkout += 1
    vcf_specification_linkout_sio += 1 if has_sio_equivalent
    vcf_specification_linkout_so += 1 if has_so_equivalent
  end
  if within_definition == '</owl:Class>' and line.start_with?('<rdfs:isDefinedBy rdf:resource="http://www.ensembl.org/info/website/upload/gff.html') then
    gtf_specification_linkout += 1
    gtf_specification_linkout_sio += 1 if has_sio_equivalent
    gtf_specification_linkout_so += 1 if has_so_equivalent
  end
  if within_definition == '</owl:Class>' and line.start_with?('<rdfs:isDefinedBy rdf:resource="http://sequenceontology.org/resources/gff3.html') then
    gff3_specification_linkout += 1
    gff3_specification_linkout_sio += 1 if has_sio_equivalent
    gff3_specification_linkout_so += 1 if has_so_equivalent
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

  if within_definition == '</owl:DatatypeProperty>' and line.start_with?('<owl:equivalentProperty rdf:resource="&obo;SO_') then
    has_so_equivalent = true
    datatype_properties_so_equivalent += 1
  end
  if within_definition == '</owl:ObjectProperty>' and line.start_with?('<owl:equivalentProperty rdf:resource="&obo;SO_') then
    has_so_equivalent = true
    object_properties_so_equivalent += 1
  end

  if within_definition and line.start_with?(within_definition) then
    within_definition = nil

    joint_sio_so_classes += 1 if has_sio_equivalent and has_so_equivalent
  end
}

puts "Classes                      : #{classes} (SIO equivalent: #{classes_sio_equivalent}; SO equivalent: #{classes_so_equivalent})"
puts "  from GFF3                  : #{gff3_specification_linkout} (#{gff3_specification_linkout_sio}; #{gff3_specification_linkout_so})"
puts "  from GTF                   : #{gtf_specification_linkout} (#{gtf_specification_linkout_sio}; #{gtf_specification_linkout_so})"
puts "  from GVF                   : #{gvf_specification_linkout} (#{gvf_specification_linkout_sio}; #{gvf_specification_linkout_so})"
puts "  from VCF                   : #{vcf_specification_linkout} (#{vcf_specification_linkout_sio}; #{vcf_specification_linkout_so})"
puts "Class Metadata"
puts "  Wikipedia references       : #{wikipedia_linkout}"
puts "  Pairwise disjoint axioms   : #{pairwise_disjoint_classes}"
puts "  Disjoint collection axioms : #{disjoint_class_collections}"
puts "  Property restrictions      : #{with_restrictions}"
puts "Datatype properties          : #{datatype_properties} (#{datatype_properties_sio_equivalent}; #{datatype_properties_so_equivalent})"
puts "Object properties            : #{object_properties} (#{object_properties_sio_equivalent}; #{object_properties_so_equivalent})"

puts ''
puts "SIO/SO joint class equivalences: #{joint_sio_so_classes}"
puts ''

puts "<tr><td>Classes</td><td>#{classes}</td><td>#{classes_sio_equivalent}</td><td>#{classes_so_equivalent}</td></tr>"
puts "<tr><td>&hellip;modeled from GFF3</td><td>#{gff3_specification_linkout}</td><td>#{gff3_specification_linkout_sio}</td><td>#{gff3_specification_linkout_so}</td></tr>"
puts "<tr><td>&hellip;modeled from GTF</td><td>#{gtf_specification_linkout}</td><td>#{gtf_specification_linkout_sio}</td><td>#{gtf_specification_linkout_so}</td></tr>"
puts "<tr><td>&hellip;modeled from GVF</td><td>#{gvf_specification_linkout}</td><td>#{gvf_specification_linkout_sio}</td><td>#{gvf_specification_linkout_so}</td></tr>"
puts "<tr><td>&hellip;modeled from VCF</td><td>#{vcf_specification_linkout}</td><td>#{vcf_specification_linkout_sio}</td><td>#{vcf_specification_linkout_so}</td></tr>"
puts "<tr><td>Class Metadata</td><td></td><td></td><td></td></tr>"
puts "<tr><td>&hellip;Wikipedia references</td><td>#{wikipedia_linkout}</td><td>n/a</td><td>n/a</td></tr>"
puts "<tr><td>&hellip;pairwise disjoint axioms</td><td>#{pairwise_disjoint_classes}</td><td>n/a</td><td>n/a</td></tr>"
puts "<tr><td>&hellip;disjoint collection axioms</td><td>#{disjoint_class_collections}</td><td>n/a</td><td>n/a</td></tr>"
puts "<tr><td>&hellip;with property restrictions</td><td>#{with_restrictions}</td><td>n/a</td><td>n/a</td></tr>"
puts "<tr><td>Datatype properties</td><td>#{datatype_properties}</td><td>#{datatype_properties_sio_equivalent}</td><td>#{datatype_properties_so_equivalent}</td></tr>"
puts "<tr><td>Object properties</td><td>#{object_properties}</td><td>#{object_properties_sio_equivalent}</td><td>#{object_properties_so_equivalent}</td></tr>"

