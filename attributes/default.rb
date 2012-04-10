default[:bag_config] = Mash.new
default[:bag_config][:mapping] = Mash.new
default[:bag_config][:info] = Mash.new

=begin

default[:bag_config][:mapping] = {'chef-client' => 'chef_client'}
default[:bag_config][:info] = {
  'chef-client' => {
    'encrypted' => true,
    'secret' => 'path/or/string',
    'bag' => 'chef&client',
    'item' => 'custom_config'
  }
}

=end
