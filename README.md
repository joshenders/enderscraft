# Enderscraft

[![Python 3.9](https://img.shields.io/badge/python-3.9-blue.svg)](https://www.python.org/downloads/release/python-391/) [![Code style: black](https://img.shields.io/badge/code%20style-black-black.svg)](https://github.com/psf/black) [![code style: prettier](https://img.shields.io/badge/code_style-prettier-ff69b4.svg?style=flat-square)](https://github.com/prettier/prettier) [![License: CC BY-NC 4.0](https://img.shields.io/badge/license-CC%20BY--NC%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc/4.0/)

## About

"Enderscraft" is Minecraft™ repackaged for on-demand serverless computing. Instead of running a server 24/7, run your server on-demand for pennies an hour. Only pay for the hours that you're playing.

### Features (in-progress or planned)

- Supports all mods and versions
- Deploy to any AWS Region
- Scaleable up to 4 vCPU and 30GB RAM
- Launchable via CLI or Discord bot
- Continuous snapshots with restore on resume
- Log/Telemetry streaming for monitoring
- Auto-DNS record creation in custom domain
- Tick fast-forward on resume
- RCON enabled
- Remote Debugging via JMX

### Pricing

Enderscraft is free as in beer but you can expect a bill from AWS roughly inline with the table below.

> **Note:** You may incur slight additional charges for things like: data transfer, log storage, container storage, and backups.

| per vCPU per hour | per GB of RAM per hour |
| ----------------- | ---------------------- |
| $0.01264791       | $0.00138883            |

### Commerical Use

This software is not licensed for commerical use. If you're interested in using this code commercially, please contact: Josh Enders <<josh.enders@gmail.com>>.

## Getting Started

## Installation

Enderscraft is designed to run in AWS on so-called "serverless" infrastructure. To make deployment easier, a CloudFormation template is provided which will automatically create and configure the necessary services in AWS in a secure and cost effective manner.

## AWS Setup

### Dependencies

- [aws-cli](https://github.com/aws/aws-cli)
- [jq](https://stedolan.github.io/jq/)

#### Environment

The following environment variable is required for this section of the setup instructions:

```bash
export PROJECT_NAME="enderscraft"
```

#### Initial AWS CLI Configuration

(Optional) If you haven't already, setup your default (root) account with `aws configure`.

```bash
aws configure
```

You should see output similar to this:

```bash
AWS Access Key ID [********************]:
AWS Secret Access Key [********************]:
Default region name [us-east-1]:
Default output format [None]:
```

After successfully completing this process, you should have a `[default]` section in your `~/.aws/credentials` file.

### CloudFormation

#### Environment

The following environment variables are required for the rest of the setup process.

> **_Note:_** A custom domain isn't a strict requirement but it will make connecting to your game a lot easier, as the public IP address will change on each invocation of a container.

```bash
export AWS_REGION="$(aws configure get 'region')"
export CUSTOM_DOMAIN="example.com"
```

From the root directory of the project, create the CloudFormation stack.

```bash
aws \
    --profile "default" \
    cloudformation create-stack \
        --region "${AWS_REGION}" \
        --template-body "file://cloudformation/public_vpc.cfn.yaml" \
        --stack-name "${PROJECT_NAME}" \
        --parameters "ParameterKey=ParameterHostedZone,ParameterValue=${CUSTOM_DOMAIN}" \
        --capabilities "CAPABILITY_NAMED_IAM"
```

(Optional) It is normal for cloudformation to take a long time. If you'd like some kind of indication of completion, you can run the following command which will block until the stack is available.

```bash
aws cloudformation wait stack-create-complete --stack-name "${PROJECT_NAME}"
```

### DNS

Once the stack has been created, you can run the following command to get the authoritative Route53 nameservers assigned to your domain.

```bash
aws \
    --profile "default" \
        cloudformation describe-stacks \
            --stack-name ${PROJECT_NAME}  \
| jq \
    --raw-output \
        '.Stacks[0] | .Outputs[0].OutputValue, .Outputs[1].OutputValue, .Outputs[2].OutputValue, .Outputs[3].OutputValue'
```

You can now login to your domain registrar's website and delegate your domain to Route53. Instructions on how to do this can be found on your registrar's website.

### IAM Configuration

Create an access key for the `enderscraft` IAM user.

```bash
aws iam create-access-key --user-name "${PROJECT_NAME}"
```

Configure your IAM user with the credentials displayed by the previous step.

> **_Note:_** `Default region name` is personal choice but accept the default when prompted for `Default output format` .

```bash
aws --profile "enderscraft" configure
```

### Container Launch

#### Dependencies

- [fargatecli](https://github.com/awslabs/fargatecli)

#### Environment

The following environment variables are required for the rest of the setup process.

```bash
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity | jq --raw-output '.Account')"
export AWS_SUBNET_ID="$(aws --profile 'default' ec2 describe-subnets --filters "Name=tag:Name,Values=${PROJECT_NAME}-SubnetPublic" | jq --raw-output '.Subnets[0].SubnetId')"
export AWS_SECURITY_GROUP_ID="$(aws --profile 'default' ec2 describe-security-groups --filters "Name=tag:Name,Values=${PROJECT_NAME}-SecurityGroupFargateTasks" | jq --raw-output '.SecurityGroups[0].GroupId')"
```

Containers can be launched with `fargatecli` with the following command.

> **Note:** `--cpu` and `--memory` can be tuned as desired

```bash
AWS_PROFILE="${PROJECT_NAME}" \
fargate task run \
    "${PROJECT_NAME}" \
        --subnet-id "${AWS_SUBNET_ID}" \
        --security-group-id "${AWS_SECURITY_GROUP_ID}" \
        --env "ACCEPT_EULA=yes" \
        --cpu "2048" \
        --memory "4096" \
        --image "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/enderscraft:latest"
```

#### Common ECS Repository Maintenance Tasks

Delete an image by tag:

```bash
aws \
    --profile "default"
        ecr batch-delete-image \
            --repository-name "${PROJECT_NAME}" \
            --image-ids imageTag="latest"
```

Delete an image by digest:

```bash
aws \
    --profile "default"
        ecr batch-delete-image \
            --repository-name "${PROJECT_NAME}" \
            --image-ids imageDigest="sha256:ea38a89e..."
```

## Contributing

### Style

- [black](https://github.com/psf/black)
- [cfn-lint](https://github.com/aws-cloudformation/cfn-python-lint)
- [prettier](https://github.com/prettier/prettier)
- [shellcheck](https://github.com/koalaman/shellcheck)

### Directory structure

```bash
.
├── cloudformation         # AWS CloudFormation files
├── docker                 # Docker files
│   ├── alpine             # WIP Alpine-based containers
│   └── debian             # Debian-based containers
│       ├── base-corretto  # Base layer build context
│       │   └── files      # Base layer root filesystem overlay
│       └── enderscraft    # Minecraft layer build context
│           └── files      # Minecraft layer root filesystem overlay
└── src                    # Build scripts and whatnot
```

## License

This work is licensed under CC BY-NC version 4.0 [https://creativecommons.org/licenses/by-nc/4.0/](https://creativecommons.org/licenses/by-nc/4.0/)
© 2020, Josh Enders. Some Rights Reserved.
