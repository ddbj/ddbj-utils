#!/usr/bin/env ruby

require 'rubygems'
#require './lib/biosample.rb'
require 'nokogiri'
require 'erb'
#require 'rdf'
#require 'rdf/ntriples'
#require 'rdf/turtle'
#require 'rdf/vocab'
#include RDF
require 'date'
require 'pp'

module DDBJ
module Utils
class BioSampleSet
  include Enumerable

  def initialize(xml, params ={})
    @xml =xml
    set_params params
    #@params = params
    #pp @params
  end

  def set_params params
      puts "### set parms #{params}"
      @outdir = params['outdir'] || './'
      @split_year = params['split-year']
      if params['begin'] or params['end']
        unless b = params['begin'] 
          b = '2004-04-04'
        end
        @date_begin = Date.parse(b)
        
        unless e = params['end']
           @date_end = Date.today 
        else
           @date_end = Date.parse(e)
        end
        puts "### Filtered by date range (#{@date_begin.to_s} .. #{@date_end.to_s})."
        #@date_range = (@date_begin..@date_end).each do |date|
        #    pp date.to_s
        #end
      else
        @no_filter = true
      end
  end

  def each
    @doc = []
    IO.foreach(@xml) do |line|
      next if line =~/\<\?xml|BioSampleSet/
      @doc.push('<?xml version="1.0" encoding="UTF-8"?>') if line =~/^\s*<BioSample/
      @doc.push(line.chomp)
      if line =~/\<\/BioSample\>/
        docs = @doc.join("\n").to_s
        yield BioSample.new(docs)
        @doc = []
      end
    end
  end

  def to_output
    @out_files = Hash.new(0)
    self.each_with_index do |biosample,i|
      o =  biosample.to_object
      #pp o
      if @no_filter or ( @date_begin .. @date_end ).cover? Date.parse(o[:publication_date])
        puts [o[:accession],o[:publication_date],o[:last_update]].join("\t")
        d = Date.parse(o[:publication_date])
        y = d.year
        basedir = @split_year ? "#{@outdir}/#{y}" : "#{@outdir}"
        out_file_name = "#{basedir}/split-biosample.xml"
        #out_file_name = @split_year ? "test-out-#{y}.xml" : "test-out.xml"
        @out_files[out_file_name] += 1
        unless FileTest.exist?(out_file_name)
            FileUtils.mkdir_p basedir 
            File.open(out_file_name, 'w+') {|f|
                f.puts '<?xml version="1.0" encoding="UTF-8"?>'
                f.puts '<BioSampleSet>'
            }
        end
        @out_files[out_file_name] += 1
        File.open(out_file_name, 'a') {|f|
          f.puts o[:xml]
        }
      end
    end
    @out_files.keys.each do |out_file_name|
        #puts out_file_name
        File.open(out_file_name, 'a') {|f|
            f.puts '</BioSampleSet>'
        }
    end
  end

  def to_tsv
    self.each_with_index do |biosample,i|
       o =  biosample.to_object
       #pp biosample.to_object
       #pp [o[:accession], o[:publication_date]]
       if @no_filter or (o[:publication_date] != "" and ( @date_begin .. @date_end ).cover? Date.parse(o[:publication_date]))
           puts [o[:accession],o[:publication_date],o[:last_update]].join("\t")
       end
       #puts biosample.to_tsv
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

  def to_object
      {
          :accession => self.accession,
          :publication_date => self.publication_date,
          :last_update => self.last_update,
          #:xml => @xml
          :xml => @biosample.to_xml
      }
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
end
end
