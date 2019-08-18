variable "nsgip" {
 description = "Workstation external IP to allow connections to JB, Kibana, Grafana"
 default = "< workstation external ip >"
}

variable "ssh_user" {
 default = "martin"
}

variable "ssh_pubkey_location" {
 default = "~/.ssh/dummychefsolokey.pub"
}

variable "ssh_privkey_location" {
 default = "~/.ssh/dummychefsolokey"
}

variable "subscription_id" {
    default = ""
}

variable "client_id" {
    default = ""
}

variable "client_secret" {
    default = ""
}

variable "tenant_id" {
    default = ""
}
