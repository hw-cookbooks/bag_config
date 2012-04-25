BagConfig
=========

Making data bag entries the "last mile" of attribute overrides.

What's it do?
-------------

This cookbook allows attributes to be provided via data bag entries. It slips
functionality into recipes seamlessly to provide consistent functionality across
all recipes, not just those explicitly built for it.

Repository
----------

https://github.com/heavywater/chef-bag_config

Basic Usage
===========

Access attributes the same way as always:

* `node[:my_cookbook][:my_attribute]`


Naming scheme
=============

Data bags
---------

The name of the data bag used will correspond to the name of the base attribute
key used within a cookbook. For example, the base attribute key for the munin
cookbook is `munin` thus the data bag name used will be `munin`. However, the 
chef-client cookbook uses the base attribute key of `chef_client` so the data
bag name it uses will be `chef_client`.

The naming of the data bag entries are based on the node name with a `config_`
prefix. Given a node named `lucid`, the data bag entry id would be `config_lucid`.
Periods are replaced with underscores within the node name for generating the
data bag entry name. Thus, a node named `lucid.example.com` would have a data
bag entry id of `config_lucid_example_com`.


Quick Ref:

```
cookbook: chef-client
base key: chef_client
node name: test1.box
data bag name: chef_client
data bag entry id: config_test1_box
```

Advanced Usage
==============

Custom Data Bag
---------------

Example: Use the `myconfig` data bag to supply configuration entries for the
`nagios` attribute:

* `node[:bag_config][:nagios] = {:bag => :myconfig}`

Custom Data Bag Entry
---------------------

Example: Use `custom_config` data bag entry id under the `nagios`
base attribute key:

* `node[:bag_config][:nagios] = {:item => 'custom_config'}`


Encrypted Data Bag Entry
------------------------

Encrypted data bags are supported when the encrypted attribute is set:

* `node[:bag_config][:nagios] = {:encrypted => true}

This will require the secret being provided either inline:

* `node[:bag_config][:nagios] = {:secret => 'my_secret'}`

or as a path to the secret file on the node:

* `node[:bag_config][:nagios] = {:secret => '/etc/config_secret.file'}`

Allowing/Restricting lookups
============================

By default, the every base attribute key used will invoke an attempt
to load a configuration data bag item related to that key. To help
reduce the number of lookups required on a run, whitelisting and blacklisting
on keys is available:

* `node[:bag_config][:bag_whitelist] = [:nagios, :djbdns]`
* `node[:bag_config][:bag_blacklist] = [:nginx, :apache]`

NOTE: The blacklist will _always_ have precedence. This means that if an item
has been specified in the whitelist and is also found in the blacklist, it will
be blacklisted.

Compatibility Note
==================

This version is incompatible with the 1.x versions. It removes all custom methods from Recipe
instances and instead proxies the attribute requests via the node, so no modifications are
required for full support.
