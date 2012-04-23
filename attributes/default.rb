default[:bag_config] = Mash.new
default[:bag_config][:bag_whitelist] = []
default[:bag_config][:bag_blacklist] = []

=begin

node[:bag_config] = {
  :cookbook => {
    :bag => 'custom_bag_name',
    :item => 'custom_item_name',
    :encrypted => true,
    :secret => 'path/or/pass'
  }
}

node[:bag_config][:allow_lookups] = []
node[:bag_config][:exclude_lookups] = []

=end
