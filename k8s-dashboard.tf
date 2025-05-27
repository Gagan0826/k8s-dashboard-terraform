resource "helm_release" "k8s_dashboard" {
  name          = "kubernetes-dashboard"
  count         =  1
  repository    = "https://kubernetes.github.io/dashboard/"
  chart         = "kubernetes-dashboard"
  version       = "7.5.0"
  namespace     = "default"
  max_history   = 3
  recreate_pods = true

  depends_on = [
    helm_release.ingress_nginx,
  ]

  values = [
  yamlencode({
    extras = {
      serviceMonitor = {
        enabled = false
      }
    }
   
    protocolHttp = true
    metrics-server = { enabled = true }
          kong = {
        enabled = true  # Change to true to ensure templates are available
      }
    app = {
      #mode= "api"
      ingress = {
        ingressClassName = "nginx"
        enabled = true
        annotations= merge(
                      local.oauth2_ingress_annotations,
                      {
                        "nginx.ingress.kubernetes.io/configuration-snippet" = <<-EOT
                          proxy_set_header Authorization "Bearer ${var.dashboard_token}";
                        EOT
                      }
                    )
        #annotations = local.oauth2_ingress_annotations
        hosts   = local.k8s_dashboard_hostname
        tls     = { enabled = false }
      }
    }
  })
]

}

resource "kubernetes_cluster_role" "k8s_dashboard_readonly" {
  count = var.enable_cluster_role ? 1 : 0
  metadata {
    name = "k8s-dashboard-readonly"
  }
  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "k8s_dashboard_crb" {
  metadata {
    name = "k8s-dashboard-crb"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.k8s_dashboard_readonly[0].metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      =  "kubernetes-dashboard-2-kong"
    namespace = "default"
  }
}

locals {
  k8s_dashboard_hostname = ["kubernetes.dashboard.com"]
  }
