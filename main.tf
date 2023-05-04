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
}

resource "random_id" "bucket_prefix" {
  byte_length = 8
}

resource "google_storage_bucket" "bucket" {
  name                        = "${local.project}-ash-gcf-source" # Every bucket name must be globally unique
  location                    = "EU"
  uniform_bucket_level_access = true
  project = "${local.project}"
}

resource "google_storage_bucket_object" "object" {
  name   = "test-http-function.zip"
  bucket = google_storage_bucket.bucket.name
  source = "./functions/testHttpFunction/test-http-function.zip" # Add path to the zipped function source code

}

resource "google_cloudfunctions2_function" "test_http_function" {
  name        = "test_http_function"
  location    = "europe-west2"
  description = "Ash testing a terraform upload"
  project = "${local.project}"

  build_config {
    runtime     = "nodejs18"
    entry_point = "testHttpFunction" # Set the entry point (function name, not file name)
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
}

output "function_uri" {
  value = google_cloudfunctions2_function.test_http_function.service_config[0].uri
}