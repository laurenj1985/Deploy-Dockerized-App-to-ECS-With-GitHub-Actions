# Deploy-Dockerized-App-to-ECS-With-GitHub-Actions

The goal of this project was to get more familiar with and document the process of working with ECS and ECR. The application was a simple flask python app that opens to a page "Hello from ECS!". I decided to use Python instead of JavaScript just because I am more familiar with it.

I usec in this project:
1. Docker
2. Python Flask
3. AWS ECS with Fargate
4. ECR (Elastic Container Registry)
5. GitHub Actions (CI/CD)

I built a web app, pushed the image to Amazon ECR, deployed it to AWS ECS (Fargate), and automated the whole workflow with GitHub Actions. The app was accessible via ECS endpoint and behind a load-balancer.

Although I did not use Terraform to build the application, I did build 90% of the infrastructure on the command line on a local Ubuntu server.

**Please also note all account information and secrets/passwords have been changed for security purposes.

Key Points:
1. I used export variable commands a good amount to save time, but there were certain instances where I had to hard-code the resources, because the variable may have included spaces or had another issue that caused syntax problems.
2. I had to review my task definition file couple times to modify. What I thought would be sufficient with my configuration for the app, had to be changed to accomodate like the executionRoleArn, environment variable use, and protocol specification.
3. If something is not working, there is a high chance that it's a networking issue or a permissions issue.
