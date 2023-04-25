# Terraform CDN Module (GCP) 

This is a Terraform module designed to facilitate the instantiation of a Content Delivery Network (CDN) on Google Cloud Platform (GCP). The module creates a URL map, a backend bucket with CDN enabled, a DNS record A pointing to a Global Load Balancer (GCLB), and an automatic certificate creation and management process for your CDN domain e.g. `cdn.yourdomain.com`.

The purpose of this module is to provide users with a simple and effective solution for setting up a CDN in their GCP environment. By automating the setup process, users can focus on the important aspects of their project without having to spend time and resources on CDN configuration.

The module is easy to use and can be quickly customized to meet the specific requirements of your project. Simply specify the name of your GCP project, domain name, managed zone and the module will handle the rest.

Overall, this module is an excellent choice for anyone looking to quickly and easily set up a CDN in their GCP environment. With its comprehensive functionality and user-friendly design, it represents an excellent value for any organization looking to improve the performance and reliability of their web services.

## Flow

- Randomly generated ID resource with a byte length of 8 is used to create unique names for various resources.
- Google Cloud Storage bucket is configured with CORS settings allowing GET, HEAD, and OPTIONS requests from any origin.
- The bucket is created with MULTI_REGIONAL storage class and located in the US region.
- The backend bucket is configured to serve static content through a CDN.
- The URL map maps requests to the backend bucket.
- A managed SSL certificate is created for the domain specified in the configuration.
- The target HTTPS proxy maps requests to the URL map and SSL certificate.
- Global external IP address and global forwarding rule are created to allow the CDN to serve content over HTTPS.
- An IAM policy binding is added to the Google Cloud Storage bucket to allow any user to view the contents of the bucket.

## Usage

To use this module, you need to have a GCP project set up and configured with the necessary permissions. Once you have done that, you can instantiate the module in your Terraform configuration file.

```hcl
module "gcp_cdn" {
  source        = "github.com/pvsousalima/cdn-module-gcp"
  project       = var.project
  domain_name   = var.domain_name
  managed_zone  = var.managed_zone
}
```

Copy your files into the created bucket and access them via `cdn.yourdomain.com/youfile.example`

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | The name of the Google Cloud project to use for resources. | string | n/a | yes |
| domain_name | The domain name to use for the CDN. | string | n/a | yes |
| managed_zone | The name of the Google Cloud DNS managed zone for the domain name. | string | n/a | yes |

## Resources created

```
1. random_id.id
2. google_storage_bucket.cdn_bucket
3. google_compute_backend_bucket.cdn_backend_bucket
4. google_compute_url_map.cdn_url_map
5. google_compute_managed_ssl_certificate.cdn_certificate
6. google_compute_target_https_proxy.cdn_https_proxy
7. google_compute_global_address.cdn_public_address
8. google_compute_global_forwarding_rule.cdn_global_forwarding_rule
9. google_storage_bucket_iam_member.cdn_allusers_reader
```

## Requirements

This module requires Terraform version v1.4.5 or later, as well as the following GCP resources:

- A project with the necessary permissions to create and configure CDN, Storage, DNS, and Load Balancer resources.

## License

This module is released under the MIT License. See the [LICENSE](LICENSE) file for more information.
