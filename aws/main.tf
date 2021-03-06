module "local_execution" {
  source  = "../generic_modules/local_exec"
  enabled = var.pre_deployment
}

# This locals entry is used to store the IP addresses of all the machines.
# Autogenerated addresses example based in 10.0.0.0/16
# Iscsi server: 10.0.0.4
# Monitoring: 10.0.0.5
# Hana ips: 10.0.1.10, 10.0.2.11 (hana machines must be in different subnets)
# Hana cluster vip: 192.168.1.10 (virtual ip address must be in a different range than the vpc)
# Netweaver ips: 10.0.3.30, 10.0.4.31, 10.0.3.32, 10.0.4.33 (netweaver ASCS and ERS must be in different subnets)
# Netweaver virtual ips: 192.168.1.30, 192.168.1.31, 192.168.1.32, 192.168.1.33 (virtual ip addresses must be in a different range than the vpc)
# If the addresses are provided by the user will always have preference
locals {
  iscsi_ip      = var.iscsi_srv_ip != "" ? var.iscsi_srv_ip : cidrhost(local.infra_subnet_address_range, 4)
  monitoring_ip = var.monitoring_srv_ip != "" ? var.monitoring_srv_ip : cidrhost(local.infra_subnet_address_range, 5)

  # The next locals are used to map the ip index with the subnet range (something like python enumerate method)
  hana_ip_start    = 10
  hana_ips         = length(var.host_ips) != 0 ? var.host_ips : [for index in range(var.hana_count) : cidrhost(element(local.hana_subnet_address_range, index % 2), index + local.hana_ip_start)]
  hana_cluster_vip = var.hana_cluster_vip != "" ? var.hana_cluster_vip : cidrhost(var.virtual_address_range, local.hana_ip_start)

  # range(4) hardcoded as we always deploy 4 nw machines
  netweaver_ip_start    = 30
  netweaver_ips         = length(var.netweaver_ips) != 0 ? var.netweaver_ips : [for index in range(4) : cidrhost(element(local.netweaver_subnet_address_range, index % 2), index + local.netweaver_ip_start)]
  netweaver_virtual_ips = length(var.netweaver_virtual_ips) != 0 ? var.netweaver_virtual_ips : [for ip_index in range(local.netweaver_ip_start, local.netweaver_ip_start + 4) : cidrhost(var.virtual_address_range, ip_index)]
}

module "iscsi_server" {
  source                 = "./modules/iscsi_server"
  aws_region             = var.aws_region
  availability_zones     = data.aws_availability_zones.available.names
  subnet_ids             = aws_subnet.infra-subnet.*.id
  iscsi_srv_images       = var.iscsi_srv
  iscsi_instancetype     = var.iscsi_instancetype
  min_instancetype       = var.min_instancetype
  key_name               = aws_key_pair.key-pair.key_name
  security_group_id      = local.security_group_id
  private_key_location   = var.private_key_location
  iscsi_srv_ip           = local.iscsi_ip
  iscsidev               = var.iscsidev
  iscsi_disks            = var.iscsi_disks
  reg_code               = var.reg_code
  reg_email              = var.reg_email
  reg_additional_modules = var.reg_additional_modules
  additional_packages    = var.additional_packages
  ha_sap_deployment_repo = var.ha_sap_deployment_repo
  provisioner            = var.provisioner
  background             = var.background
  qa_mode                = var.qa_mode
  on_destroy_dependencies = [
    aws_route_table_association.infra-subnet-route-association,
    aws_route.public,
    aws_security_group_rule.ssh,
    aws_security_group_rule.outall
  ]
}

module "netweaver_node" {
  source                     = "./modules/netweaver_node"
  netweaver_count            = var.netweaver_enabled == true ? 4 : 0
  instancetype               = var.netweaver_instancetype
  name                       = "netweaver"
  aws_region                 = var.aws_region
  availability_zones         = data.aws_availability_zones.available.names
  sles4sap_images            = var.sles4sap
  vpc_id                     = local.vpc_id
  subnet_address_range       = local.netweaver_subnet_address_range
  key_name                   = aws_key_pair.key-pair.key_name
  security_group_id          = local.security_group_id
  route_table_id             = aws_route_table.route-table.id
  efs_performance_mode       = var.netweaver_efs_performance_mode
  aws_credentials            = var.aws_credentials
  aws_access_key_id          = var.aws_access_key_id
  aws_secret_access_key      = var.aws_secret_access_key
  s3_bucket                  = var.netweaver_s3_bucket
  netweaver_product_id       = var.netweaver_product_id
  netweaver_swpm_folder      = var.netweaver_swpm_folder
  netweaver_sapcar_exe       = var.netweaver_sapcar_exe
  netweaver_swpm_sar         = var.netweaver_swpm_sar
  netweaver_swpm_extract_dir = var.netweaver_swpm_extract_dir
  netweaver_sapexe_folder    = var.netweaver_sapexe_folder
  netweaver_additional_dvds  = var.netweaver_additional_dvds
  hana_ip                    = var.hana_cluster_vip
  host_ips                   = local.netweaver_ips
  virtual_host_ips           = local.netweaver_virtual_ips
  public_key_location        = var.public_key_location
  private_key_location       = var.private_key_location
  iscsi_srv_ip               = module.iscsi_server.iscsisrv_ip
  cluster_ssh_pub            = var.cluster_ssh_pub
  cluster_ssh_key            = var.cluster_ssh_key
  reg_code                   = var.reg_code
  reg_email                  = var.reg_email
  reg_additional_modules     = var.reg_additional_modules
  ha_sap_deployment_repo     = var.ha_sap_deployment_repo
  devel_mode                 = var.devel_mode
  provisioner                = var.provisioner
  background                 = var.background
  monitoring_enabled         = var.monitoring_enabled
  on_destroy_dependencies = [
    aws_route.public,
    aws_security_group_rule.ssh,
    aws_security_group_rule.outall
  ]
}

module "hana_node" {
  source                 = "./modules/hana_node"
  hana_count             = var.hana_count
  instancetype           = var.instancetype
  name                   = var.name
  init_type              = var.init_type
  scenario_type          = var.scenario_type
  aws_region             = var.aws_region
  availability_zones     = data.aws_availability_zones.available.names
  sles4sap_images        = var.sles4sap
  vpc_id                 = local.vpc_id
  subnet_address_range   = local.hana_subnet_address_range
  key_name               = aws_key_pair.key-pair.key_name
  security_group_id      = local.security_group_id
  route_table_id         = aws_route_table.route-table.id
  aws_credentials        = var.aws_credentials
  aws_access_key_id      = var.aws_access_key_id
  aws_secret_access_key  = var.aws_secret_access_key
  host_ips               = local.hana_ips
  hana_data_disk_type    = var.hana_data_disk_type
  hana_inst_master       = var.hana_inst_master
  hana_inst_folder       = var.hana_inst_folder
  hana_platform_folder   = var.hana_platform_folder
  hana_sapcar_exe        = var.hana_sapcar_exe
  hdbserver_sar          = var.hdbserver_sar
  hana_extract_dir       = var.hana_extract_dir
  hana_disk_device       = var.hana_disk_device
  hana_fstype            = var.hana_fstype
  hana_cluster_vip       = local.hana_cluster_vip
  private_key_location   = var.private_key_location
  iscsi_srv_ip           = module.iscsi_server.iscsisrv_ip
  cluster_ssh_pub        = var.cluster_ssh_pub
  cluster_ssh_key        = var.cluster_ssh_key
  reg_code               = var.reg_code
  reg_email              = var.reg_email
  reg_additional_modules = var.reg_additional_modules
  additional_packages    = var.additional_packages
  ha_sap_deployment_repo = var.ha_sap_deployment_repo
  devel_mode             = var.devel_mode
  hwcct                  = var.hwcct
  qa_mode                = var.qa_mode
  provisioner            = var.provisioner
  background             = var.background
  monitoring_enabled     = var.monitoring_enabled
  on_destroy_dependencies = [
    aws_route.public,
    aws_security_group_rule.ssh,
    aws_security_group_rule.outall
  ]
}

module "monitoring" {
  source                 = "./modules/monitoring"
  monitor_instancetype   = var.monitor_instancetype
  min_instancetype       = var.min_instancetype
  key_name               = aws_key_pair.key-pair.key_name
  security_group_id      = local.security_group_id
  monitoring_srv_ip      = local.monitoring_ip
  private_key_location   = var.private_key_location
  aws_region             = var.aws_region
  availability_zones     = data.aws_availability_zones.available.names
  sles4sap_images        = var.sles4sap
  subnet_ids             = aws_subnet.infra-subnet.*.id
  host_ips               = [local.hana_ips]
  timezone               = var.timezone
  reg_code               = var.reg_code
  reg_email              = var.reg_email
  reg_additional_modules = var.reg_additional_modules
  additional_packages    = var.additional_packages
  ha_sap_deployment_repo = var.ha_sap_deployment_repo
  provisioner            = var.provisioner
  background             = var.background
  monitoring_enabled     = var.monitoring_enabled
  netweaver_enabled      = var.netweaver_enabled
  netweaver_ips          = local.netweaver_virtual_ips
  on_destroy_dependencies = [
    aws_route_table_association.infra-subnet-route-association,
    aws_route.public,
    aws_security_group_rule.ssh,
    aws_security_group_rule.outall
  ]
}
