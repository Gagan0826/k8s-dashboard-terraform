resource "kubernetes_config_map" "nginx_dashboard_proxy" {
  count = 1
  metadata {
    name      = "nginx-dashboard-proxy"
    namespace = "default"
  }

  data = {
    "custom_server.conf" = <<-EOT
      server {
        listen 8080;

        location / {
          proxy_pass https://kubernetes-dashboard-test-kong-proxy.default.svc.cluster.local:443;
          proxy_ssl_verify off;

          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;

          proxy_set_header Authorization "Bearer ${data.kubernetes_secret.dashboard_viewer_token_data.data.token}";
        }
      }
    EOT
  }
}
resource "kubernetes_deployment" "nginx_proxy_test_deployment" {
  count       =  1
  metadata {
    name      = "nginx-k8s-dashboard-test-proxy"
    namespace = "default"
    labels = {
      app = "dashboard-proxy-nginx"
    }
  }

  depends_on = [
    kubernetes_config_map.nginx_dashboard_proxy[0],
  ]

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "dashboard-proxy-nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "dashboard-proxy-nginx"
        }
      }
      spec {
        container {
          name  = "nginx"
          image = "bitnami/nginx:1.25.3-debian-11-r4"
          port {
            container_port = 8080
          }
          volume_mount {
            name       = "nginx-config"
            mount_path = "/opt/bitnami/nginx/conf/server_blocks/custom_server.conf"
            sub_path   = "custom_server.conf"
          }
        }
        volume {
          name = "nginx-config"

          config_map {
            name = kubernetes_config_map.nginx_dashboard_proxy[0].metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx_proxy_test_svc" {
  count       =  1
  metadata {
    name      = "nginx-k8s-dashboard-test-proxy-svc"
    namespace = "default"
  }
  depends_on = [
    kubernetes_deployment.nginx_proxy_test_deployment[0]
  ]
  spec {
    selector = {
      app = "dashboard-proxy-nginx"
    }
    port {
      port        = 80
      target_port = 8080
    }
  }
}

resource "kubernetes_secret_v1" "dashboard_viewer_token" {
  metadata {
    name      = "dashboard-viewer-token"
    namespace = "default"
    annotations = {
      "kubernetes.io/service-account.name" = "kubernetes-dashboard-test-kong"
    }
  }

  type = "kubernetes.io/service-account-token"
}

data "kubernetes_secret" "dashboard_viewer_token_data" {
  metadata {
    name      = kubernetes_secret_v1.dashboard_viewer_token.metadata[0].name
    namespace = kubernetes_secret_v1.dashboard_viewer_token.metadata[0].namespace
  }

  depends_on = [kubernetes_secret_v1.dashboard_viewer_token]
}
