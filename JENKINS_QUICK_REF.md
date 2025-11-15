# Jenkins Pipeline Quick Reference

## Quick Start

### 1. Add Jenkins Credentials (5 required)
```
Jenkins > Credentials > Global > Add Credential

1. docker-username (Username with password)
2. docker-password (Secret text)
3. aws-access-key-id (Secret text)
4. aws-secret-access-key (Secret text)
5. ec2-ssh-private-key (Secret text)
```

### 2. Create Jenkins Pipeline Job
```
New Item > Pipeline > OK

Configure:
  - GitHub project: https://github.com/Thanu10ekoon/DevOps_VoteX
  - Build Triggers: Poll SCM (H/5 * * * *)
  - Pipeline:
    - Definition: Pipeline script from SCM
    - SCM: Git
    - Repository: https://github.com/Thanu10ekoon/DevOps_VoteX.git
    - Branch: */main
    - Script Path: Jenkinsfile
```

### 3. Run Pipeline
```
Click "Build Now" or push to main branch
```

## Pipeline Stages Overview

| Stage | Purpose | GitHub Actions Equivalent |
|-------|---------|---------------------------|
| Checkout Code | Clone repo | `actions/checkout@v4` |
| Setup Docker Buildx | Multi-platform builds | `docker/setup-buildx-action@v3` |
| Login to Docker Hub | Registry auth | `docker/login-action@v3` |
| Build Client Image | Build frontend | `docker/build-push-action@v5` |
| Build Server Image | Build backend | `docker/build-push-action@v5` |
| Configure AWS | Setup AWS CLI | `aws-actions/configure-aws-credentials@v4` |
| Get EC2 IP | Find instance | AWS CLI command |
| Setup SSH | Configure access | Shell commands |
| Install Ansible | Deploy tool | apt-get install |
| Install Docker Collection | Ansible modules | ansible-galaxy |
| Create Inventory | Target hosts | echo commands |
| Update Compose | Image refs | sed commands |
| Deploy Ansible | Execute deployment | ansible-playbook |
| Summary | Display info | echo commands |

## Jenkins vs GitHub Actions Mapping

### Secrets/Credentials
```yaml
# GitHub Actions
${{ secrets.DOCKER_USERNAME }}

# Jenkins
${DOCKER_USERNAME}  (from credentials)
```

### Checkout
```yaml
# GitHub Actions
- uses: actions/checkout@v4

# Jenkins
stage('Checkout Code') {
    steps {
        checkout scm
    }
}
```

### Docker Build
```yaml
# GitHub Actions
- uses: docker/build-push-action@v5
  with:
    context: ./client
    push: true
    tags: user/votex-client:latest

# Jenkins
sh '''
    docker buildx build \
        --push \
        --file ./client/Dockerfile \
        --tag ${DOCKER_USERNAME}/votex-client:latest \
        ./client
'''
```

### Environment Variables
```yaml
# GitHub Actions
env:
  AWS_REGION: eu-west-1

# Jenkins
environment {
    AWS_REGION = 'eu-west-1'
}
```

### Conditional Steps
```yaml
# GitHub Actions
if: success()

# Jenkins
when {
    expression { currentBuild.result == null }
}
```

## Credential IDs Reference

| Credential ID | Type | Used For |
|--------------|------|----------|
| `docker-username` | Username/Password | Docker Hub login |
| `docker-password` | Secret Text | Docker Hub password |
| `aws-access-key-id` | Secret Text | AWS authentication |
| `aws-secret-access-key` | Secret Text | AWS authentication |
| `ec2-ssh-private-key` | Secret Text | EC2 SSH access |

## Common Jenkins Commands

### Trigger Build
```bash
# Via Jenkins CLI
java -jar jenkins-cli.jar -s http://localhost:8080/ build VoteX-Deploy-Pipeline

# Via API
curl -X POST http://localhost:8080/job/VoteX-Deploy-Pipeline/build \
  --user username:token
```

### View Build Log
```bash
# Via Jenkins CLI
java -jar jenkins-cli.jar -s http://localhost:8080/ console VoteX-Deploy-Pipeline

# Via browser
http://localhost:8080/job/VoteX-Deploy-Pipeline/lastBuild/console
```

## Troubleshooting Checklist

- [ ] All 5 credentials configured in Jenkins
- [ ] Docker installed on Jenkins agent
- [ ] Jenkins user in docker group
- [ ] AWS CLI installed
- [ ] Git installed
- [ ] Correct GitHub repository URL
- [ ] Branch name is 'main'
- [ ] EC2 instance tagged as 'votex-server'
- [ ] EC2 security group allows SSH from Jenkins
- [ ] Docker Hub credentials valid
- [ ] AWS credentials have EC2 permissions

## Test Individual Stages

### Test Docker Build Locally
```bash
docker buildx build -t test/votex-client:latest ./client
docker buildx build -t test/votex-server:latest ./server
```

### Test AWS Access
```bash
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
aws ec2 describe-instances --region eu-west-1
```

### Test SSH Connection
```bash
ssh -i ~/.ssh/votex_key ubuntu@EC2_IP
```

### Test Ansible Connection
```bash
ansible -i ansible/inventory votex_servers -m ping
```

## Performance Tips

1. **Use Docker Build Cache**: Already configured in Jenkinsfile
2. **Parallel Stages**: Consider parallelizing client/server builds
3. **Agent Labels**: Use specific agents for Docker builds
4. **Workspace Cleanup**: Enable workspace cleanup plugin
5. **Artifact Retention**: Limit builds to keep (set to 10)

## Email Notification Setup

### Gmail Configuration
```groovy
// Jenkins System Configuration
SMTP server: smtp.gmail.com
Port: 587
Use TLS: true
Username: your-email@gmail.com
Password: App Password (not regular password)
```

### Generate Gmail App Password
```
1. Google Account > Security
2. 2-Step Verification (enable if not enabled)
3. App passwords
4. Select "Mail" and "Other (Custom name)"
5. Generate and copy password
```

## Monitoring URLs

After successful deployment:
- **Frontend**: `http://EC2_IP:3000`
- **Backend API**: `http://EC2_IP:4000`
- **Health Check**: `http://EC2_IP:4000/api/health`
- **Docker Hub Client**: `https://hub.docker.com/r/USERNAME/votex-client`
- **Docker Hub Server**: `https://hub.docker.com/r/USERNAME/votex-server`

## Build Parameters (Optional Enhancement)

Add these parameters to make pipeline more flexible:

```groovy
parameters {
    choice(
        name: 'ENVIRONMENT',
        choices: ['production', 'staging', 'development'],
        description: 'Deployment environment'
    )
    booleanParam(
        name: 'SKIP_TESTS',
        defaultValue: false,
        description: 'Skip test execution'
    )
    string(
        name: 'DOCKER_TAG',
        defaultValue: 'latest',
        description: 'Docker image tag'
    )
}
```

## Jenkins Pipeline Best Practices

1. ✅ Use `environment {}` for global variables
2. ✅ Use `script {}` for complex Groovy logic
3. ✅ Always clean up in `post` block
4. ✅ Use `credentials()` for sensitive data
5. ✅ Add meaningful stage names
6. ✅ Include error handling with `try-catch`
7. ✅ Use `echo` for debugging
8. ✅ Archive artifacts when needed
9. ✅ Set build descriptions
10. ✅ Send notifications on failure

## Differences from GitHub Actions

| Aspect | GitHub Actions | Jenkins |
|--------|----------------|---------|
| **Execution** | Cloud runners | Self-hosted agent |
| **Cost** | Limited free tier | Free (hosting cost only) |
| **Flexibility** | Predefined actions | Full control |
| **Setup** | Minimal | Requires server setup |
| **Maintenance** | Managed by GitHub | Self-maintained |
| **Integration** | Native GitHub | Webhook needed |
| **Secrets** | GitHub UI | Jenkins UI |
| **Logs** | GitHub interface | Jenkins interface |
| **Artifacts** | GitHub storage | Jenkins storage |
| **Caching** | GitHub cache | Docker cache |

## Next Steps

1. Test the pipeline with a test commit
2. Monitor the first few builds
3. Configure email notifications
4. Set up GitHub webhook
5. Add health checks
6. Implement rollback strategy
7. Add automated tests
8. Configure build badges
9. Document custom modifications
10. Train team on Jenkins usage

## Support Links

- **Jenkins**: http://localhost:8080
- **Repository**: https://github.com/Thanu10ekoon/DevOps_VoteX
- **Docker Hub**: https://hub.docker.com
- **AWS Console**: https://console.aws.amazon.com
