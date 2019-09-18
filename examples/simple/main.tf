module "simple" {
    source "../../"

    name = "simple"
    resource_group_name = "appgw-rg"
    subnet_id = "/subscriptions/...."

    private_ip_address = "10.0.0.100"

    capacity = {
        min = 1
        max = 2
    }

    zones = ["1", "2", "3"]
}