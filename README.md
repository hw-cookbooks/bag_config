BagConfig
=========

Making data bag entries the "last mile" of attribute overrides.

What's it do?
-------------

This cookbook allows attributes to be provided via data bag entries. It slips
functionality into recipes seamlessly to provide consistent functionality across
all recipes, not just those explicitly built for it.

Basic Usage
===========

Access attributes the same way as always:

* `node[:my_cookbook][:my_attribute]`


Naming scheme
=============

Data bags
---------

The name of the data bag used will correspond to the name of the cookbook the
recipe resides within. For example, if the cookbook is named `test`, configuration
entries will be searched for within the `test` data bag. Configuration entries
for a node are based on the node name. If the name of the node is `test1.box`,
then the `test` data bag will be searched for an entry with the id of `config_test1_box`.

Quick Ref:

```
cookbook: test
node name: test1.box
data bag entry: test/config_test1_box
```

Attribute key
-------------

Attribute keys may not always be consistent with cookbook names. For example,
the `chef-client` cookbook uses the attribute key `:chef_client`. This can
be switched via attributes:

* `node[:bag_config][:map]['chef-client'] = 'chef_client'`

Advanced Usage
==============

Custom Data Bag
---------------

If the configuration entries are not within a data bag that corresponds to the
cookbook name (or #node_key if it has been overriden) it can be explicitly defined
via attribute:

* `node[cookbook][:config_data_bag_override] = 'my_custom_bag'`

This will force config entries to be searched for within the `my_custom_bag` data bag.

Custom Data Bag Entry
---------------------

By default, the configuration entries are based on the current node name, prefixed
with `config_`. If a custom entry name is required:

* `node[cookbook][:config_bag] = 'myconfigentry'`

This will force the data bag entry searched for to have the id `myconfigentry`.

Encrypted Data Bag Entry
------------------------

Encrypted data bags are supported when the encrypted attribute is set:

* `node[cookbook][:config_bag][:encrypted] = true`

This will require the secret being provided either inline:

* `node[cookbook][:config_bag][:secret] = 'my_secret'`

or as a path to the secret file on the node:

* `node[cookbook][:config_bag][:secret] = '/etc/config_secret.file'`

Note: If a custom data bag entry name is required, it can be supplied via the
:name key:

* `node[cookbook][:config_bag][:name] = 'myconfigentry'`

Advanced Recipe Usage
=====================

This section is for helpers and configurations available to recipes providing
data bag based configuration.

Accessing configuration attributes
----------------------------------

__This access type is deprecated__

To access a single attribute:

```ruby
file_name = bag_or_node(:file_name)
```

To access a number of attributes:

```ruby
config_hash = bag_or_node_args(:file_name, :file_mode, :etc...)
...
config_hash[:file_name]
```

The latter provides an easy way to fetch all configuration attributes at the
start of the recipe and use the provided hash to access the values throughout
the recipe. 

Note: The resulting hash keys will be symbolized regardless of how they are
initially provided to the method.

Non-standard attributes key
---------------------------

If the key used to access attributes on the node is not the same as the cookbook
name of the recipe, it can be overriden in the recipe by calling #override_node_key.

```ruby
override_node_key('my-test')
```
Non-standard data bag
---------------------

A custom data bag can be defined by recipe. Please note that if this approach is
taken (rather than overriding via attributes) it must be done in all applicable
recipes:

```ruby
override_data_bag('my_bag')
```

