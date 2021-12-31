data "local_file" "masterkey" {
  filename = "../config/master.key"
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = "${var.app-name}"
  }
}

resource "kubernetes_config_map" "config" {
  depends_on = [azurerm_redis_cache.redis, azurerm_postgresql_server.db]

  metadata {
    name = "${var.app-name}-config"
    namespace = "${var.app-name}"
  }

  data = {
    RAILS_MASTER_KEY = data.local_file.masterkey.content
    RAILS_ENV = "production"
    DATABASE_URL = "postgres://${var.postgresql-admin-login}:${var.postgresql-admin-login}@${azurerm_postgresql_server.db.fqdn}"
    REDIS_URL = "redis://:${azurerm_redis_cache.redis.primary_access_key}@${azurerm_redis_cache.redis.hostname}:${azurerm_redis_cache.redis.ssl_port}/0"
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name = "${var.app-name}-app"
    labels = {
      app = "${var.app-name}"
    }
    namespace = "${var.app-name}"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "${var.app-name}"
      }
    }

    template {
      metadata {
        name = "${var.app-name}"
        labels = {
          app = "${var.app-name}"
        }
      }

      spec {
        init_container {
          image = "murny/demo:main"
          image_pull_policy = "Always"
          name = "${var.app-name}-init"
          command = ["rake", "db:migrate"]
          env_from {
            config_map_ref {
              name = "${var.app-name}-config"
            }
          }
        }
        container {
          image = "murny/demo:main"
          image_pull_policy = "Always"
          name = "${var.app-name}"
          port {
            container_port = 3000
          }
          env_from {
            config_map_ref {
              name = "${var.app-name}-config"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "workers" {
  metadata {
    name = "${var.app-name}-workers"
    namespace = "${var.app-name}"

  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "${var.app-name}-workers"
      }
    }

    template {
      metadata {
        name = "${var.app-name}-workers"
        labels = {
          app = "${var.app-name}-workers"
        }
      }

      spec {
        container {
          image = "murny/demo:main"
          name = "${var.app-name}-workers"
          command = ["sidekiq"]
          env_from {
            config_map_ref {
              name = "${var.app-name}-config"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "service" {
  metadata {
    name = "${var.app-name}-service"
    namespace = "${var.app-name}"
  }

  spec {
    port {
      port = 80
      target_port = 3000
    }

    selector = {
      app = "${var.app-name}"
    }
  }
}

resource "kubernetes_ingress" "ingress" {
  wait_for_load_balancer = true
  metadata {
    name = "${var.app-name}-ingress"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
    namespace = "${var.app-name}"
  }
  spec {
    rule {
      host = "murny.tech"
      http {
        path {
          path = "/"
          backend {
            service_name = "${var.app-name}-service"
            service_port = 80
          }
        }
      }
    }
  }
}
