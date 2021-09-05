#!/usr/bin/env ruby

require './lib/bioproject.rb'
require 'optparse'

xml = ARGV.shift || 'bioproject-test.xml'
params = ARGV.getopts("h:","begin:","end:", "outdir:", "split-year", "split-month")

bss = DDBJ::Utils::BioProjectSet.new(xml, params)
bss.to_output
