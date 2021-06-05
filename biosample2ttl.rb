#!/usr/bin/env ruby

require 'nokogiri'
require 'erb'
#require 'uri'
#require 'pp'

class BioSampleSet
  include Enumerable

  def initialize(xml)
    @xml =xml
  end

  def each
    @doc = []
    IO.foreach(@xml) do |line|
      next if line =~/\<\?xml|BioSampleSet/
      @doc.push('<?xml version="1.0" encoding="UTF-8"?>') if line =~/^\s*<BioSample/
      @doc.push(line.chomp)
#puts line
      if line =~/\<\/BioSample\>/
        docs = @doc.join("\n").to_s
        yield BioSample.new(docs)
        @doc = []
      end
    end
  end

  def to_tsv
    self.each_with_index do |biosample,i|
       puts biosample.to_tsv
    end
  end

  def to_ttl
    self.each_with_index do |biosample,i|
      if i == 0
        puts biosample.to_ttl_prefix
      end
      puts biosample.to_ttl
    end
  end
end

class BioSample

  def initialize(xml)
    @biosample = Nokogiri::XML(xml).css("BioSample")
    raise NameError, "biosample element not found" unless @biosample

    doc = Nokogiri::XML(xml)
    biosample = doc.xpath("/BioSample")

    if @biosample.attribute("id").nil?
      @ddbj = true
    else
      @ddbj = false
    end
  end

  def id
    if @ddbj
      nil
    else
      @biosample.attribute("id").value
    end
    # @biosample.attribute("id").nil? ?
    #         '' : @biosample.attribute("id").value
  end

  def accession
    if @ddbj
      @biosample.at_css('Ids > Id[namespace="BioSample"]').inner_text
    else
      #@biosample.attribute("accession").value
      if @biosample.at_css('Ids > Id[db="BioSample"]').nil?
        nil
      else
        @biosample.at_css('Ids > Id[db="BioSample"]').inner_text
      end
    end
  end

  def access
    @biosample.attribute("access").value
  end

  def publication_date
    if  @biosample.attribute("publication_date").nil?
      ''
    else
      @biosample.attribute("publication_date").value
    end
  end

  def last_update
    @biosample.attribute("last_update").value
  end

  def title
    if @ddbj 
      @biosample.css('Description > SampleName' ).inner_text
    else
      @biosample.css('Description > Title' ).inner_text
    end
  end

  def comment
    if @ddbj
      @biosample.css('Description > Title' ).inner_text
    else
      #exception: SAMN00000186
      if @biosample.at_css('Description > Comment > Paragraph' ).nil?
        ''
      else
        @biosample.at_css('Description > Comment > Paragraph' ).inner_text
      end
    end
  end 

  def organism
    if @ddbj 
      @biosample.css('Organism > OrganismName').inner_text
    else
      @biosample.css('Description > Organism').attribute('taxonomy_name').value
    end
  end

  def taxid
    @biosample.css('Description > Organism').attribute('taxonomy_id').value
  end

  def model
    @biosample.css('Models > Model').inner_text
  end

  def owner
    @biosample.css('Owner > Name').inner_text
  end

  def to_tsv
     [self.accession, self.publication_date, self.last_update ].join("\t")
  end

  def to_ttl
    erb = accession ? self.template : self.template_blank
    puts erb.result(binding)
  end

  def template
    tpl = <<EOF
<http://identifiers.org/biosample/<%= self.accession %>>
  rdf:type insdc:BioSample ;
  rdfs:label "<%= self.title %>" ;
  rdfs:comment "<%= self.comment -%>" ;
  insdc:organism "<%= self.organism -%>" ;
  obo:RO_0002162 <http:identifiers.org/taxonomy/<%= self.taxid -%>> ; #RO:in taxon
  owl:sameAs <http://trace.ddbj.nig.ac.jp/BSSearch/biosample?acc=<%= self.accession %>> ;
  owl:sameAs <http://www.ebi.ac.uk/ena/data/view/<%= self.accession %>> ;
  owl:sameAs <http://www.ncbi.nlm.nih.gov/biosample?term=<%= self.accession %>> ;
  biosample:model "<%= self.model %>" ;
  biosample:owner "<%= self.owner %>" ;
<% self.sample_attributes.each do |attribute| -%>
  biosample:<%= attribute[:name] %> "<%= attribute[:value] %>" ;
<% end -%>
<% self.sample_ids.each do |id| -%>
  biosample:dblink "<%= id[:name] %>:<%= id[:value] %>" ;
<% end -%>
<% self.sample_links.each do |link| -%>
  biosample:db_xref "<%= link[:name] %>:<%= link[:value] %>" ;
<% end -%>
  biosample:access "<%= self.access %>" ;
  biosample:publication_date "<%= self.publication_date %>" ;
  biosample:last_update "<%= self.last_update %>" .
EOF
  ERB.new(tpl, nil, '-')
  end

  def template_blank
                tpl = <<EOF
[
  rdf:type insdc:BioSample ;
  rdfs:label "<%= self.title %>" ;
  rdfs:comment "<%= self.comment -%>" ;
  insdc:organism "<%= self.organism -%>" ;
  obo:RO_0002162 <http:identifiers.org/taxonomy/<%= self.taxid -%>> ; #RO:in taxon
  biosample:access "<%= self.access %>" ;
  biosample:publication_date "<%= self.publication_date %>" ;
  biosample:last_update "<%= self.last_update %>" ;
  biosample:model "<%= self.model %>" ;
  biosample:owner "<%= self.owner %>" ;
<% self.sample_attributes.each do |attribute| -%>
  biosample:<%= attribute[:name] %> "<%= attribute[:value] %>" ;
<% end -%>
<% self.sample_ids.each do |id| -%>
  biosample:dblink "<%= id[:name] %>:<%= id[:value] %>" ;
<% end -%>
<% self.sample_links.each do |link| -%>
  biosample:db_xref "<%= link[:name] %>:<%= link[:value] %>" ;
<% end -%>
  biosample:access "<%= self.access %>" ;
  biosample:publication_date "<%= self.publication_date %>" ;
  biosample:last_update "<%= self.last_update %>" ;
]
.
EOF
  ERB.new(tpl, nil, '-')
        end



  def sample_attributes
    #      doc.xpath("/BioSample/Attributes/Attribute").each do |element|
    #         children = element.children.to_s
    #         attribute_name = element.attribute("attribute_name").value
    #         harmonized_name = element.attribute("harmonized_name").nil? ?
    #              '' : element.attribute("harmonized_name").value
    #         display_name = element.attribute('display_name').nil? ?
    #              '' : element.attribute("display_name").value
    #         #puts [accession,id,attribute_name,harmonized_name,display_name,children].join("\t")
    #         puts "biosample:attributes##{URI.escape(attribute_name)}>\t\"#{children.gsub('"','\\"')}\" ;"
    #      end
    @biosample.css('Attributes > Attribute').map do |node|
                        {
      name: self.uri_escaped(node.attribute('attribute_name').value),
      value:  self.ttl_escaped(node.inner_text.to_s)
      }
    end
  end

  def sample_ids
    ids = @biosample.css('Ids > Id').map do |node|
      children = node.inner_text.to_s
      if @ddbj
                                {
        name: self.uri_escaped(node.attribute("namespace").value),
        value: self.ttl_escaped(node.inner_text.to_s)
        }
      else
        db = node.attribute("db").nil? ? node.attribute("db_label").value : node.attribute("db").value 
        {
        name: self.uri_escaped(db),
        value: self.ttl_escaped(node.inner_text.to_s)
        }
      end
    end
    #      doc.xpath("/BioSample/Ids/Id").each do |element|
    #         children = element.children.to_s
    #         #attribute_name = element.attribute("namespace").value #DDBJ
    #         attribute_name = element.attribute("namespace") ? attribute_name = element.attribute("namespace").value : attribute_name = element.attribute("db").value
    #         puts "\tdcterms:identifier\t\"#{URI.escape(attribute_name)}:#{children}\" ;"
    #      end
  end

  def sample_links
    #      #doc.xpath('/BioSample/Links/Link').each do |element| # DDBJ
    #      doc.xpath('/BioSample/Links/Link[@type="url"]').each do |element| #NCBI
    #         children = element.children.to_s
    #         attribute_name = element.attribute("label").value #DDBJ
    #         #puts "\t<http://ddbj.nig.ac.jp/ontologies/biosample/link##{URI.escape(attribute_name)}>\t\"#{children}\" ;"
    #         puts "\tdcterms:identifier\t\"#{URI.escape(attribute_name)}:#{children}\" ;"
    #      end
    if @ddbj
      @biosample.css('Links > Link').map do |node|
        {
        name: self.uri_escaped(node.attribute("label").value),
        value: self.ttl_escaped(node.inner_text.to_s)
        }
      end
    else
      @biosample.css('Links > Link[type="url"]').map do |node|
        label = node.attribute("label").nil? ? node.attribute("target").value : node.attribute("label").value
        {
        name: self.uri_escaped(label),
        value: self.ttl_escaped(node.inner_text.to_s)
        }
      end
    end
  end 

        def uri_escaped(string)
            require 'uri'
            URI.encode_www_form_component(string)
        end
        # seeAlso: http://rdf.greggkellogg.net/yard/RDF/Writer.html#escaped-instance_method
  def ttl_escaped(string)
    string.gsub('\\', '\\\\\\\\').
    gsub("\b", '\\b').
    gsub("\f", '\\f').
    gsub("\t", '\\t').
    gsub("\n", '\\n').
    gsub("\r", '\\r').
    gsub('"', '\\"')
  end

  # TODO
  def related_link
    @study.css("RELATED_LINK").map do |node|
      { db: node.css("DB").inner_text,
        id: node.css("ID").inner_text,
      label: node.css("LABEL").inner_text }
    end
  end
    def to_ttl_prefix
    <<HEADER
@prefix : <http://identifiers.org/dataset/> .
@prefix owl:  <http://www.w3.org/2002/07/owl#>.
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix skos: <http://www.w3.org/2004/02/skos/core#> .
@prefix void: <http://rdfs.org/ns/void#> .
@prefix dcterms: <http://purl.org/dc/terms/> .
@prefix obo:  <http://purl.obolibrary.org/obo/> .
@prefix insdc: <http://ddbj.nig.ac.jp/ontologies/nucleotide/> . 
@prefix biosample: <http://ddbj.nig.ac.jp/biosample/> . 
@prefix dcterms: <http://purl.org/dc/terms/>.

HEADER
    end
end

xml =  ARGV[0] || 'biosample_ddbj.xml'
bss = BioSampleSet.new(xml)
#bss.to_ttl
bss.to_tsv
