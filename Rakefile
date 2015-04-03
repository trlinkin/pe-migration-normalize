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

    groups = []

    DEFAULT_GROUP_ID = '00000000-0000-4000-8000-000000000000'

    # Default group
    begin
      default_group_json = PuppetHttps.get("#{SETTINGS.nc_api_url}/v1/groups/#{DEFAULT_GROUP_ID}", 'application/json', true)
      groups << JSON.parse(default_group_json)
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

