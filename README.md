# Static S3 Site - Terraform Template
This is a classic example in AWS of using Serverless technologies to host a static website.  

Contained in this project is a Terraform template to 1) Deploy S3 and CloudFront, 2) create the interlinking 
dependencies to allow the services to communicate, 3) uploads HTML files that are located within a static folder from
the project.

If you are starting from a new AWS account, I will outline the process to:
 1) Setup a "Least-Privileged" IAM User
 2) Configure your AWS CLI credentials
 3) Install Terraform

If you already have all of the above setup, you can skip down to the "Executing this project" section below.

##  Getting Started
### IAM (aka Identity and Access Management)
We will be building a hierarchy in the next few steps (IAM User > Belongs to an IAM Group > which is given access to 
do things after being granted access through IAM Policies)  

It is already assumed that you have an AWS account created (if you do not, please refer to 
[this guide](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/)).
1. Log into your AWS Console (Ideally NOT using your "Root" account - 
[learn about this here](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html))
2. Go to Services > Search "IAM" > Click "IAM" (If you already hit an Access Error, go ahead and skim through my next 
steps. They may help you troubleshoot using your Root account to grant additional access)

#### Creating IAM Policy

1. Let's start with the IAM Policy first. This is a definition of "What" someone has access to Create/Read/Update/Delete. 
In our case, we will provide access to 1) S3 and 2) CloudFront.
2. Click "Policies" in the left panel. Then "Create Policy".
3. Click the "JSON" tab, and paste the following in to get started (be sure to update the <update> sections)
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "static_site_deployer",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:CreateBucket",
                "s3:ListBucket",
                "s3:DeleteObject",
                "s3:DeleteBucketPolicy",
                "s3:DeleteBucket",
                "s3:GetBucketPolicy"
            ],
            "Resource": [
                "arn:aws:s3:::<update>",
                "arn:aws:s3:::<update>/*"
            ]
        }
    ]
}
```
4. Provide the policy a name "static_site_deployer"

#### Create IAM Group
You may ask, "If there is only one user, why do we need a group". This construct is a recommendation from AWS. 
It ensures that you're able to add/remove/expand users to allow for new uses.

1. Click "Groups" in the left Panel. Then "Create New Group"
2. Give it a name like "static_site_deployer" here as well. 
3. Search and Check the "static_site_deployer" policy that we just created. Click "Next Step".
4. At the summary page, you should see your Group Name and one policy listed. Click "Create Group"

#### Create IAM User
So far, only having the IAM Policy and Group, there is still no "Entrypoint" for you or I to use this granted access.
In AWS, our "entrypoint" will be an IAM User. These users provide a model where we can add/remove access methods for ourselves.

For Terraform, we need to have access to "AWS Access Keys". You can think of these as API keys that are long-lasting 
(only expiring when you say so). But this opens a door for anyone with these keys to start using them against your AWS Account.
That is why its important to take a "Least-Privilege" approach in Policies, that way if these keys were compromised, 
the blast radius will be smaller than "Administrator" access. 

1. Click "Users" in the left panel. Then "Add user". 
2. Enter a User name like "static_site_deployer", then check "Programmatic access". This can be done later too, if preferred.
3. Click "Next: Permissions". Under the "Add user to group" set, select the "static_site_deployer" group. Click "Next: Tags"
4. No tags are necessary at this point. Click "Next:Review" then "Create user".
5. You now have access to your Access key and Secret Access Key. You can copy these to your password manager of choice, 
or download the CSV to be referrenced later.

### AWS CLI Installation
- TODO

### Terraform Installation
- TODO

# Executing this project
> terraform apply -var-file="example.tfvars" 

