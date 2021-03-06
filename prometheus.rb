#!/usr/bin/env ruby

# Copyright 2012 Stephen Haywood aka AverageSecurityGuy
# All rights reserved see LICENSE file.

# Tell Ruby to look in the lib folder for include files
base = __FILE__
while File.symlink?(base)
	base = File.expand_path(File.readlink(base), File.dirname(base))
end

$:.unshift(File.join(File.dirname(base), 'lib'))
$base_dir = File.dirname(base)

# Set the version number
version = '2.0.4'

# Setup optparse to handle command line arguments.
require 'optparse'

options = {}
optparse = OptionParser.new do |opts|
	# Usage banner
	opts.banner = "Usage: ./prometheus.rb -c config_file [options]"

	# Firewall configuration file
	options[:config] = ""
	opts.on( '-c', '--config_file FILE', "Firewall configuration to parse." ) do|c|
		options[:config] = c
	end

	# Report output file
	options[:report] = nil
	opts.on( '-r', '--report_file FILE', "Report file to write." ) do |r|
		options[:report] = r
	end
	
	# Report format
	options[:format] = "html"
	opts.on( '-f', '--format FORMAT', "Report format to use." ) do |f|
		options[:format] = f
	end

	# Report template
	options[:template] = nil
	opts.on( '-t', '--template FILE', "File to use as template." ) do |t|
		options[:template] = t
	end

	# Verbose output
	options[:verbose] = false
	opts.on( '-v', '--verbose', "Print verbose output.") do |v|
		options[:verbose] = true
	end

	# Debug output
	options[:debug] = false
	opts.on( '-d', '--debug', "Print debug output (very verbose).") do |d|
		options[:debug] = true
	end

	# Display Version
	options[:version] = false
	opts.on( '-V', '--version', "Print version number.") do |ver|
		options[:version] = true
	end

	# This displays the help screen.
	opts.on( '-h', '--help', 'Display this screen' ) do
		puts opts
		exit
	end
end

optparse.parse!

# Begin main program
require 'common'
require 'parse'
require 'analyze'
require 'report'

include PrometheusErrors
include PrometheusUI

$verbose = options[:verbose]
$debug = options[:debug]

if options[:version]
	print_line("Prometheus version #{version}")
	exit(1)
end

print_status("Launching Prometheus version #{version}.")
config = open_config_file(options[:config])

# Parse the firewall config
begin
	firewall = parse_firewall(config)
rescue ParseError => e
	print_error(e.message)
	exit(1)
end

# Analyze the firewall config
begin
analysis = analyze_firewall(firewall, config)
rescue AnalysisError => e
	print_error(e.message)
	exit(1)
end

#Create report for firewall config and analysis
begin
	report_firewall(firewall, analysis, options[:report], options[:format], options[:template] )
rescue ReportError => e
	print_error(e.message)
	exit(1)
end