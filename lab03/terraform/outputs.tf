output "server_ip" {
  value = [for instance in module.instance1 : instance.vm_ip]
}

output "proxy_ip" {
  value = module.instance2.vm_ip
}
