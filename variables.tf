variable "enable_cluster_role" {
  description = "Whether to create the ClusterRole and ClusterRoleBinding"
  type        = bool
  default     = true
}

#oauth2Proxy->endpoint(ingress)->nginx(proxy)->service(backend)->pod