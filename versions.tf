terraform {
  required_providers {
    aci = {
      source = "ciscodevnet/aci"
    }
    null = {
      source = "hashicorp/null"
    }
    vsphere = {
      source = "hashicorp/vsphere"
    }
  }
  required_version = ">= 0.13"
}
