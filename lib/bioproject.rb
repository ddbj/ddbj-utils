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
class BioProjectSet
  include Enumerable

  def initialize(xml, params ={})
    @xml =xml
    set_params params
    #@params = params
    #pp @params
  end

  def set_params params
      warn "### set parms #{params}"
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
      next if line =~/\<\?xml|PackageSet/
      @doc.push('<?xml version="1.0" encoding="UTF-8"?>') if line =~/^\s*<Package/
      @doc.push(line.chomp)
      if line =~/\<\/Package\>/
        docs = @doc.join("\n").to_s
        yield BioProject.new(docs)
        @doc = []
      end
    end
  end

  def to_output
    @out_files = Hash.new(0)
    self.each_with_index do |bioproject,i|
      #pp bioproject
      o = bioproject.to_object
      #pp o[:accession]
      #pp o[:publication_date]
      #pp o[:last_update]
      #if @no_filter or ( @date_begin .. @date_end ).cover? Date.parse(o[:publication_date])
      #if @no_filter or (o[:publication_date] != "" and ( @date_begin .. @date_end ).cover? Date.parse(o[:publication_date]))
      if @no_filter or (o[:submitted_date] != "" and ( @date_begin .. @date_end ).cover? Date.parse(o[:submitted_date]))
        #`puts [o[:accession],o[:publication_date],o[:last_update]].join("\t")
        d = Date.parse(o[:submitted_date])
        y = d.year
        basedir = @split_year ? "#{@outdir}/#{y}" : "#{@outdir}"
        out_file_name = "#{basedir}/split-bioproject.xml"
        #out_file_name = @split_year ? "test-out-#{y}.xml" : "test-out.xml"
        @out_files[out_file_name] += 1
        unless FileTest.exist?(out_file_name)
            FileUtils.mkdir_p basedir 
            File.open(out_file_name, 'w+') {|f|
                f.puts '<?xml version="1.0" encoding="UTF-8"?>'
                f.puts '<PackageSet>'
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
            f.puts '</PackageSet>'
        }
    end
  end

  def to_tsv
    puts ["#accession","dateCreated", "dateModified", "datePublished"].join("\t")
    self.each_with_index do |bioproject,i|
       o =  bioproject.to_object
       #pp bioproject.to_object
       #pp [o[:accession], o[:publication_date]]
       if @no_filter or (o[:submitted_date] != "" and ( @date_begin .. @date_end ).cover? Date.parse(o[:submitted_date]))
       #if @no_filter or (o[:publication_date] != "" and ( @date_begin .. @date_end ).cover? Date.parse(o[:publication_date]))
           puts [o[:accession],o[:submitted_date],o[:last_update], o[:publication_date] ].join("\t")
       end
       #puts bioproject.to_tsv
    end
  end

  def to_ttl
    self.each_with_index do |bioproject,i|
      if i == 0
        puts bioproject.to_ttl_prefix
      end
      puts bioproject.to_ttl
    end
  end
end

class BioProject

  def initialize(xml)

    #@bioproject = Nokogiri::XML(xml).css("Package")
    @bioproject = Nokogiri::XML(xml).css("Package")
    #puts @bioproject
    #exit
    raise NameError, "bioproject element not found" unless @bioproject

    #doc = Nokogiri::XML(xml)
    #bioproject = doc.xpath("/Project")
    #@ddbj = @bioproject.attribute("id").nil? ? true : false
    @ddbj = false
    #if @bioproject.attribute("id").nil?
    #  @ddbj = true
    #else
    #  @ddbj = false
    #end
    #get_release_date
  end

  def id
    if @ddbj
      nil
    else
      @bioproject.attribute("id").value
    end
    # @bioproject.attribute("id").nil? ?
    #         '' : @bioproject.attribute("id").value
  end

  def accession
    #pp @bioproject.at_css('Project > Project > ProjectID > ArchiveId[namespace="BioProject"]')
    #puts @bioproject
    #puts @bioproject.at_css('ArchiveID').attribute('accession').value
    @accession = @bioproject.at_css('ArchiveID').attribute('accession').value
    #pp @bioproject.at_css('Project > Project > ProjectID > ArchiveId')
    #@bioproject.at_css('Project > Project > ProjectID > ArchiveId[namespace="BioProject"]').inner_text
    #if @ddbj
    #  @bioproject.at_css('Project > Project > ProjectID > ArchiveId[namespace="BioProject"]').inner_text
    #else
    #  #@bioproject.attribute("accession").value
    #  if @bioproject.at_css('Ids > Id[db="BioProject"]').nil?
    #    nil
    #  else
    #    @bioproject.at_css('Ids > Id[db="BioProject"]').inner_text
    #  end
    #end
  end

  def access
    @bioproject.attribute("access").value
  end

  def submitted_date
      #<Submission submitted="2003-02-23">
      #puts @bioproject.xpath('//Submission/@submitted').to_s
      @bioproject.xpath('//Submission/@submitted').to_s
  end

  def publication_date
    #puts @bioproject
    #puts @bioproject.xpath('//Publication/@date') 
    @release_date = @bioproject.xpath('//Publication/@date').to_s
    #@bioproject.css('Publication').attribute('date').value 
    #exit
    #if  @bioproject.attribute("publication_date").nil?
    #  ''
    #else
    #  @bioproject.attribute("publication_date").value
    #end
  end

  def release_date
      @bioproject.xpath('//ProjectReleaseDate').inner_text
  end

  def get_release_date
      @release_date = "9999-12-31T00:00:00Z"
      date = @bioproject.xpath('//ProjectReleaseDate')
      if date.any?
        @release_date = date.inner_text
      end
      #if date = @bioproject.xpath('//Publication/@date')
      #   puts date
      #end
      #  @release_date = date.to_s
      #end
      #pp "release_date:#{@release_date}"
      @release_date
  end
      #ProjectReleaseDate

  def last_update
    @bioproject.xpath('//Submission/@last_update').to_s
  end

  def title
    if @ddbj 
      @bioproject.css('Description > ProjectName' ).inner_text
    else
      @bioproject.css('Description > Title' ).inner_text
    end
  end

  def comment
    if @ddbj
      @bioproject.css('Description > Title' ).inner_text
    else
      #exception: SAMN00000186
      if @bioproject.at_css('Description > Comment > Paragraph' ).nil?
        ''
      else
        @bioproject.at_css('Description > Comment > Paragraph' ).inner_text
      end
    end
  end 

  def organism
    if @ddbj 
      @bioproject.css('Organism > OrganismName').inner_text
    else
      @bioproject.css('Description > Organism').attribute('taxonomy_name').value
    end
  end

  def taxid
    @bioproject.css('Description > Organism').attribute('taxonomy_id').value
  end

  def model
    @bioproject.css('Models > Model').inner_text
  end

  def owner
    @bioproject.css('Owner > Name').inner_text
  end

  def to_object
      {
          :accession => self.accession,
          :publication_date => self.release_date , ## self.publication_date
          :submitted_date => self.submitted_date,
          :last_update => self.last_update ,
          :xml => @bioproject.to_xml
      }
  end
  def to_tsv
     [self.accession, self.submitted_date, self.last_update, self.release_date ].join("\t")
  end

  def to_ttl
    erb = accession ? self.template : self.template_blank
    puts erb.result(binding)
  end

  def template
    tpl = <<EOF
<http://identifiers.org/bioproject/<%= self.accession %>>
  rdf:type insdc:BioProject ;
  rdfs:label "<%= self.title %>" ;
  rdfs:comment "<%= self.comment -%>" ;
  insdc:organism "<%= self.organism -%>" ;
  obo:RO_0002162 <http:identifiers.org/taxonomy/<%= self.taxid -%>> ; #RO:in taxon
  owl:sameAs <http://trace.ddbj.nig.ac.jp/BSSearch/bioproject?acc=<%= self.accession %>> ;
  owl:sameAs <http://www.ebi.ac.uk/ena/data/view/<%= self.accession %>> ;
  owl:sameAs <http://www.ncbi.nlm.nih.gov/bioproject?term=<%= self.accession %>> ;
  bioproject:model "<%= self.model %>" ;
  bioprojecte:owner "<%= self.owner %>" ;
<% self.project_attributes.each do |attribute| -%>
  bioproject:<%= attribute[:name] %> "<%= attribute[:value] %>" ;
<% end -%>
<% self.project_ids.each do |id| -%>
  bioproject:dblink "<%= id[:name] %>:<%= id[:value] %>" ;
<% end -%>
<% self.project_links.each do |link| -%>
  bioproject:db_xref "<%= link[:name] %>:<%= link[:value] %>" ;
<% end -%>
  bioproject:access "<%= self.access %>" ;
  bioproject:publication_date "<%= self.publication_date %>" ;
  bioproject:last_update "<%= self.last_update %>" .
EOF
  ERB.new(tpl, nil, '-')
  end

  def template_blank
                tpl = <<EOF
[
  rdf:type insdc:BioProject ;
  rdfs:label "<%= self.title %>" ;
  rdfs:comment "<%= self.comment -%>" ;
  insdc:organism "<%= self.organism -%>" ;
  obo:RO_0002162 <http:identifiers.org/taxonomy/<%= self.taxid -%>> ; #RO:in taxon
  bioproject:access "<%= self.access %>" ;
  bioproject:publication_date "<%= self.publication_date %>" ;
  bioproject:last_update "<%= self.last_update %>" ;
  bioproject:model "<%= self.model %>" ;
  bioproject:owner "<%= self.owner %>" ;
<% self.project_attributes.each do |attribute| -%>
  bioproject:<%= attribute[:name] %> "<%= attribute[:value] %>" ;
<% end -%>
<% self.project_ids.each do |id| -%>
  bioproject:dblink "<%= id[:name] %>:<%= id[:value] %>" ;
<% end -%>
<% self.project_links.each do |link| -%>
  bioproject:db_xref "<%= link[:name] %>:<%= link[:value] %>" ;
<% end -%>
  bioproject:access "<%= self.access %>" ;
  bioproject:publication_date "<%= self.publication_date %>" ;
  bioproject:last_update "<%= self.last_update %>" ;
]
.
EOF
  ERB.new(tpl, nil, '-')
        end



  def project_attributes
    #      doc.xpath("/BioProject/Attributes/Attribute").each do |element|
    #         children = element.children.to_s
    #         attribute_name = element.attribute("attribute_name").value
    #         harmonized_name = element.attribute("harmonized_name").nil? ?
    #              '' : element.attribute("harmonized_name").value
    #         display_name = element.attribute('display_name').nil? ?
    #              '' : element.attribute("display_name").value
    #         #puts [accession,id,attribute_name,harmonized_name,display_name,children].join("\t")
    #         puts "bioproject:attributes##{URI.escape(attribute_name)}>\t\"#{children.gsub('"','\\"')}\" ;"
    #      end
    @bioproject.css('Attributes > Attribute').map do |node|
                        {
      name: self.uri_escaped(node.attribute('attribute_name').value),
      value:  self.ttl_escaped(node.inner_text.to_s)
      }
    end
  end

  def project_ids
    ids = @bioproject.css('Ids > Id').map do |node|
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
    #      doc.xpath("/BioProject/Ids/Id").each do |element|
    #         children = element.children.to_s
    #         #attribute_name = element.attribute("namespace").value #DDBJ
    #         attribute_name = element.attribute("namespace") ? attribute_name = element.attribute("namespace").value : attribute_name = element.attribute("db").value
    #         puts "\tdcterms:identifier\t\"#{URI.escape(attribute_name)}:#{children}\" ;"
    #      end
  end

  def project_links
    #      #doc.xpath('/BioProject/Links/Link').each do |element| # DDBJ
    #      doc.xpath('/BioProject/Links/Link[@type="url"]').each do |element| #NCBI
    #         children = element.children.to_s
    #         attribute_name = element.attribute("label").value #DDBJ
    #         #puts "\t<http://ddbj.nig.ac.jp/ontologies/bioproject/link##{URI.escape(attribute_name)}>\t\"#{children}\" ;"
    #         puts "\tdcterms:identifier\t\"#{URI.escape(attribute_name)}:#{children}\" ;"
    #      end
    if @ddbj
      @bioproject.css('Links > Link').map do |node|
        {
        name: self.uri_escaped(node.attribute("label").value),
        value: self.ttl_escaped(node.inner_text.to_s)
        }
      end
    else
      @bioproject.css('Links > Link[type="url"]').map do |node|
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
@prefix bioproject: <http://ddbj.nig.ac.jp/bioproject/> . 
@prefix dcterms: <http://purl.org/dc/terms/>.

HEADER
    end
end
end
end
