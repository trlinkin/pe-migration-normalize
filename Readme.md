pe-migration-normalize
==========================

Make the PE 3.3.2 to 3.7.x migration a little less painful by
normalizing the exported classifications as much as possible.

Overview
--------------------------

This is a simple collection of Rake tasks aimed at making the migration
of classification data from Puppet Enterprise 3.3.2 to 3.7.x a simpler
and less painful process.

Often when performing an upgrade the likes of the 3.3.2 to 3.7.x
variety, it is common to prefer migration to infrastructure on the new
version rather than performing an upgrade in place. For the most part,
the data stored in a Puppet Enterprise infrastructure is generated over
time from agent runs and is not of enough value to justify the effort of
migrating. The classification data however is important enough. This tool
is focused on the migration of that data.

What does it do?
---------------------------

### The Problem
Currently the PE upgrade path will attempt to convert the 3.3.2
classification data into a form that works for the new NC in 3.7.x
during an in-place upgrade. While this method works, there are a few
issues with this approach. To start, the old infrastructure doesn't persist
as a reference of the former classification, which could be a handy
reference to help in the conversion to the new NC. Also, current migration
technique also does not preserve any former group based organization in
the 3.3.2 and below console. This means that in the new NC, a groups is
made for each individual node migrated. This can be cumbersome to
resolve as well as very time consuming. When migrating 1000 nodes, 1000
NC groups will be created in 3.7.x which may also slow down the NC
operations if not on sufficiently large hardware.

### How This Method Is Different

These rake tasks are originally lifted from the PE Console source itself
and modified a bit. The first advantage they have is that they may be
manually called instead of being implicitly part of an in-place upgrade.
This allows for a true migration from one PE infrastructure to another.
The benefit of this approach is that the legacy infrastructure can be left
in place as a reference to help guide the adoption to the new NC system.

Since most infrastructures that use Puppet tend to have a certain amount
of consistency, there should also be consistency in the classification
across groupings of nodes. This technique tries to group nodes with
matching classifications together. This will assist in the adoption of
the new NC service.

Nodes that have a truly unique classification will receive a custom
group named after the node. This is similar to how the built-in PE
migration would move all nodes.

### Shortcomings

This method does not preserve former console groups as the mapping is
not perfectly one-to-one in every case. It examines the resulting
configuration for each node in the console based on group membership and
direct class assignment and compares these configurations. Matches are
then grouped together.

When grouping together nodes, the group names are generic. They take the
form of "Migration Group [n]" where 'n' will increment for each unique
group. Though these names are not too helpful, they can be changed in
the migration YAML file before import if a review of the import data is
done.

Your mileage will vary. This script is assuming consistency, which is
never a guarantee. Organizations that heavily use direct classification
with class parameters or top scope parameters that are unique may not
receive a great benefit from this migration technique.

Usage
---------------------------

This Rakefile will be used on both the legacy infrastructure and the
newly provisioned infrastructure. It has no other dependencies other than
the Puppet Enterprise Console and this repository can be simply git
cloned onto the nodes involved in the migration.

To run the tasks in this Rakefile, we can simply use it with the `rake`
command installed with PE.

```bash
/opt/puppet/bin/rake -f <path_to_this>/Rakefile <task>
```

This Rakefile exposes two new tasks:
  - `configuration:import_normalized[filename]`
  - `configuration:export_normalized[fileanme]`

The `configuration:export_normalized` task can be run on either PE 3.3.2
or 3.7.x, however it is intended to be run on the legacy 3.3.2 node
that is running the Enterprise Console. It accepts on argument,
`filename`, which is the location to store the export to. This will be
the file that will be imported on the new 3.7.x infrastructure.

__Example Export__

```bash
/opt/puppet/bin/rake -f Rakefile configuration:normalized_export[/tmp/norm.yaml]
Exporting configurations

Node name:
------------------------
master.puppetlabs.vm
example1.puppetlabs.vm
example2.puppetlabs.vm
example3.puppetlabs.vm
example4.puppetlabs.vm
example6.puppetlabs.vm

------------------------

Nodes processed: 6
Unique groups: 1
Configurations unique to single node: 3

Done! Configurations of all nodes were successfully exported.
```

__Example Export YAML__
```yaml
# Exported Puppet Enterprise node classification
# Created: 03/04/2015 19:37:35
---
master.puppetlabs.vm:
  classes:
    pe_console_prune:
      prune_upto: 30
    pe_repo: {}

    pe_repo::platform::el_6_x86_64: {}

    puppet_enterprise::license: {}

  parameters: {}

  nodes:
  - master.puppetlabs.vm
Migration Group 1:
  classes:
    apache: {}

    foo: {}

  parameters: {}

  nodes:
  - example1.puppetlabs.vm
  - example2.puppetlabs.vm
  - example6.puppetlabs.vm
example3.puppetlabs.vm:
  classes:
    apache: {}

    foo: {}

  parameters:
    var: lol
  nodes:
  - example3.puppetlabs.vm
example4.puppetlabs.vm:
  classes:
    apache:
      port: 80
    foo: {}

  parameters: {}

  nodes:
  - example4.puppetlabs.vm
```

The `configuration:import_normalized` task can only be run on the PE 3.7.x
node that is running the Enterprise Console. It accepts one argument,
`filename`, which is the export file that will be imported.

Stop-Gap Warning
----------------------------

Yes, this technique is a stop-gap solution to get over the hump until PE
3.8 which will come equipped with a stronger migration tool.

This migration method will be deprecated once PE 3.8 is released.

