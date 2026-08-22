# DNSimple handles both domain registration and DNS.
#
# I still have domains registered with Namecheap, which I will move over to DNSimple
# as they approach their yearly renewal.
#
# TODO: Migrate registration to DNSimple for the following sites before renewal:
# - jhendrickson.dev    Renews: 2027-02-11
# - joni-on-micro.site  Renews: 2027-02-15
# - joni.site           Renews: 2027-02-28

# ---------------------------------------------------------
# joni.site
#
# My primary personal website and email domain.
# - Webserver provided by a small VPS in hetzner.tf
# - Email is hosted with Fastmail

resource "dnsimple_zone" "joni_site" {
  name = "joni.site"

  lifecycle {
    prevent_destroy = true
  }
}

resource "dnsimple_zone_record" "joni_site_apex_a" {
  zone_name = dnsimple_zone.joni_site.name
  name      = ""
  type      = "A"
  ttl       = 3600
  # IP referenced directly from Hetzner resources
  value     = hcloud_primary_ip.wasabi_ipv4.ip_address

  depends_on = [dnsimple_zone.joni_site]

  lifecycle {
    prevent_destroy = true
  }
}

resource "dnsimple_zone_record" "joni_site_apex_aaaa" {
  zone_name = dnsimple_zone.joni_site.name
  name      = ""
  type      = "AAAA"
  ttl       = 3600
  # IP referenced directly from Hetzner resources
  value     = hcloud_primary_ip.wasabi_ipv6.ip_address

  depends_on = [dnsimple_zone.joni_site]

  lifecycle {
    prevent_destroy = true
  }
}

resource "dnsimple_zone_record" "joni_site_www_a" {
  zone_name = dnsimple_zone.joni_site.name
  name      = "www"
  type      = "A"
  ttl       = 3600
  # IP referenced directly from Hetzner resources
  value     = hcloud_primary_ip.wasabi_ipv4.ip_address

  depends_on = [dnsimple_zone.joni_site]

  lifecycle {
    prevent_destroy = true
  }
}

resource "dnsimple_zone_record" "joni_site_www_aaaa" {
  zone_name = dnsimple_zone.joni_site.name
  name      = "www"
  type      = "AAAA"
  ttl       = 3600
  # IP referenced directly from Hetzner resources
  value     = hcloud_primary_ip.wasabi_ipv6.ip_address

  depends_on = [dnsimple_zone.joni_site]

  lifecycle {
    prevent_destroy = true
  }
}

# Standard Fastmail configuration.

resource "dnsimple_zone_record" "joni_site_mx_1" {
  zone_name = dnsimple_zone.joni_site.name
  name      = ""
  type      = "MX"
  ttl       = 3600
  priority  = 10
  value     = "in1-smtp.messagingengine.com"

  depends_on = [dnsimple_zone.joni_site]

  lifecycle {
    prevent_destroy = true
  }
}

resource "dnsimple_zone_record" "joni_site_mx_2" {
  zone_name = dnsimple_zone.joni_site.name
  name      = ""
  type      = "MX"
  ttl       = 3600
  priority  = 20
  value     = "in2-smtp.messagingengine.com"

  depends_on = [dnsimple_zone.joni_site]

  lifecycle {
    prevent_destroy = true
  }
}

resource "dnsimple_zone_record" "joni_site_spf" {
  zone_name = dnsimple_zone.joni_site.name
  name      = ""
  type      = "TXT"
  ttl       = 3600
  value     = "\"v=spf1 include:spf.messagingengine.com ?all\""

  depends_on = [dnsimple_zone.joni_site]

  lifecycle {
    prevent_destroy = true
  }
}

resource "dnsimple_zone_record" "joni_site_dkim_1" {
  zone_name = dnsimple_zone.joni_site.name
  name      = "fm1._domainkey"
  type      = "CNAME"
  ttl       = 3600
  value     = "fm1.joni.site.dkim.fmhosted.com"

  depends_on = [dnsimple_zone.joni_site]

  lifecycle {
    prevent_destroy = true
  }
}

resource "dnsimple_zone_record" "joni_site_dkim_2" {
  zone_name = dnsimple_zone.joni_site.name
  name      = "fm2._domainkey"
  type      = "CNAME"
  ttl       = 3600
  value     = "fm2.joni.site.dkim.fmhosted.com"

  depends_on = [dnsimple_zone.joni_site]

  lifecycle {
    prevent_destroy = true
  }
}

resource "dnsimple_zone_record" "joni_site_dkim_3" {
  zone_name = dnsimple_zone.joni_site.name
  name      = "fm3._domainkey"
  type      = "CNAME"
  ttl       = 3600
  value     = "fm3.joni.site.dkim.fmhosted.com"

  depends_on = [dnsimple_zone.joni_site]

  lifecycle {
    prevent_destroy = true
  }
}

# ---------------------------------------------------------
# cedh-decklist-database.com
#
# Public website listing competitive Commander decks for Magic: The Gathering.
# Old college project I still keep alive, but all its content is handled by a
# team of volunteers.

resource "dnsimple_registered_domain" "cedh_decklist_database" {
  name                  = "cedh-decklist-database.com"
  contact_id            = dnsimple_contact.default.id
  auto_renew_enabled    = true
  dnssec_enabled        = true
  transfer_lock_enabled = true
  whois_privacy_enabled = true

  depends_on = [dnsimple_zone.cedh_decklist_database]

  lifecycle {
    prevent_destroy = true
  }
}

# Registrant contact. PII values come from pii_* variables so they stay
# out of this public repository.

resource "dnsimple_contact" "default" {
  address1          = var.pii_address
  address2          = ""
  city              = var.pii_city
  country           = var.pii_country
  email             = var.pii_email
  first_name        = var.pii_first_name
  job_title         = ""
  label             = "Default"
  last_name         = var.pii_last_name
  organization_name = ""
  phone             = var.pii_phone
  postal_code       = var.pii_postal_code
  state_province    = var.pii_state

  lifecycle {
    prevent_destroy = true
  }
}

resource "dnsimple_zone" "cedh_decklist_database" {
  name = "cedh-decklist-database.com"

  lifecycle {
    prevent_destroy = true
  }
}

# Apex A records use GitHub's shared Pages addresses, which GitHub
# changes occasionally.

resource "dnsimple_zone_record" "cedh_apex_a_1" {
  zone_name = dnsimple_zone.cedh_decklist_database.name
  name      = ""
  type      = "A"
  ttl       = 3600
  value     = "185.199.110.153"

  depends_on = [dnsimple_zone.cedh_decklist_database]

  lifecycle {
    prevent_destroy = true
  }
}

resource "dnsimple_zone_record" "cedh_apex_a_2" {
  zone_name = dnsimple_zone.cedh_decklist_database.name
  name      = ""
  type      = "A"
  ttl       = 3600
  value     = "185.199.108.153"

  depends_on = [dnsimple_zone.cedh_decklist_database]

  lifecycle {
    prevent_destroy = true
  }
}

resource "dnsimple_zone_record" "cedh_apex_a_3" {
  zone_name = dnsimple_zone.cedh_decklist_database.name
  name      = ""
  type      = "A"
  ttl       = 3600
  value     = "185.199.111.153"

  depends_on = [dnsimple_zone.cedh_decklist_database]

  lifecycle {
    prevent_destroy = true
  }
}

resource "dnsimple_zone_record" "cedh_apex_a_4" {
  zone_name = dnsimple_zone.cedh_decklist_database.name
  name      = ""
  type      = "A"
  ttl       = 3600
  value     = "185.199.109.153"

  depends_on = [dnsimple_zone.cedh_decklist_database]

  lifecycle {
    prevent_destroy = true
  }
}

resource "dnsimple_zone_record" "cedh_google_verification" {
  zone_name = dnsimple_zone.cedh_decklist_database.name
  name      = ""
  type      = "TXT"
  ttl       = 3600
  value     = "\"google-site-verification=Njb5A1OygyJa_CIxGH7Drq6CEzO12RIHEeYoguRjD2I\""

  depends_on = [dnsimple_zone.cedh_decklist_database]

  lifecycle {
    prevent_destroy = true
  }
}

resource "dnsimple_zone_record" "cedh_www_cname" {
  zone_name = dnsimple_zone.cedh_decklist_database.name
  name      = "www"
  type      = "CNAME"
  ttl       = 60
  value     = "cedh-decklist-database.github.io"

  depends_on = [dnsimple_zone.cedh_decklist_database]

  lifecycle {
    prevent_destroy = true
  }
}
