 /*
Code Created by Pablo Urcid
 */
 
 provider "aci" {
      # cisco-aci user name
      username = "admin"
      # cisco-aci password
      password = "cisco123"
      # cisco-aci url
      url      = "https://mx-lab-apic2.cisco.com"
      insecure = true
    }

resource "aci_tenant" "terra-tenant" {
  name        = "Terra-tenant-2-EPGs"
  description = "This tenant is created by terraform"
}

resource "aci_vrf" "vrf-terra" {
    tenant_dn = aci_tenant.terra-tenant.id
    name = "vrf-terra"
}

resource "aci_application_profile" "general-network" {
    tenant_dn = aci_tenant.terra-tenant.id
    name = "general-network"
}

#### EPG4 Start ####

resource "aci_bridge_domain" "bd4" {
    tenant_dn = aci_tenant.terra-tenant.id
    relation_fv_rs_ctx = aci_vrf.vrf-terra.id
    name = "bd4"
}

resource "aci_subnet" "bd4_subnet" {
    parent_dn = aci_bridge_domain.bd4.id
    ip = "4.4.4.1/24"
}

data "aci_vmm_domain" "vds" {
    provider_profile_dn = "uni/vmmp-VMware"
    name = "DVS-Site22"
}

resource "aci_application_epg" "epg4" {
    application_profile_dn = aci_application_profile.general-network.id
    name = "epg4"
    relation_fv_rs_bd = aci_bridge_domain.bd4.id
}

resource "aci_epg_to_domain" "example" {
    application_epg_dn = aci_application_epg.epg4.id
    tdn = data.aci_vmm_domain.vds.id
}

#### EPG4 End ####

resource "null_resource" "delay" {
  provisioner "local-exec" {
    command = "sleep 5"
  }

  triggers = {
    "epg4" = aci_application_epg.epg4.id
    "epg5" = aci_application_epg.epg5.id
  }
}

#### EPG5 Start ####

resource "aci_bridge_domain" "bd5" {
    tenant_dn = aci_tenant.terra-tenant.id
    relation_fv_rs_ctx = aci_vrf.vrf-terra.id
    name = "bd5"
}

resource "aci_subnet" "bd5_subnet" {
    parent_dn = aci_bridge_domain.bd5.id
    ip = "5.5.5.1/24"
}

data "aci_vmm_domain" "vds5" {
    provider_profile_dn = "uni/vmmp-VMware"
    name = "DVS-Site22"
}

resource "aci_application_epg" "epg5" {
    application_profile_dn = aci_application_profile.general-network.id
    name = "epg5"
    relation_fv_rs_bd = aci_bridge_domain.bd5.id
}

resource "aci_epg_to_domain" "example2" {
    application_epg_dn = aci_application_epg.epg5.id
    tdn = data.aci_vmm_domain.vds5.id
}

#### EPG5 End ####

#### ACI Contract Contract/Filter #####

resource "aci_contract" "contract_epg4_epg5" {
  tenant_dn = aci_tenant.terra-tenant.id
  name = "All-Talking-Now"
}

resource "aci_filter" "allow_icmp" {
  tenant_dn = aci_tenant.terra-tenant.id
  name = "allow_icmp"
}

resource "aci_filter_entry" "icmp" {
  name = "icmp-terra"
  #filter_dn = "${aci_filter.allow_icmp.id}"
  filter_dn = aci_filter.allow_icmp.id
  ether_t = "ip"
  prot = "icmp"
  stateful = "yes"
}

resource "aci_contract_subject" "subfilter" { 
  contract_dn = aci_contract.contract_epg4_epg5.id
  name = "subfilter"
  relation_vz_rs_subj_filt_att = [aci_filter.allow_icmp.id]
}

resource "aci_epg_to_contract" "epg4contract" {
    application_epg_dn = "${aci_application_epg.epg4.id}"
    contract_dn  = "${aci_contract.contract_epg4_epg5.id}"
    contract_type = "consumer"
}

resource "aci_epg_to_contract" "epg5contract" {
    application_epg_dn = "${aci_application_epg.epg5.id}"
    contract_dn  = "${aci_contract.contract_epg4_epg5.id}"
    contract_type = "provider"
}


