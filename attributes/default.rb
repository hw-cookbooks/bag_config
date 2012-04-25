default[:bag_config] = Mash.new
default[:bag_config][:bag_whitelist] = []
default[:bag_config][:bag_blacklist] = []

=begin

node[:bag_config] = {
  :base_key => {
    :bag => 'custom_bag_name',
    :item => 'custom_item_name',
    :encrypted => true,
    :secret => 'path/or/pass'
  },
  :bag_whitelist => [:nagios],
  :bag_blacklist => [:nginx, :apache]
}

=end
