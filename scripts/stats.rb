#!/usr/bin/env ruby

classes = 0
datatype_properties = 0
object_properties = 0

classes_sio_equivalent = 0
datatype_properties_sio_equivalent = 0
object_properties_sio_equivalent = 0

gff3_specification_linkout = 0
gtf_specification_linkout = 0
gvf_specification_linkout = 0
vcf_specification_linkout = 0

wikipedia_linkout = 0

within_definition = nil

STDIN.each { |line|
  line.chomp!
  line.strip!

  if line.start_with?('<owl:Class rdf:about="http://www.biointerchange.org/gfvo#') then
    classes += 1
    within_definition = '</owl:Class>'
  end
  if line.start_with?('<owl:DatatypeProperty rdf:about="http://www.biointerchange.org/gfvo#') then
    datatype_properties += 1
    within_definition = '</owl:DatatypeProperty>'
  end
  if line.start_with?('<owl:ObjectProperty rdf:about="http://www.biointerchange.org/gfvo#')
    object_properties += 1
    within_definition = '</owl:ObjectProperty>'
  end

  if within_definition == '</owl:Class>' and line.start_with?('<owl:equivalentClass rdf:resource="&sio;SIO_') then
    classes_sio_equivalent += 1
  end

  if within_definition == '</owl:Class>' and line.start_with?('<rdfs:isDefinedBy rdf:resource="http://sequenceontology.org/resources/gvf.html"') then
    gvf_specification_linkout += 1
  end
  if within_definition == '</owl:Class>' and line.start_with?('<rdfs:isDefinedBy rdf:resource="http://www.1000genomes.org/wiki/Analysis/Variant%20Call%20Format/vcf-variant-call-format-version') then
    vcf_specification_linkout += 1
  end
  if within_definition == '</owl:Class>' and line.start_with?('<rdfs:isDefinedBy rdf:resource="http://www.ensembl.org/info/website/upload/gff.html') then
    gtf_specification_linkout += 1
  end
  if within_definition == '</owl:Class>' and line.start_with?('<rdfs:isDefinedBy rdf:resource="http://sequenceontology.org/resources/gff3.html') then
    gff3_specification_linkout += 1
  end

  if within_definition == '</owl:Class>' and line.start_with?('<rdfs:seeAlso>http://en.wikipedia.org/wiki') then
    wikipedia_linkout += 1
  end

  if within_definition == '</owl:DatatypeProperty>' and line.start_with?('<owl:equivalentProperty rdf:resource="&sio;SIO_') then
    datatype_properties_sio_equivalent += 1
  end
  if within_definition == '</owl:ObjectProperty>' and line.start_with?('<owl:equivalentProperty rdf:resource="&sio;SIO_') then
    object_properties_sio_equivalent += 1
  end

  if within_definition and line.start_with?(within_definition) then
    within_definition = nil
  end
}

puts "Classes              : #{classes} (SIO equivalent: #{classes_sio_equivalent})"
puts "  from GFF3          : #{gff3_specification_linkout}"
puts "  from GTF           : #{gtf_specification_linkout}"
puts "  from GVF           : #{gvf_specification_linkout}"
puts "  from VCF           : #{vcf_specification_linkout}"
puts "  Wikipedia reference: #{wikipedia_linkout}"
puts "Datatype properties  : #{datatype_properties} (SIO equivalent: #{datatype_properties_sio_equivalent})"
puts "Object properties    : #{object_properties} (SIO equivalent: #{object_properties_sio_equivalent})"

puts ''

puts "<tr><td>Classes:</td><td>#{classes}</td><td>#{classes_sio_equivalent}</td></tr>"
puts "<tr><td>from GFF3:</td><td>#{gff3_specification_linkout}</td><td></td></tr>"
puts "<tr><td>from GTF:</td><td>#{gtf_specification_linkout}</td><td></td></tr>"
puts "<tr><td>from GVF:</td><td>#{gvf_specification_linkout}</td><td></td></tr>"
puts "<tr><td>from VCF:</td><td>#{vcf_specification_linkout}</td><td></td></tr>"
puts "<tr><td>Wikipedia reference:</td><td>#{wikipedia_linkout}</td><td></td></tr>"
puts "<tr><td>Datatype properties:</td><td>#{datatype_properties}</td><td>#{datatype_properties_sio_equivalent}</td></tr>"
puts "<tr><td>Object properties:</td><td>#{object_properties}</td><td>#{object_properties_sio_equivalent}</td></tr>"

