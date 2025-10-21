# +-------------------------+ 
# | Creation of the Network |
# +-------------------------+
resource "oci_core_vcn" "vcn" {
    compartment_id = var.compartment_ocid
    cidr_block     = "${var.network_cidr}.0.0/16"
    display_name   = "VCN_${var.network_name}"
    dns_label      = lower(var.network_dns)
}

resource "oci_core_internet_gateway" "internet_gateway" {
    compartment_id = var.compartment_ocid
    display_name   = "IG_${var.network_name}"
    enabled        = "true"
    vcn_id         = oci_core_vcn.vcn.id
}

resource "oci_core_nat_gateway" "nat_gateway" {
    compartment_id = var.compartment_ocid
    display_name   = "NG_${var.network_name}"
    vcn_id         = oci_core_vcn.vcn.id
}

resource "oci_core_service_gateway" "service_gateway" {
    compartment_id = var.compartment_ocid
    display_name   = "SG_${var.network_name}"
    vcn_id         = oci_core_vcn.vcn.id

    services {
        service_id = data.oci_core_services.oci_network_services.services.0.id
    }
}

resource "oci_core_default_dhcp_options" "default_dhcp_options" {
    manage_default_resource_id = oci_core_vcn.vcn.default_dhcp_options_id
    compartment_id             = var.compartment_ocid
    display_name               = "DHCP_${var.network_name}"

    options {
        type        = "DomainNameServer"
        server_type = "VcnLocalPlusInternet"
    }

    options {
        type                = "SearchDomain"
        search_domain_names = [ "${lower(var.network_dns)}.oraclevcn.com" ]
    }
}

resource "oci_core_route_table" "route_table_private" {
    compartment_id = var.compartment_ocid
    display_name   = "RT_PRIVATE_${var.network_name}"
    vcn_id         = oci_core_vcn.vcn.id

    route_rules {
        description       = "Traffic to Internet"
        destination       = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
        network_entity_id = oci_core_nat_gateway.nat_gateway.id
    }

    route_rules {
        description       = "Traffic to OCI Services"
        destination       = data.oci_core_services.oci_network_services.services.0.cidr_block
        destination_type  = "SERVICE_CIDR_BLOCK"
        network_entity_id = oci_core_service_gateway.service_gateway.id
    }
}

resource "oci_core_default_route_table" "default_route_table" {
    manage_default_resource_id = oci_core_vcn.vcn.default_route_table_id
    compartment_id             = var.compartment_ocid
    display_name               = "RT_PUBLIC_${var.network_name}"

    route_rules {
        description       = "Traffic to/from Internet"
        destination       = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
        network_entity_id = oci_core_internet_gateway.internet_gateway.id
    }
}

resource "oci_core_default_security_list" "default_security_list" {
    manage_default_resource_id = oci_core_vcn.vcn.default_security_list_id
    compartment_id             = var.compartment_ocid
    display_name               = "SL_PUBLIC_${var.network_name}"

    egress_security_rules {
        description      = "Allow access to Internet"
        destination      = "0.0.0.0/0"
        destination_type = "CIDR_BLOCK"
        protocol         = "all"
        stateless        = "false"
    }

    ingress_security_rules {
        protocol    = "6"
        description = "Inbound SSH traffic"
        source      = "0.0.0.0/0"
        source_type = "CIDR_BLOCK"
        stateless   = "false"

        tcp_options {
            max = "22"
            min = "22"
        }
    }

    ingress_security_rules {
        description = "Allow access to all VCN Subnets"
        protocol    = "all"
        source      = "${var.network_cidr}.0.0/16"
        stateless   = "false"
    }
}

resource "oci_core_security_list" "private_security_list" {
    compartment_id = var.compartment_ocid
    display_name   = "SL_PRIVATE_${var.network_name}"
    vcn_id         = oci_core_vcn.vcn.id

    egress_security_rules {
        description      = "Allow access to Internet"
        destination      = "0.0.0.0/0"
        destination_type = "CIDR_BLOCK"
        protocol         = "all"
        stateless        = "false"
    }

    ingress_security_rules {
        protocol    = "6"
        description = "Inbound SSH traffic"
        source      = "0.0.0.0/0"
        source_type = "CIDR_BLOCK"
        stateless   = "false"

        tcp_options {
            max = "22"
            min = "22"
        }
    }

    ingress_security_rules {
        description = "Allow access to all VCN Subnets"
        protocol    = "all"
        source      = "${var.network_cidr}.0.0/16"
        stateless   = "false"
    }
}

resource "oci_core_subnet" "public_subnet" {
    cidr_block                 = "${var.network_cidr}.0.0/24"
    display_name               = "SUBNET_PUBLIC_${var.network_name}"
    dns_label                  = "pub"
    prohibit_public_ip_on_vnic = "false"
    security_list_ids          = [oci_core_vcn.vcn.default_security_list_id]
    compartment_id             = var.compartment_ocid
    vcn_id                     = oci_core_vcn.vcn.id
    route_table_id             = oci_core_vcn.vcn.default_route_table_id
}

resource "oci_core_subnet" "private_subnet" {
    cidr_block                 = "${var.network_cidr}.1.0/24"
    display_name               = "SUBNET_PRIVATE_${var.network_name}"
    dns_label                  = "prv"
    prohibit_public_ip_on_vnic = "true"
    security_list_ids          = [oci_core_security_list.private_security_list.id]
    compartment_id             = var.compartment_ocid
    vcn_id                     = oci_core_vcn.vcn.id
    route_table_id             = oci_core_route_table.route_table_private.id
}