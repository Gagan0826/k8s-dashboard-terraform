resource "kubernetes_config_map" "nginx_dashboard_proxy" {
  metadata {
    name      = "nginx-dashboard-proxy"
    namespace = "default"
  }

  data = {
    "custom_server.conf" = <<-EOT
      server {
        listen 8080;

        location / {
          proxy_pass https://kubernetes-dashboard-kong-proxy.default.svc.cluster.local:443;
          proxy_ssl_verify off;

          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;

          proxy_set_header Authorization "Bearer ${var.dashboard_token}";
        }
      }
    EOT
  }
}
resource "helm_release" "nginx_proxy" {
  name       = "nginx-dashboard-proxy"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx"
  namespace  = "default"
  version    = "15.10.0"
    depends_on = [
    helm_release.k8s_dashboard,
  ]

  values = [
    <<-EOT
      containerPorts:
        http: 8080

      service:
        type: ClusterIP
        port: 80
        targetPort:
          http: 8080

      extraVolumeMounts:
        - name: custom-nginx-config
          mountPath: /opt/bitnami/nginx/conf/server_blocks/custom_server.conf
          subPath: custom_server.conf

      extraVolumes:
        - name: custom-nginx-config
          configMap:
            name: ${kubernetes_config_map.nginx_dashboard_proxy.metadata[0].name}
    EOT
  ]
}