#!/usr/bin/env ruby

require './lib/biosample.rb'
require 'optparse'

xml = ARGV.shift || 'test.xml'
params = ARGV.getopts("h:","begin:","end:", "outdir:", "split-year", "split-month")

bss = DDBJ::Utils::BioSampleSet.new(xml, params)
bss.to_output
