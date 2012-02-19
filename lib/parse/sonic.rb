def preprocess_wri(config)
	# Preprocess the SonicWall wri file to make it easier to run
	# regexs to capture rules
	config.gsub!(/^Nat Policy Table/, "#INTERFACES_END\nNat Policy Table")
	config.gsub!(/^Interfaces/, "#INTERFACES_START\nInterfaces")
	config.gsub!(/^Rules/, "#RULES_START\nRules")
	config.gsub!(/^Bandwidth Management Configurations/, "#RULES_END\nBandwidth Management Configurations")
	config.gsub!(/^BWM Rules/, "#RULES_END\nBWM Rules")
	config.gsub!(/^Status/, "#STATUS_START\nStatus")
	config.gsub!(/^CPU Monitor/, "#STATUS_END\nCPU Monitor")

	return config
end

def parse_sonic_config(config)

	fw = Config::FirewallConfig.new
	wri = preprocess_wri(config)

	# Find status information and load it into the firewall config
	wri =~ /#STATUS_START(.*)#STATUS_END/m
	status = $1
	if status =~ /Serial number (.*)/ then fw.id = $1 end
	if status =~ /(\d+\/\d+\/\d+)\s/ then fw.date = $1 end
	if status =~ /Firmware version: (.*)/ then fw.firmware = $1 end

	# Find rules and parse them into access lists and rulesets
	wri =~ /#RULES_START(.*)#RULES_END/m
	rules = $1
	str = ""
	rules.each_line do |line|
		if line =~ /From ([A-Z]+ To [A-Z]+)/ then
			fw.access_lists << Config::AccessList.new($1)
		end
		if line =~ /Rule ([0-9]+) \(([a-zA-z]+)\)/
			id = $1
			if $2 == "Enabled" then enabled = "Yes" else enabled = "No" end
		end
		if line =~ /source:\s+(.*)$/ then source = $1 end
		if line =~ /destination:\s(.*)$/ then dest = $1 end
		if line =~ /action:\s+(.*), service:\s+(.*)/ then
			action = $1
			proto = $2
			rule = Config::Rule.new(id, enabled, action, source, dest, proto)
			fw.access_lists.last.ruleset << rule
			rule = nil
		end
	end

	# Find all interfaces
	wri =~ /#INTERFACES_START(.*)INTERFACES_END/m
	interfaces = $1

	interfaces.each_line do |line|
		if line =~ /Interface Name:\s+([A-Z0-9]+)/ then
			fw.interfaces << Config::Interface.new($1)
		end
		if line =~ /IP Address:\s+(.*)/ then fw.interfaces.last.ip = $1 end
		if line =~ /Network Mask:\s+(.*)/ then fw.interfaces.last.mask = $1 end
   	  
   	end
end	
