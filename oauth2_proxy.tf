resource "helm_release" "oauth2_proxy" {
  count = 0
  name          = "oauth2-proxy-test"
  repository    =  "https://oauth2-proxy.github.io/manifests"
  chart         = "oauth2-proxy"
  version       =  "7.7.31"
  namespace     = "default"
  max_history   = 3
  recreate_pods = true

  values = [local.oauth2_proxy_values]

  // Adjust the namespace so kiam will permit the required IAM role(s).  At
  // present Helm gives no control over namespace settings; revisit this when
  // Helm v3 is mainstream.
}

data "template_file" "oauth2_proxy" {
  template = <<EOF
extraArgs:
  provider: google
  email-domain: ""
config:
  clientID: ""
  clientSecret: ""
  extraArgs:
    redirect-url: http://kubernetes.dashboard.com/oauth2/callback

alphaConfig:
  injectRequestHeaders:
    Authorization:
      value: "Bearer YOUR_STATIC_TOKEN"

ingress:
  enabled: true
  hosts: [${join(",", local.oauth2_hosts)}]
  path: /oauth2
  tls:
    - hosts: [${join(",", local.oauth2_hosts)}]

authenticatedEmailsFile:
  enabled: true
  restricted_access: |-
    ${join("\n    ", sort(local.oauth2_allowed_users))}
EOF
}


locals {
  oauth2_hosts = concat(["apache.endpoint.com","kubernetes.dashboard.com"])
  oauth2_allowed_users = var.oauth2_allowed_users
  oauth2_proxy_values = sensitive(data.template_file.oauth2_proxy.rendered)
  oauth2_ingress_annotations = {
    "nginx.ingress.kubernetes.io/auth-response-headers" = "Authorization,X-Auth-Request-User,X-Auth-Request-Email"
    # "nginx.ingress.kubernetes.io/auth-signin"           = "http://apache.endpoint.com/oauth2/start?rd=$escaped_request_uri"
    # "nginx.ingress.kubernetes.io/auth-url"              = "http://apache.endpoint.com/oauth2/auth"
    #Remove SSL-related annotations
    #"nginx.ingress.kubernetes.io/backend-protocol"      = "HTTPS"


  }
}

variable "oauth2_allowed_users" {
  description = "List of allowed users for OAuth2 authentication"
  type        = list(string)
  default     = [
    "gagan@gmail.com",
  ]
}