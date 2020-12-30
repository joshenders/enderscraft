# enderscraft

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
  - Either cloudformation or fargate cli <https://github.com/awslabs/fargatecli>
    - -create registry with policy-
  - IAM
- Custom scripts
  - docker healthcheck
  - docker entrypoint
    - <https://aikar.co/2018/07/02/tuning-the-jvm-g1gc-garbage-collector-flags-for-minecraft/>
  - Sleep 30 mins after last player disconnects
  - monitor
  - DNS update 60 seconds
  - Restore from S3 on startup
  - Snapshot backup to S3 every 5 min
    - via rcon <https://minecraft.gamepedia.com/Commands/save>
    - By default it auto-saves every 6,000 ticks (5 minutes)
    - COW snapshot of the underlying storage
  - tickrate advance after wake?
- Discord Bot (matt?)
  - !start and !status
  - <https://www.digitalocean.com/community/tutorials/how-to-build-a-discord-bot-with-node-js>
  - <https://github.com/getify/You-Dont-Know-JS>
- rcon
  - <https://github.com/conqp/mcipc>
  - <https://github.com/itzg/rcon-cli>

| per vCPU per hour | per GB per hour |
| ----------------- | --------------- |
| $0.01264791       | $0.00138883     |

$9.24/mo per vCPU and $1.01/mo per GB of RAM per month of usage

TODO: ECR push role account?

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

