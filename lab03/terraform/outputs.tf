output "server_ip" {
  value = [for instance in module.appservers : instance.vm_ip]
}

output "proxy_ip" {
  value = module.proxy.vm_ip
}

