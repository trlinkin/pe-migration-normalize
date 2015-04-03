require 'optparse'
require 'yaml'

options = {}

OptionParser.new do |opts|

  opts.banner = "Usage: nornamilze.rb [options] INPUT_FILE"

  opts.on("-d", "--details", "Display details on consistency discovered in input file") do
    options[:details] = true
  end

  opts.on('-o', '--output_file FILE', "Write output to custom FILE") do |file|
    options[:output_file] = file
  end
end.parse!

options[:output_file] ||= "normalized-pe_classification_export.yaml"

def cputs(string)
    puts "\033[1m#{string}\033[0m"
end

abort("Must provide an export file to load") unless export_file = ARGV.first

cputs "Loading classification export YAML..."
classification = YAML.load(File.read(export_file))

# Process the current classification dump and find similar classifications
groups = {}

classification.each do |name, details|
  node_name = details['name']
  details.delete('name')
  groups[details] = [] unless groups[details]
  groups[details] << node_name
end


# Print details if option passed
if options[:details]
  single_nodes = groups.select{ |set, nodes| nodes.size == 1 }
  cputs "\n###### Basic Normalization Details ######"
  cputs "Total nodes parsed: #{classification.size}"
  cputs "Total unique groups: #{groups.size}"
  cputs "Total classifications unique to one node: #{single_nodes.size}"
end

# Create normalized strcture to be converted to YAML for use with modified rake task
normalized = {}
group_id = 1

groups.each do |details, nodes|
  details['nodes'] = nodes

  if nodes.size == 1
    normalized[nodes.first] = details
  else
    normalized["Migration Group #{group_id}"] = details
    group_id += 1
  end
end

# create file to be used with rake task
cputs "\nCreating normalized export file: #{options[:output_file]}"
File.open(options[:output_file], 'w') do |f|
  f << normalized.to_yaml
end
