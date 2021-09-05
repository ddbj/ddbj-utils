#!/usr/bin/env ruby

require './lib/bioproject.rb'
require 'optparse'

xml = ARGV.shift || 'bioproject-test.xml'
params = ARGV.getopts("h:","begin:","end:", "split-year")

bps = DDBJ::Utils::BioProjectSet.new(xml, params)
bps.to_tsv
