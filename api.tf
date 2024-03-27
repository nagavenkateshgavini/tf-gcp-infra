resource "google_project_service" "all" {
  for_each = toset([
      "compute.googleapis.com",
      "servicenetworking.googleapis.com",
      "cloudbuild.googleapis.com",
      "cloudfunctions.googleapis.com",
      "logging.googleapis.com",
      "pubsub.googleapis.com",
      "eventarc.googleapis.com",
      "run.googleapis.com"
    ])
  service = each.key
  disable_on_destroy = false
}
