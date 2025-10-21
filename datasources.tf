# +--------------+ 
# | Data Sources |
# +--------------+
data "oci_core_services" "oci_network_services" {
    filter {
        name   = "name"
        values = ["All .* Services In Oracle Services Network"]
        regex  = true
    }
}