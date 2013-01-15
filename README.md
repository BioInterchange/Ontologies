# BioInterchange Ontologies

Bioinformatics related ontologies. Especially for generating RDF content using BioInterchange.

### GFF3O

An ontology for describing [GFF3](http://sequenceontology.org/gff3.shtml) file contents.

*  https://raw.github.com/BioInterchange/Ontologies/master/gff3o.xml

### Genome Variation Format Version 1 Ontology (GVF1O)

An ontology for describing [GVF](http://sequenceontology.org/gvf.shtml) file contents.

*  https://raw.github.com/BioInterchange/Ontologies/master/gvf1o.xml

## Build Instructions

Build instructions are intended for collaborators and enthusiasts who would like contributing
to the BioInterchange ontologies. The ontologies can be edited using [Protege](http://protege.stanford.edu),
but a few post-processing steps are necessary to remove additional information that Protege
inserts on its own.

### Post-Protege-Cleanup

Saving an ontology with Protege will introduce explicit class definitions and individuals for external URIs.
These have to be removed, so that only BioInterchange URIs are described by the ontologies. A script has been
provided that takes care of this, and additionally, increments the patch level version number of the
ontologies.

For example, for GFF3O the following commands can be used to create a new cleaned version of the ontology:

    <gff3o.xml scripts/cleanse.rb > gff3o.tmp
    mv gff3o.tmp gff3o.xml

### Generating new GO Abbreviation Collection Link-Outs

The URIs linking out to the [Gene Ontology Abbreviation Collection](http://www.geneontology.org/doc/GO.xrf_abbs)
can be automatically generated from the BioInterchange project's corresponding vocabulary
wrapper class:

    git clone git://github.com/BioInterchange/BioInterchange.git
    cd BioInterchange
    grep 'RDF::URI.new' lib/biointerchange/goxref.rb | grep -o -E 'http:[^"]+' | awk '{ print "                    <owl:Class rdf:about=\"&go"NR";\"/>" }'

On Mac OS X, the generated list of entities can be copied into the clipboard for subsequent
pasting using the `pbcopy` command:

    grep 'RDF::URI.new' lib/biointerchange/goxref.rb | grep -o -E 'http:[^"]+' | awk '{ print "                    <owl:Class rdf:about=\"&go"NR";\"/>" }' | pbcopy

