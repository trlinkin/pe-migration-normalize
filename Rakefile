#!/usr/bin/env rake

load '/opt/puppet/share/puppet-dashboard/Rakefile'

namespace :configuration do

  desc 'Import normalized configurations of all nodes from a file to new NC.'
  repeatable_task :import_normalized, [:filename] => :environment do |task|

    unless filename = task.get_parameter(:filename)
      puts 'Must specify a source filename.'
      exit 1
    end

    puts 'Importing configurations'
    puts

    confs = YAML.load(File.read(filename))

    DEFAULT_GROUP_ID = '00000000-0000-4000-8000-000000000000'

    # Default group
    begin
      default_group_json = PuppetHttps.get("#{SETTINGS.nc_api_url}/v1/groups", 'application/json', true)
      groups = JSON.parse(default_group_json)
    rescue Net::HTTPExceptions => e
      report_error(e.response)
      exit
    end

    agent_specified_rule = ['or']

    # Classification
    confs.each do |env_name, conf|

      node_rules = ['or']
      conf["nodes"].each do |node_name|
        agent_specified_rule << ['=', 'name', node_name]
        node_rules << ['=', 'name', node_name]
      end

      group = {}
      group[:id] = SecureRandom::uuid
      group[:name] = env_name
      group[:description] = ""
      group[:environment] = 'production'
      group[:environment_trumps] = false
      group[:parent] = DEFAULT_GROUP_ID
      group[:rule] = node_rules
      group[:variables] = conf["parameters"]
      group[:classes] = conf["classes"]

      groups << group
    end

    # Agent-specified environment
    group = {}
    group[:id] = SecureRandom::uuid
    group[:name] = 'Agent-specified environment'
    group[:description] = "This group is for imported nodes that need to retain an environment specified using a source other than the PE console. To achieve this, the node's environment is not reported to the master."
    group[:environment] = 'agent-specified'
    group[:environment_trumps] = true
    group[:parent] = DEFAULT_GROUP_ID
    group[:rule] = agent_specified_rule
    group[:variables] = {}
    group[:classes] = {}

    groups << group

    response = PuppetHttps.post("#{SETTINGS.nc_api_url}/v1/import-hierarchy", 'application/json', groups.to_json, true)

    if response.kind_of? Net::HTTPClientError or response.kind_of? Net::HTTPServerError
      report_error(response)
    else
      puts "Done - all configurations were successfully imported"
    end
  end
end

namespace :configuration do

  desc 'Export configurations of all nodes to a file.'
  repeatable_task :export_normalized, [:filename] => :environment do |task|

    unless filename = task.get_parameter(:filename)
      puts 'Must specify a target filename.'
      exit 1
    end

    puts 'Exporting configurations'
    puts
    puts 'Node name:'
    puts '------------------------'

    confs = {}
    error_nodes = []
    Node.all.each do |node|
      puts node.name
      begin
        node_configuration = node.configuration
        node_configuration['classes'] = node_configuration['classes'].delete_if { |key, value| class_to_remove?(key) }
        confs[node.name] = node_configuration
      rescue => e
        error_nodes << node.name
        puts "  Error: #{e.message}. Skipping this node."
      end
    end

    groups = {}

    confs.each do |name, conf|
      conf.delete('name')
      groups[conf] = [] unless groups[conf]
      groups[conf] << name
    end

    normalized = {}
    group_id = 1

    groups.each do |conf, nodes|
      conf['nodes'] = nodes

      if nodes.size == 1
        normalized[nodes.first] = conf
      else
        normalized["Migration Group #{group_id}"] = conf
        group_id += 1
      end
    end

    puts
    puts '------------------------'
    puts
    puts "Nodes processed: #{Node.all.size}"
    puts "Unique consolidated groups: #{group_id - 1}"

    single_nodes = groups.select{ |set, nodes| nodes.size == 1 }
    puts "Configurations unique to single node: #{single_nodes.size}"

    tempfile  = Tempfile.new(['configurations', 'yml'])
    begin
      tempfile.write("# Exported Puppet Enterprise node classification\n")
      tempfile.write("# Created: #{DateTime.now.strftime '%d/%m/%Y %H:%M:%S'}\n")
      tempfile.write(normalized.to_yaml)
    ensure
      tempfile.close
    end

    FileUtils.chmod(0400, tempfile.path)
    FileUtils.mv(tempfile.path, filename)

    puts

    if error_nodes.empty?
      puts 'Done! Configurations of all nodes were successfully exported.'
    else
      puts 'Done! However, configurations of the following nodes were not exported:'
      puts error_nodes.join(', ')
    end
  end
end

def class_to_remove?(class_name)
  ['pe_puppetdb', 'pe_postgresql', 'pe_mcollective'].each do |module_name|
    if class_name.start_with? module_name
      return true
    end
  end

  false
end
