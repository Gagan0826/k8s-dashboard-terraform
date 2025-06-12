resource "kubernetes_ingress_v1" "dashboard_proxy_ingress" {
  metadata {
    name      = "dashboard-proxy-ingress"
    namespace = "default"
    annotations = {
      # nginx.ingress.kubernetes.io/auth-url              = "https://kubernetes.dashboard.com/oauth2/auth"
      # nginx.ingress.kubernetes.io/auth-signin           = "https://kubernetes.dashboard.com/oauth2/start"
      "nginx.ingress.kubernetes.io/auth-response-headers" = "X-Auth-Request-User,X-Auth-Request-Email"
      # nginx.ingress.kubernetes.io/backend-protocol      = "HTTP"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "kubernetes-test.dashboard.com"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "nginx-k8s-dashboard-test-proxy-svc"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
    tls {
      hosts      = ["kubernetes-test.dashboard.com"]
    }
  }
}
