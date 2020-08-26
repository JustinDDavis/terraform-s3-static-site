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

Let's start with the IAM Policies first. This is a definition of "What" someone has access to Create/Read/Update/Delete. 
In our case, we will provide access to 1) S3 and 2) CloudFront.

##### CloudFront Policy
1. Click "Policies" in the left panel. Then "Create Policy".
2. Click the "JSON" tab, and paste the following in to get started
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "cloudfront:TagResource",
                "cloudfront:DeleteCloudFrontOriginAccessIdentity",
                "cloudfront:UpdateCloudFrontOriginAccessIdentity",
                "cloudfront:UpdateDistribution",
                "cloudfront:CreateDistribution",
                "cloudfront:DeleteDistribution",
                "cloudfront:UntagResource",
                "cloudfront:CreateCloudFrontOriginAccessIdentity"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "cloudfront:Get*",
                "cloudfront:List*"
            ],
            "Resource": [
                "arn:aws:cloudfront::*:distribution/*",
                "arn:aws:cloudfront::*:origin-access-identity/*",
                "arn:aws:cloudfront::*:streaming-distribution/*"
            ]
        }
    ]
}
```
4. Provide the policy a name "static_site_deployer_cloudfront"

Note: There is additional opportunity to limit this even more by working with the wildcards. For getting started, this is still a good start. 

##### S3 Policy
1. If not already in the policy section, click "Policies" in the left panel. Then "Create Policy".
2. Click the "JSON" tab, and paste the following in to get started (be sure to update the <update> section with the value you're going to use for your site_project_name)

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:GetAccessPoint",
                "s3:ListAccessPoints",
                "s3:ListJobs",
                "s3:GetAccountPublicAccessBlock",
                "s3:HeadBucket"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "s3:DeleteBucketWebsite",
                "s3:PutBucketWebsite",
                "s3:PutBucketAcl",
                "s3:PutBucketPolicy",
                "s3:CreateBucket",
                "s3:ListBucket",
                "s3:DeleteBucketPolicy",
                "s3:DeleteBucket"
            ],
            "Resource": "arn:aws:s3:::<update>"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::<update>/*"
        },
        {
            "Sid": "VisualEditor3",
            "Effect": "Allow",
            "Action": "s3:Get*",
            "Resource": [
                "arn:aws:s3:::<update>",
                "arn:aws:s3:::<update>/*",
                "arn:aws:s3::*:job/*",
                "arn:aws:s3::*:accesspoint/*"
            ]
        }
    ]
}
```
3. Provide the policy a name "static_site_deployer_s3"

#### Create IAM Group
You may ask, "If there is only one user, why do we need a group". This construct is a recommendation from AWS. 
It ensures that you're able to add/remove/expand users to allow for new uses.

1. Click "Groups" in the left Panel. Then "Create New Group"
2. Give it a name like "static_site_deployer" here as well. 
3. Search and Check the "static_site_deployer_cloudfront" and "static_site_deployer_s3" policies that we just created. Click "Next Step".
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
#### Options to interact with AWS
To interact with AWS, there are generally 3 options. 
1) Web Console (Which we've been using so far)
2) AWS CLI (A command line interface that will need setup for us to continue)
3) SDKs (libraries) to use with your favorite programming langauges.

#### AWS CLI Installation Resource
For Terraform to execute on your local machine, we need to configure the AWS CLI. This will vary by your local
operating system, but you should be able to find your necessary 
[resources here](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html). 

#### Testing that you can access the CLI
You should get to to a point where you can type in your terminal or command prompt the command "aws".   
For me, the biggest hiccup I see is if you get a "command not recoganized" type of message. If the installation
succeeded, you may need to either restart your terminal or command prompt window, and/or update/modify your System's 
PATH environment variable.  

If you're not familiar with PATH, this is a list of all the directories that your computer 
will scan on a new window launch of a terminal or command prompt. It will make any executable files then accessible, 
like in our case the "aws" executable.

#### Adding your AWS Access Key and Secret Key
Once you have the "aws" command available, we need to add our keys. 

From your terminal window, type and fill out the dialogs: 
```
> aws configure --profile static_site_deployer
> AWS Access Key ID [None]: # Enter your Access key provided from your IAM User
> AWS Secret Access Key [None]: # Enter your Secret key provided from your IAM User
> Default region name [None]: us-east-1 # (I'm choosing to use this region. Just be sure to be consistent to whatever region you choose)
> Default output format [None]: # You can just use the None option by pressing Enter
``` 

So what's with the "--profile" option? When you use the AWS CLI on your computer, there is a file likely generated at 
"~/.aws". Within that single file, you can end up with many different credentials to many different accounts.
By using an explict profile option, this make sure your keys are not dropped into the "default" position. If your 
keys do end up in Default, any command you execute without providing a "--profile" option will use those default keys.

By getting into the habit of using explict keys, this will help avoid some mistakes like deploying to a wrong account or 
overriding production.

### Terraform Installation
Terraform comes as a single exeutable. This executable will need to be downloaded, (optionally) added to an executable 
tools folder, and have that folder added to your System's PATH environment variable. 

[Terraform Installation Resource](https://learn.hashicorp.com/tutorials/terraform/install-cli)

After adding the executable, you should be able to now execute "terraform" successfully from directory selected from 
your terminal.

# Executing this project

## Cloning project to your local machine.
> git clone <github_ssh_or_https>

## Copy and update the "example.tfvars"
The tfvars file will be your configuration for the AWS assets. The site_project_name will need to be globally unique, 
because it does generate the S3 bucket which requires a unique name. If someone else in the world has named their bucket
the same, you won't be able to use that name.

## Make sure Terraform is using the correct AWS Profile
Terraform surprisingly doesn't make it easy to select local profiles. I'm surprised by this, because there is a high
risk that someone might commit sensitive credentials into Git if they don't just follow the Profile approach.

You'll need to update your "AWS_PROFILE" environment variable to match the profile name you specified above.
Mac/Linux:
> export AWS_PROFILE="static_site_deployer"
Windows Powershell: 
> $env:AWS_PROFILE="static_site_deployer"

## Commands to deploy resources

To preview what is about to happen in your account, you can use the "plan" functionality. 
> terraform plan -var-file="example.tfvars" 

If the plan looks good, you can then move onto deploying. It will print the same information is plan, but this time you'll be prompted for a Yes/No before the changes will be deployed to the account.
> terraform apply -var-file="example.tfvars" 

