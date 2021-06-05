#!/usr/bin/env ruby

require './lib/biosample.rb'

xml = ARGV.shift || 'test.xml'
bss = DDBJ::Utils::BioSampleSet.new(xml)
bss.to_tsv
