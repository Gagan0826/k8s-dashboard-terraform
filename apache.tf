resource "helm_release" "testing_appache_app" {
  name             = "apache-app"
  count =  0
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "apache"
  namespace        = "default"
  version          = "10.5.1"
  max_history      = 3
  recreate_pods    = true
  values           = [data.template_file.testing_apache.rendered]
}
data "template_file" "testing_apache" {
  template = <<EOF
ingress:
  enabled: true
  ingressClassName: "nginx"
  hostname: "apache.endpoint.com"
  annotations:
    nginx.ingress.kubernetes.io/auth-response-headers: "X-Auth-Request-User,X-Auth-Request-Email"
    nginx.ingress.kubernetes.io/auth-url: "http://apache.endpoint.com/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "http://apache.endpoint.com/oauth2/start?rd=\\$escaped_request_uri"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
EOF
}