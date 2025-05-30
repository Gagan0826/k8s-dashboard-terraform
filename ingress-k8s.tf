resource "kubernetes_ingress_v1" "dashboard_proxy_ingress" {
  metadata {
    name      = "dashboard-proxy-ingress"
    namespace = "default"
    annotations = {
      # nginx.ingress.kubernetes.io/auth-url              = "https://kubernetes.dashboard.com/oauth2/auth"
      # nginx.ingress.kubernetes.io/auth-signin           = "https://kubernetes.dashboard.com/oauth2/start"
      "nginx.ingress.kubernetes.io/auth-response-headers" = "Authorization,X-Auth-Request-User,X-Auth-Request-Email"
      # nginx.ingress.kubernetes.io/backend-protocol      = "HTTP"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "kubernetes.dashboard.com"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "nginx-dashboard-proxy"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
    # tls {
    #   hosts      = ["dashboard.example.com"]
    #   secret_name = "dashboard-tls"
    # }
  }
}
