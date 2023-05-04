terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
}

locals {
  project = "matthew-law-dev"
  region  = "europe-west2"
}

resource "random_id" "bucket_prefix" {
  byte_length = 8
}

resource "google_storage_bucket" "bucket" {
  name                        = "${local.project}-ash-gcf-source"
  location                    = "EU"
  uniform_bucket_level_access = true
  project                     = local.project
}

# resource "google_storage_bucket_object" "object" {
#   name   = "test-http-function.zip"
#   bucket = google_storage_bucket.bucket.name
#   source = "./functions/testHttpFunction/test-http-function.zip"
# }

resource "google_storage_bucket_object" "object" {
  name   = "test-pubsub-functions.zip"
  bucket = google_storage_bucket.bucket.name
  source = "./functions/testPubSubFunctions/test-pubsub-functions.zip"
}

resource "google_pubsub_topic" "topic" {
  name    = "tf-test-topic"
  project = local.project
}

# resource "google_cloudfunctions2_function" "test_http_function" {
#   name        = "test_http_function"
#   location    = "europe-west2"
#   description = "Ash testing a terraform upload"
#   project = local.project

#   build_config {
#     runtime     = "nodejs18"
#     entry_point = "testHttpFunction"
#     source {
#       storage_source {
#         bucket = google_storage_bucket.bucket.name
#         object = google_storage_bucket_object.object.name
#       }
#     }
#   }

#   service_config {
#     max_instance_count = 1
#     available_memory   = "256M"
#     timeout_seconds    = 60
#   }
# }

resource "google_cloudfunctions2_function" "tf_pub_message" {
  name        = "tf_pub_message"
  location    = local.region
  description = "Ash testing a terraform pub message"
  project     = local.project

  build_config {
    runtime     = "nodejs18"
    entry_point = "tfPubMessage"

    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
    environment_variables = {
      TOPIC_NAME: google_pubsub_topic.topic.id
    }
  }
}

resource "google_cloudfunctions2_function" "tf_sub_message" {
  name        = "tf_sub_message"
  location    = local.region
  description = "Ash testing a terraform sub message"
  project     = local.project

  build_config {
    runtime     = "nodejs18"
    entry_point = "tfSubMessage"

    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
  }

  event_trigger {
    trigger_region  = local.region
    event_type      = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic    = google_pubsub_topic.topic.id
    retry_policy    = "RETRY_POLICY_RETRY"
  }
}

output "pub_function_uri" {
  value = google_cloudfunctions2_function.tf_pub_message.service_config[0].uri
}

output "sub_func_id" {
  value = google_cloudfunctions2_function.tf_sub_message.id
}