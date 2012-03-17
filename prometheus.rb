#!/usr/bin/ruby

# Copyright 2012 Stephen Haywood
# All rights reserved

base = __FILE__
while File.symlink?(base)
	base = File.expand_path(File.readlink(base), File.dirname(base))
end

$:.unshift(File.join(File.dirname(base), 'lib'))

require 'optparse'

options = {}
optparse = OptionParser.new do|opts|
	# Firewall configuration file
	options[:config] = ""
	opts.on( '-c', '--config_file FILE', "Firewall configuration to parse." ) do|c|
		options[:config] = c
	end

	# Report output file
	options[:report] = "#{Time.now.to_f.to_s}.html"
	opts.on( '-r', '--report_file FILE', "Report file to write." ) do |r|
		options[:report] = r
	end
	
	# Report format
	options[:format] = "html"
	opts.on( '-f', '--report_format FORMAT', "Report format to use.") do |f|
		options[:format] = f
	end

	# Verbose output
	options[:verbose] = false
	opts.on( '-v', '--verbose', "Print verbose output.") do |v|
		options[:verbose] = true
	end

	# This displays the help screen.
	opts.on( '-h', '--help', 'Display this screen' ) do
		puts opts
		exit
	end
end

optparse.parse!

# Begin main program
require 'errors'
require 'ui'
require 'parse'
require 'analyze'
require 'report'

include PrometheusErrors
include PrometheusUI

$verbose = options[:verbose]

# Parse the firewall config
begin
	firewall = parse_firewall(options[:config])
rescue ParseError => e
	print_error(e.message)
	exit
end

# Analyze the firewall config
begin
	analysis = analyze_firewall(firewall)
rescue AnalysisError => e
	print_error(e.message)
	exit
end

#Create report for firewall config and analysis
begin
	report_firewall(firewall, analysis, options[:report], options[:format], options[:template] )
rescue ReportError => e
	print_error(e.message)
	exit
end


