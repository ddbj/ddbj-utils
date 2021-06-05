#!/usr/bin/env ruby

require './lib/biosample.rb'
require 'optparse'

xml = ARGV.shift || 'test.xml'
params = ARGV.getopts("h:","begin:","end:", "split-year")

bss = DDBJ::Utils::BioSampleSet.new(xml, params)
bss.to_tsv
