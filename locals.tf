locals {
  // GENERATE NAMES
  rsg_name = join("", [var.project_name, "rsg", var.resource_sequence])
  akv_name = join("", [var.project_name, "akv", var.resource_sequence])
  sta_name = join("", [var.project_name, "sta", var.resource_sequence])
  lwk_name = join("", [var.project_name, "lwk", var.resource_sequence])
  vnt_name = join("", [var.project_name, "vnt", var.resource_sequence])
  vm_name  = join("", [var.project_name, "vml", var.resource_sequence])
}