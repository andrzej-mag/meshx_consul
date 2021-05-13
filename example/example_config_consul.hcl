// use for testing only!!!
datacenter = "my-dc"
// server = true
// start_join = ["xxx.xxx.xxx.xxx"]
// retry_join = ["xxx.xxx.xxx.xxx"]
addresses = {
  grpc = "unix:///run/consul/grpc.sock",
  http = "unix:///run/consul/http.sock"
}
unix_sockets = {
  user = "xxx" // Consul uid
  group = "xxx" // Consul gid
  mode = "660"
}
encrypt = "topsecretsecretsecretsecret"
ca_file = "/etc/consul.d/cert/consul-agent-ca.pem"
cert_file = "/etc/consul.d/cert/my-dc-server-consul-0.pem"
key_file = "/etc/consul.d/cert/my-dc-server-consul-0-key.pem"
verify_incoming = true
verify_outgoing = true
data_dir = "/opt/consul/data"
ui_config = {
  enabled = true
}
acl = {
  enabled = true
  default_policy = "allow"
  enable_token_persistence = true
}
