# IAM POLICY REQUIRED FOR RESOURCES INCLUDED:
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "VisualEditor0",
#             "Effect": "Allow",
#             "Action": [
#                 "s3:DeleteBucketWebsite",
#                 "s3:PutBucketWebsite",
#                 "s3:PutBucketAcl",
#                 "s3:CreateBucket",
#                 "s3:ListBucket",
#                 "s3:DeleteBucket"
#             ],
#             "Resource": "arn:aws:s3:::<BUCKET>"
#         },
#         {
#             "Sid": "",
#             "Effect": "Allow",
#             "Action": [
#                 "s3:PutObject",
#                 "s3:Get*",
#                 "s3:DeleteObject"
#             ],
#             "Resource": "arn:aws:s3:::<BUCKET>/*"
#         },
#         {
#             "Sid": "VisualEditor1",
#             "Effect": "Allow",
#             "Action": [
#                 "s3:GetAccessPoint",
#                 "s3:GetAccountPublicAccessBlock",
#                 "s3:ListAccessPoints",
#                 "s3:ListJobs",
#                 "s3:HeadBucket"
#             ],
#             "Resource": "*"
#         },
#         {
#             "Sid": "VisualEditor2",
#             "Effect": "Allow",
#             "Action": [
#                 "s3:Get*",
#                 "s3:PutBucketPolicy",
#                 "s3:DeleteBucketPolicy"
#             ],
#             "Resource": "arn:aws:s3:::<BUCKET>"
#         }
#     ]
# }
resource "aws_s3_bucket" "site_asset_storage" {
  bucket  = var.site_project_name

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_policy" "site_asset_bucket_policy" {
  bucket = aws_s3_bucket.site_asset_storage.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site_asset_storage.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
}

# # Sync artifact to s3 bucket
resource "aws_s3_bucket_object" "site_asset_uploads" {
  for_each = fileset("./${var.local_static_asset_directory}", "*")

  bucket = var.site_project_name
  key    = each.value
  source = "./${var.local_static_asset_directory}/${each.value}"
  # etag makes the file update when it changes; see https://stackoverflow.com/questions/56107258/terraform-upload-file-to-s3-on-every-apply
  etag   = filemd5("./${var.local_static_asset_directory}/${each.value}")
  content_type  = "text/html"

  depends_on = [
    aws_s3_bucket.site_asset_storage
  ]
}
