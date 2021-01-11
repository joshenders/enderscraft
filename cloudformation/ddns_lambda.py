import boto3
import logging
from sys import exit

# FIXME: Derive from
HOSTED_ZONE = "${ParameterHostedZone}."
PROJECT_NAME = "${AWS::StackName}"
TTL = 60

log = logging.getLogger()
for h in log.handlers:
    h.setFormatter(logging.Formatter("%(aws_request_id)s [%(levelname)s] %(message)s"))

log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)


def get_ipv4_from_task_arn(arn):
    def _get_eni_from_task_arn(arn):
        ecs = boto3.client("ecs")
        response = ecs.describe_tasks(cluster="fargate", tasks=[arn])
        return (
            response.get("tasks", [dict()])[0]
            .get("attachments", [dict()])[0]
            .get("details", [dict()])[1]
            .get("value")
        )

    def _get_ipv4_from_eni(eni):
        ec2 = boto3.client("ec2")
        response = ec2.describe_network_interfaces(NetworkInterfaceIds=[eni])
        return (
            response.get("NetworkInterfaces", [dict()])[0]
            .get("Association", dict())
            .get("PublicIp")
        )

    eni = _get_eni_from_task_arn(arn)
    return _get_ipv4_from_eni(eni)


def update_record(answer):
    batch = {
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": HOSTED_ZONE,
                    "Type": "A",
                    "TTL": TTL,
                    "ResourceRecords": [
                        {"Value": answer},
                    ],
                },
            },
        ],
    }

    route53 = boto3.client("route53")
    hosted_zones = route53.list_hosted_zones().get("HostedZones", list())
    zone_id = None
    for zone in hosted_zones:
        if zone.get("Name") == HOSTED_ZONE:
            zone_id = zone.get("Id").split("/")[2]
            log.info(f"Found zone_id: '{zone_id}' for '{HOSTED_ZONE}'")

    if not zone_id:
        log.error(f"'{HOSTED_ZONE}' not found in hosted_zones: '{hosted_zones}'")
        exit(1)

    log.info(f"Route53 request: '{batch}'")
    return route53.change_resource_record_sets(HostedZoneId=zone_id, ChangeBatch=batch)


def handler(event, _):
    task_def = event.get("taskDefinitionArn")
    last_status = event.get("lastStatus")
    desired_status = event.get("desiredStatus")

    if PROJECT_NAME not in task_def:
        log.warning(f"Ignored event")
        return
    elif last_status == "RUNNING" and desired_status == "STOPPED":
        log.info(f"Task stop event")
        response = update_record("127.0.0.1")
        log.info(f"Route53 response: '{response}'")
        return
    elif last_status == "RUNNING" and desired_status == "RUNNING":
        log.info(f"Task start event")
        task_arn = event.get("taskArn")
        ipv4_addr = get_ipv4_from_task_arn(task_arn)
        log.info(f"ipv4_addr: '{ipv4_addr}', task_arn: '{task_arn}'")
        response = update_record(ipv4_addr)
        log.info(f"Route53 response: '{response}'")