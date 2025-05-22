#authenticating Docker
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 730335519137.dkr.ecr.us-east-1.amazonaws.com

#creating ECR repo
aws ecr create-repository --repository-name ecs-docker-ci

#building and pushing (after setting up environment variables)
docker build -t $ECR_REPO_NAME .
docker tag $ECR_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG
aws ecr list-images --repository-name $ECR_REPO_NAME

#create ecs cluster
aws ecs create-cluster --cluster-name $CLUSTER_NAME

#creating security group that allowed port 3000
aws ec2 create-security-group \
  --group-name ecs-demo-sg \
  --description "Allow port 3000" \
  --vpc-id $VPC_ID

#get sg id
SG_ID=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values=ecs-demo-sg \
  --query "SecurityGroups[0].GroupId" --output text)

#open port 3000
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 3000 \
  --cidr 0.0.0.0/0

#create role for fargate
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file://ecs-trust-policy.json

#attach managed policy
aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

#register task definition
aws ecs register-task-definition \
  --cli-input-json file://ecs-task-definition.json

#get subnets
SUBNETS=$(aws ec2 describe-subnets \
  --filters "Name=default-for-az,Values=true" \
  --query "Subnets[*].SubnetId" --output text)

#create alb
aws elbv2 create-load-balancer \
  --name demo-alb \
  --subnets $SUBNETS \
  --security-groups $SG_ID \
  --scheme internet-facing \
  --type application

#create target group
aws elbv2 create-target-group \
  --name demo-targets \
  --protocol HTTP \
  --port $CONTAINER_PORT \
  --vpc-id $VPC_ID \
  --target-type ip

#get target group arn
TG_ARN=$(aws elbv2 describe-target-groups \
  --names demo-targets \
  --query "TargetGroups[0].TargetGroupArn" --output text)

#create listener
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --names demo-alb \
  --query "LoadBalancers[0].LoadBalancerArn" --output text)

aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN

#create fargate ecs service
aws ecs create-service \
  --cluster $CLUSTER_NAME \
  --service-name $SERVICE_NAME \
  --task-definition $TASK_NAME \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[\"subnet-0d0f2a6af2fb9f17e\",\"subnet-02a2559d2b72115da\",\"subnet-0752ef344f1c97279\",\"subnet-06fd707d102a59603\",\"subnet-01014169409b4f444\",\"subnet-035c9c99332b484a8\"],securityGroups=[$SG_ID],assignPublicIp=\"ENABLED\"}" \
  --load-balancers "targetGroupArn=$TG_ARN,containerName=ecs-docker-ci,containerPort=$CONTAINER_PORT" \
  --desired-count 1
