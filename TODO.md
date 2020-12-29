# enderscraft

## AWS Configuration

```
aws ec2 modify-subnet-attribute --map-public-ip-on-launch --subnet-id <subnet-aaaaaaaaaaaaaaaaa>
```

### Dependencies

- [aws-cli](https://github.com/aws/aws-cli)
- [jq](https://stedolan.github.io/jq/)

This guide assumes you do not have an AWS account configured.

1. (Optional) Setup your default (root) account with `aws configure`

   ```bash
   aws configure
   ```

   After successfully completing this process, you should have a `[default]` section in your `~/.aws/credentials` file.

### IAM Configuration

1. FIXME: do this programatically

2. Create a new IAM group, user, and attach the managed policy: `AmazonEC2ContainerRegistryPowerUser` and custom IAM policy ...

3. Configure your user credentials. When prompted for `Default output format` leave that at default.

   ```bash
   aws --profile "enderscraft" configure
   ```

### Environment

The follow environment is required for the rest of the setup process:

```bash
export PROJECT_NAME="enderscraft"
export AWS_REGION="$(aws configure get region)"
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity | jq --raw-output '.Account')"

export AWS_PAGER="cat"
export AWS_PROFILE=default
```

### VPC Creation

1. If you do not already have a VPC you must create one.

```bash
aws \
    ec2 create-vpc \
        --cidr-block "10.0.0.0/24" \
| tee \
    /dev/tty \
| jq \
    --raw-output ".Vpc.VpcId" \
| xargs \
		-I '{}'
    		aws \
        		--profile "default" \
            		ec2 create-tags \
                		--tags "Key=Name,Value=${PROJECT_NAME}" \
                		--resources '{}'
```

The follow environment update is required for the rest of the process:

```bash
export AWS_VPC_ID="$(aws --profile 'default' ec2 describe-vpcs --filters 'Name=tag:aws:cloudformation:stack-name,Values=${PROJECT_NAME}' | jq --raw-output '.Vpcs[0].VpcId')"
```

2. If you do not already have a subnet, you must create a subnet for your fargate tasks.

```bash
aws \
    ec2 create-subnet \
        --cidr-block "10.0.0.0/24" \
        --vpc-id "${AWS_VPC_ID}" \
| tee \
    /dev/tty \
| jq \
    --raw-outout \
    		'.Subnet.SubnetId' \
| xargs \
    -I '{}' \
        aws \
            --profile "default" \
                ec2 create-tags \
                    --tags "Key=Name,Value=${PROJECT_NAME}" \
                    --resources '{}'
```

The follow environment update is required for the rest of the process:

```bash
export AWS_SUBNET_ID="$(aws --profile 'default' ec2 describe-subnets --filters "Name=tag:aws:cloudformation:stack-name,Values=${PROJECT_NAME}" | jq --raw-output '.Subnets[0].SubnetId')"
export AWS_SECURITY_GROUP_ID="$(aws --profile 'default' ec2 describe-security-groups --filters Name=vpc-id,Values=${AWS_VPC_ID} | jq --raw-output '.SecurityGroups[0].GroupId')"
```

3. Create and attach Internet Gateway

```bash
aws \
    ec2 create-internet-gateway \
| tee \
		/dev/tty \
| jq \
		--raw-output \
				'.InternetGateway.InternetGatewayId' \
| xargs \
		-I '{}' \
				aws ec2 \
						attach-internet-gateway \
								--internet-gateway-id '{}' \
								--vpc-id "${AWS_VPC_ID}"
```



```bash
aws \
		ec2 create-security-group \
				--description "Security group for Fargate tasks" \
				--group-name "${PROJECT_NAME}" \
				--vpc-id "${AWS_VPC_ID}"
```

### Repository Configuration

FIXME: push user?

1. (Once) Create a repository using the default (root) account.

   ```bash
   aws \
   		ecr create-repository \
   		    --repository-name "${PROJECT_NAME}" \
   		    --image-scanning-configuration "scanOnPush=true" \
           --region "${AWS_REGION}"
   ```
   
2. Login to ECR

   ```bash
   aws \
   		ecr get-login-password \
      			--region "${AWS_REGION}" \
   | docker login \
       --username "AWS" \
       --password-stdin \
       		"${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
   ```
   
3. Tag your image for ECR

   ```bash
   docker tag \
   		"${PROJECT_NAME}:latest" \
   		"${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}:latest"
   ```

4. Push image to ECR

   ```bash
   docker push "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}:latest"
   ```

#### Repository Maintenance

- Delete an image by tag:

```bash
aws \
		ecr batch-delete-image \
    		--repository-name "${PROJECT_NAME}" \
      	--image-ids imageTag="latest"
```

- Delete an image by digest:

```bash
aws \
		ecr batch-delete-image \
				--repository-name "${PROJECT_NAME}" \
      	--image-ids imageDigest="sha256:ea38a89e..."
```

- Delete a repository:

```bash
aws \
		ecr delete-repository \
    		--repository-name "${PROJECT_NAME}" \
      	--force
```

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:BatchGetImage",
        "ecr:GetLifecyclePolicy",
        "ecr:GetLifecyclePolicyPreview",
        "ecr:ListTagsForResource",
        "ecr:DescribeImageScanFindings",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "*"
    }
  ]
}
```



### Container Launch

#### Dependencies:

- [fargatecli](https://github.com/awslabs/fargatecli)

```bash
AWS_PROFILE=${PROJECT_NAME} \
fargate task run \
		enderscraft \
				--subnet-id "${AWS_SUBNET_ID}" \
				--security-group-id "${AWS_SECURITY_GROUP_ID}" \
				--env "ACCEPT_EULA=yes" \
				--cpu "2048" \
				--memory "4096" \
				--image "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/enderscraft:latest"
```

## Directory structure

```
docker/
```

## Java Version

Provide mechanism to select JVM

- Coretto
- OpenJDK
- Oracle Java

## Tasks

- Fix docker container
  - Remove bad opinions from upstream docker container
  - Layer in mods (computercraft, etc)
  - Layer in custom configuration
- Travis? pipeline to build forked docker container
  - build
  - test
  - push to ECS
- Fargate container launch
  - Either cloudformation or fargate cli https://github.com/awslabs/fargatecli
      - create registry with policyi
  - IAM
- Custom scripts
  - docker healthcheck
  - docker entrypoint
    - https://aikar.co/2018/07/02/tuning-the-jvm-g1gc-garbage-collector-flags-for-minecraft/
  - Sleep 30 mins after last player disconnects
  - monitor
  - DNS
  - Restore from S3 on startup
  - Snapshot backup to S3 every 5 min
    - via rcon https://minecraft.gamepedia.com/Commands/save
    - By default it auto-saves every 6,000 ticks (5 minutes)
    - COW snapshot of the underlying storage
  - tickrate advance after wake?
- Discord Bot (matt?)
  - !start and !status
  - https://www.digitalocean.com/community/tutorials/how-to-build-a-discord-bot-with-node-js
  - https://github.com/getify/You-Dont-Know-JS
- rcon
  - https://github.com/conqp/mcipc
  - https://github.com/itzg/rcon-cli
- crack the client (for the lolz)

| per vCPU per hour | per GB per hour |
| ----------------- | --------------- |
| $0.01264791       | $0.00138883     |

$9.24/mo per vCPU and $1.01/mo per GB of RAM per month of usage
