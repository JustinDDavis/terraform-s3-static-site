resource "aws_s3_bucket" "site_bucket" {
  bucket  = var.name

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.site_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
}

# Sync artifact to s3 bucket
resource "aws_s3_bucket_object" "dist" {
  for_each = fileset("./static_site", "*")

  bucket = var.name
  key    = each.value
  source = "./static_site/${each.value}"
  # etag makes the file update when it changes; see https://stackoverflow.com/questions/56107258/terraform-upload-file-to-s3-on-every-apply
  etag   = filemd5("./static_site/${each.value}")
  content_type  = "text/html"
}
