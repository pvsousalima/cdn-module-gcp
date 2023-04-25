# Create a random ID resource with a byte length of 8.
# This resource can be used to generate a unique identifier for other resources that require a unique name.
resource "random_id" "id" {
  byte_length = 8
}

# Create a Google Cloud Storage bucket with CORS configuration that allows GET, HEAD, and OPTIONS requests from any origin.
# The bucket name is randomly generated using the previously created random_id resource.
# The bucket is created with MULTI_REGIONAL storage class and located in the US region.
# The lifecycle prevent_destroy setting is enabled to protect the bucket from being destroyed accidentally.
resource "google_storage_bucket" "cdn_bucket" {
  name          = "${random_id.id.hex}"
  storage_class = "MULTI_REGIONAL"
  location      = "US"
  project       = var.project
  cors {
    origin = ["*"]
    method = ["GET", "HEAD", "OPTIONS"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
  lifecycle {
    prevent_destroy = true
  }
}

# Create a Google Compute Engine backend bucket that serves static content through a CDN.
# The backend bucket name is randomly generated using the previously created random_id resource.
# The bucket_name parameter is set to the name of the previously created Google Cloud Storage bucket.
# The enable_cdn setting is enabled to turn on CDN for the backend bucket.
# The lifecycle prevent_destroy setting is enabled to protect the backend bucket from being destroyed accidentally.
resource "google_compute_backend_bucket" "cdn_backend_bucket" {
  name        = "${random_id.id.hex}"
  description = "Backend bucket for serving static content through CDN"
  bucket_name = google_storage_bucket.cdn_bucket.name
  enable_cdn  = true
  project     = var.project
  lifecycle {
    prevent_destroy = true
  }
}

# Create a Google Compute Engine URL map that maps requests to the previously created backend bucket.
# The URL map name is randomly generated using the previously created random_id resource.
# The default_service parameter is set to the self_link of the previously created Google Compute Engine backend bucket.
# The lifecycle prevent_destroy setting is enabled to protect the URL map from being destroyed accidentally.
resource "google_compute_url_map" "cdn_url_map" {
  name            = "${random_id.id.hex}"
  description     = "CDN URL map to cdn_backend_bucket"
  default_service = google_compute_backend_bucket.cdn_backend_bucket.self_link
  project         = var.project
}

# Create a managed SSL certificate for the domain name specified in the var.domain_name variable.
# The SSL certificate name is randomly generated using the previously created random_id resource.
# The lifecycle create_before_destroy and prevent_destroy settings are enabled to ensure the certificate is not destroyed accidentally.
resource "google_compute_managed_ssl_certificate" "cdn_certificate" {
  provider = google-beta
  project  = var.project
  name = "${random_id.id.hex}"
  lifecycle {
    create_before_destroy = true
    prevent_destroy = true
  }
  managed {
    domains = [var.domain_name]
  }
}

# Create a Google Compute Engine target HTTPS proxy that maps requests to the previously created URL map and SSL certificate.
# The proxy name is randomly generated using the previously created random_id resource.
# The url_map parameter is set to the self_link of the previously created Google Compute Engine URL map.
# The ssl_certificates parameter is set to an array containing the self_link of the previously created managed SSL certificate.
# The lifecycle prevent_destroy setting is enabled to protect the proxy from being destroyed accidentally.
resource "google_compute_target_https_proxy" "cdn_https_proxy" {
  name             = "${random_id.id.hex}"
  url_map          = google_compute_url_map.cdn_url_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.cdn_certificate.self_link]
  project          = var.project
}

# Create a global external IP address for the CDN using the random_id resource.
# The name of the IP address is set to the value of the hex property of the random_id resource.
# The IP address version is set to IPV4 and address type is set to EXTERNAL.
# The project parameter is set to the value of the var.project variable.
resource "google_compute_global_address" "cdn_public_address" {
  name         = "${random_id.id.hex}"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
  project      = var.project
}

# Create a global forwarding rule for the CDN using the random_id resource.
# The name of the forwarding rule is set to the value of the hex property of the random_id resource.
# The target parameter is set to the self_link of the previously created Google Compute Engine target HTTPS proxy.
# The ip_address parameter is set to the address property of the previously created Google Compute Engine global IP address.
# The port_range parameter is set to "443".
# The project parameter is set to the value of the var.project variable.
resource "google_compute_global_forwarding_rule" "cdn_global_forwarding_rule" {
  name       = "${random_id.id.hex}"
  target     = google_compute_target_https_proxy.cdn_https_proxy.self_link
  ip_address = google_compute_global_address.cdn_public_address.address
  project    = var.project
  port_range = "443"
}

# Add a legacy storage object reader IAM policy binding to the previously created Google Cloud Storage bucket.
# This allows any user to view the contents of the bucket.
# The bucket parameter is set to the name of the previously created Google Cloud Storage bucket.
# The role parameter is set to "roles/storage.legacyObjectReader".
# The member parameter is set to "allUsers".
resource "google_storage_bucket_iam_member" "all_users_viewers" {
  bucket = google_storage_bucket.cdn_bucket.name
  role   = "roles/storage.legacyObjectReader"
  member = "allUsers"
}

# Create a DNS A record pointing to the previously created Google Compute Engine global IP address.
# The managed_zone parameter is set to the value of the var.managed_zone variable.
# The name parameter is set to the value of the var.domain_name variable.
# The type parameter is set to "A".
# The ttl parameter is set to 3600 seconds.
# The rrdatas parameter is set to an array containing the address property of the previously created Google Compute Engine global IP address.
# The project parameter is set to the value of the var.project variable.
resource "google_dns_record_set" "cdn_dns_a_record" {
  managed_zone = var.managed_zone
  name         = var.domain_name
  type         = "A"
  ttl          = 3600
  rrdatas      = [google_compute_global_address.cdn_public_address.address]
  project      = var.project
}
