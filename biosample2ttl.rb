#!/usr/bin/env ruby
require 'rubygems'
#require 'rdf'
#require 'rdf/ntriples'
#require 'rdf/turtle'
require './lib/biosample.rb'
require 'nokogiri'
require 'erb'
#include RDF

#f = open(ARGV.shift)
#f_out = open(ARGV.shift, "w")
#r = MassBank::Record.new(f.read)
##r.record.each do |e|
##  p e
##end
#factory = MassBank::RDFFactory.new(r.record, f_out)
#factory.rdfize

xml =  ARGV.shift || 'test.xml'
bss = DDBJ::Utils::BioSampleSet.new(xml)
bss.to_ttl
