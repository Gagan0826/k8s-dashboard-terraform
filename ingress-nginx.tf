resource "helm_release" "ingress_nginx" {
  count = 0
  timeout    = 600  
  wait       = true
  wait_for_jobs = true
  name          = "ingress-nginx"
  repository    = "https://kubernetes.github.io/ingress-nginx"
  chart         = "ingress-nginx"
  namespace     = "ingress-nginx"
  max_history   = 3
  recreate_pods = true
  version       =  "4.11.0"
  values        = [data.template_file.ingress_nginx.rendered]
  cleanup_on_fail = true
  set {
    name  = "controller.replicaCount"
    value = "2"
  }
}

data "template_file" "ingress_nginx" {
  template = <<EOF

controller:
  image:
    registry: "registry.k8s.io" 
    image: ingress-nginx/controller
    tag: "v1.12.1"
    pullPolicy: "Always"
  extraArgs:
    update-status: "true"
  replicaCount: 3
  allowSnippetAnnotations: "true"

  config:
  ingressClassResource:
    name: nginx
    enabled: true
    default: true
    
EOF
}
