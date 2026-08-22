# PII passed to the infra module. Values come from TF_VAR_* environment
# variables, loaded from the GNOME Keyring by the tofu wrapper in
# flake.nix. These values must not be committed to this repository.

variable "pii_email" {
  type      = string
  sensitive = true
}

variable "pii_address" {
  type      = string
  sensitive = true
}

variable "pii_city" {
  type      = string
  sensitive = true
}

variable "pii_state" {
  type      = string
  sensitive = true
}

variable "pii_postal_code" {
  type      = string
  sensitive = true
}

variable "pii_country" {
  type      = string
  sensitive = true
}

variable "pii_first_name" {
  type      = string
  sensitive = true
}

variable "pii_last_name" {
  type      = string
  sensitive = true
}

variable "pii_middle_name" {
  type      = string
  sensitive = true
}

variable "pii_phone" {
  type      = string
  sensitive = true
}
