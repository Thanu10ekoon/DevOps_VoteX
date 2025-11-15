# GitHub Actions vs Jenkins Pipeline - Side by Side Comparison

## Pipeline Architecture

### GitHub Actions (`.github/workflows/deploy.yml`)
```yaml
name: Deploy VoteX to AWS

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps: [...]
  
  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    steps: [...]
```

### Jenkins (`Jenkinsfile`)
```groovy
pipeline {
    agent any
    
    environment { ... }
    
    stages {
        stage('Build and Push') { ... }
        stage('Deploy') { ... }
    }
    
    post {
        always { ... }
        success { ... }
        failure { ... }
    }
}
```

---

## Stage-by-Stage Comparison

### 1. Code Checkout

#### GitHub Actions
```yaml
- name: Checkout code
  uses: actions/checkout@v4
```

#### Jenkins
```groovy
stage('Checkout Code') {
    steps {
        echo 'Checking out code from repository...'
        checkout scm
    }
}
```

---

### 2. Docker Buildx Setup

#### GitHub Actions
```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3
```

#### Jenkins
```groovy
stage('Setup Docker Buildx') {
    steps {
        sh '''
            docker buildx version || {
                mkdir -p ~/.docker/cli-plugins/
                wget -O ~/.docker/cli-plugins/docker-buildx \
                  https://github.com/docker/buildx/releases/download/v0.12.0/buildx-v0.12.0.linux-amd64
                chmod +x ~/.docker/cli-plugins/docker-buildx
            }
            docker buildx create --use --name mybuilder || docker buildx use mybuilder
            docker buildx inspect --bootstrap
        '''
    }
}
```

---

### 3. Docker Hub Login

#### GitHub Actions
```yaml
- name: Login to Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
```

#### Jenkins
```groovy
stage('Login to Docker Hub') {
    steps {
        sh '''
            echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
        '''
    }
}
```

---

### 4. Build and Push Client Image

#### GitHub Actions
```yaml
- name: Build and push client image
  uses: docker/build-push-action@v5
  with:
    context: ./client
    file: ./client/Dockerfile
    push: true
    tags: |
      ${{ secrets.DOCKER_USERNAME }}/votex-client:latest
      ${{ secrets.DOCKER_USERNAME }}/votex-client:${{ github.sha }}
    cache-from: type=registry,ref=${{ secrets.DOCKER_USERNAME }}/votex-client:buildcache
    cache-to: type=registry,ref=${{ secrets.DOCKER_USERNAME }}/votex-client:buildcache,mode=max
```

#### Jenkins
```groovy
stage('Build and Push Client Image') {
    steps {
        sh '''
            docker buildx build \
                --platform linux/amd64 \
                --push \
                --file ./client/Dockerfile \
                --tag ${DOCKER_USERNAME}/votex-client:latest \
                --tag ${DOCKER_USERNAME}/votex-client:${GIT_COMMIT_SHORT} \
                --cache-from type=registry,ref=${DOCKER_USERNAME}/votex-client:buildcache \
                --cache-to type=registry,ref=${DOCKER_USERNAME}/votex-client:buildcache,mode=max \
                ./client
        '''
    }
}
```

---

### 5. AWS Credentials Configuration

#### GitHub Actions
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ env.AWS_REGION }}
```

#### Jenkins
```groovy
stage('Configure AWS Credentials') {
    steps {
        sh '''
            mkdir -p ~/.aws
            cat > ~/.aws/credentials <<EOF
[default]
aws_access_key_id = ${AWS_ACCESS_KEY_ID}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
EOF
            cat > ~/.aws/config <<EOF
[default]
region = ${AWS_REGION}
output = json
EOF
            chmod 600 ~/.aws/credentials ~/.aws/config
        '''
    }
}
```

---

### 6. Get EC2 Instance IP

#### GitHub Actions
```yaml
- name: Get EC2 instance IP
  id: get-ip
  run: |
    INSTANCE_IP=$(aws ec2 describe-instances \
      --filters "Name=tag:Name,Values=votex-server" \
                "Name=instance-state-name,Values=running" \
      --query "Reservations[0].Instances[0].PublicIpAddress" \
      --output text)
    echo "instance_ip=$INSTANCE_IP" >> $GITHUB_OUTPUT
    echo "EC2 Instance IP: $INSTANCE_IP"
```

#### Jenkins
```groovy
stage('Get EC2 Instance IP') {
    steps {
        script {
            env.INSTANCE_IP = sh(
                script: '''
                    aws ec2 describe-instances \
                        --filters "Name=tag:Name,Values=votex-server" \
                                  "Name=instance-state-name,Values=running" \
                        --query "Reservations[0].Instances[0].PublicIpAddress" \
                        --output text
                ''',
                returnStdout: true
            ).trim()
            echo "EC2 Instance IP: ${env.INSTANCE_IP}"
        }
    }
}
```

---

### 7. Ansible Installation

#### GitHub Actions
```yaml
- name: Install Ansible
  run: |
    sudo apt-get update
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    sudo apt-get install -y ansible
```

#### Jenkins
```groovy
stage('Install Ansible') {
    steps {
        sh '''
            if ! command -v ansible &> /dev/null; then
                echo "Installing Ansible..."
                sudo apt-get update
                sudo apt-get install -y software-properties-common
                sudo add-apt-repository --yes --update ppa:ansible/ansible
                sudo apt-get install -y ansible
            else
                echo "Ansible is already installed"
                ansible --version
            fi
        '''
    }
}
```

---

### 8. Deploy with Ansible

#### GitHub Actions
```yaml
- name: Deploy with Ansible
  env:
    ANSIBLE_HOST_KEY_CHECKING: False
    DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
    DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
  run: |
    cd ansible
    ansible-playbook -i inventory playbook.yml -v
```

#### Jenkins
```groovy
stage('Deploy with Ansible') {
    steps {
        sh '''
            export ANSIBLE_HOST_KEY_CHECKING=False
            cd ansible
            ansible-playbook -i inventory playbook.yml -v
        '''
    }
}
```

---

### 9. Post-Deployment Actions

#### GitHub Actions
```yaml
- name: Deployment Summary
  run: |
    echo "🎉 Deployment completed successfully!"
    echo "🌐 Frontend URL: http://${{ steps.get-ip.outputs.instance_ip }}:3000"
    echo "🔗 Backend API: http://${{ steps.get-ip.outputs.instance_ip }}:4000"
```

#### Jenkins
```groovy
stage('Deployment Summary') {
    steps {
        echo '🎉 Deployment completed successfully!'
        echo "🌐 Frontend URL: http://${env.INSTANCE_IP}:3000"
        echo "🔗 Backend API: http://${env.INSTANCE_IP}:4000"
    }
}

post {
    success {
        emailext(
            subject: "SUCCESS: VoteX Deployment",
            body: "Deployment completed successfully...",
            to: "${env.DEVELOPER_EMAIL}"
        )
    }
    failure {
        emailext(
            subject: "FAILURE: VoteX Deployment",
            body: "Deployment failed...",
            to: "${env.DEVELOPER_EMAIL}"
        )
    }
}
```

---

## Secrets/Credentials Management

### GitHub Actions
```yaml
# Stored in: Repository > Settings > Secrets and variables > Actions

secrets:
  - DOCKER_USERNAME
  - DOCKER_PASSWORD
  - AWS_ACCESS_KEY_ID
  - AWS_SECRET_ACCESS_KEY
  - EC2_SSH_PRIVATE_KEY

# Access in workflow:
${{ secrets.DOCKER_USERNAME }}
```

### Jenkins
```groovy
// Stored in: Jenkins > Credentials > System > Global credentials

credentials:
  - docker-username (Username with password)
  - docker-password (Secret text)
  - aws-access-key-id (Secret text)
  - aws-secret-access-key (Secret text)
  - ec2-ssh-private-key (Secret text)

// Access in pipeline:
environment {
    DOCKER_USERNAME = credentials('docker-username')
}
```

---

## Triggering Mechanisms

### GitHub Actions
```yaml
on:
  push:
    branches: [main]           # Automatic on push
  workflow_dispatch:           # Manual trigger
```

### Jenkins
```groovy
// Configure in Job > Build Triggers:
triggers {
    pollSCM('H/5 * * * *')    // Poll every 5 minutes
    githubPush()               // GitHub webhook
}

// Or manual trigger: Click "Build Now"
```

---

## Environment Variables

### GitHub Actions
```yaml
env:
  AWS_REGION: eu-west-1
  DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}

# Job-level:
jobs:
  build:
    env:
      NODE_ENV: production

# Step-level:
- name: Deploy
  env:
    ANSIBLE_HOST_KEY_CHECKING: False
```

### Jenkins
```groovy
environment {
    AWS_REGION = 'eu-west-1'
    DOCKER_USERNAME = credentials('docker-username')
    GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
}

// Stage-level:
stage('Deploy') {
    environment {
        ANSIBLE_HOST_KEY_CHECKING = 'False'
    }
}
```

---

## Conditional Execution

### GitHub Actions
```yaml
- name: Deploy to production
  if: github.ref == 'refs/heads/main'
  run: echo "Deploying..."

- name: Run tests
  if: success()
  run: npm test
```

### Jenkins
```groovy
stage('Deploy to Production') {
    when {
        branch 'main'
    }
    steps {
        echo 'Deploying...'
    }
}

stage('Run Tests') {
    when {
        expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
    }
    steps {
        sh 'npm test'
    }
}
```

---

## Parallel Execution

### GitHub Actions
```yaml
jobs:
  build-client:
    runs-on: ubuntu-latest
    steps: [...]
  
  build-server:
    runs-on: ubuntu-latest
    steps: [...]
```

### Jenkins
```groovy
stage('Build Images') {
    parallel {
        stage('Build Client') {
            steps { ... }
        }
        stage('Build Server') {
            steps { ... }
        }
    }
}
```

---

## Error Handling

### GitHub Actions
```yaml
- name: Deploy
  run: |
    set -e
    ./deploy.sh
  continue-on-error: false
```

### Jenkins
```groovy
stage('Deploy') {
    steps {
        script {
            try {
                sh './deploy.sh'
            } catch (Exception e) {
                echo "Deployment failed: ${e.message}"
                currentBuild.result = 'FAILURE'
                throw e
            }
        }
    }
}
```

---

## Cleanup Actions

### GitHub Actions
```yaml
# No explicit cleanup needed
# Runners are ephemeral and reset after each job
```

### Jenkins
```groovy
post {
    always {
        sh '''
            docker logout || true
            rm -f ~/.ssh/votex_key || true
            rm -f ~/.aws/credentials || true
            rm -f ~/.aws/config || true
        '''
        cleanWs()  // Clean workspace (optional)
    }
}
```

---

## Notifications

### GitHub Actions
```yaml
# Native GitHub UI notifications
# Can add custom notifications with actions:
- name: Slack Notification
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {"text": "Deployment completed"}
```

### Jenkins
```groovy
post {
    success {
        emailext(
            subject: "SUCCESS: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
            body: """
                <h2>Deployment Successful</h2>
                <p>Build: ${env.BUILD_NUMBER}</p>
                <p>Duration: ${currentBuild.durationString}</p>
            """,
            to: "${env.DEVELOPER_EMAIL}",
            mimeType: 'text/html'
        )
    }
    failure {
        emailext(
            subject: "FAILURE: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
            body: "Build failed. Check console output.",
            to: "${env.DEVELOPER_EMAIL}"
        )
    }
}
```

---

## Artifacts

### GitHub Actions
```yaml
- name: Upload artifacts
  uses: actions/upload-artifact@v3
  with:
    name: build-artifacts
    path: ./dist

- name: Download artifacts
  uses: actions/download-artifact@v3
  with:
    name: build-artifacts
```

### Jenkins
```groovy
stage('Archive Artifacts') {
    steps {
        archiveArtifacts artifacts: 'dist/**/*', fingerprint: true
    }
}

stage('Use Artifacts') {
    steps {
        script {
            copyArtifacts(projectName: 'upstream-job', selector: lastSuccessful())
        }
    }
}
```

---

## Caching

### GitHub Actions
```yaml
- name: Cache Docker layers
  uses: actions/cache@v3
  with:
    path: /tmp/.buildx-cache
    key: ${{ runner.os }}-buildx-${{ github.sha }}
    restore-keys: |
      ${{ runner.os }}-buildx-
```

### Jenkins
```groovy
// Docker layer caching via buildx:
sh '''
    docker buildx build \
        --cache-from type=registry,ref=user/image:buildcache \
        --cache-to type=registry,ref=user/image:buildcache,mode=max \
        .
'''

// Or use Jenkins Cache plugin
```

---

## Feature Comparison Table

| Feature | GitHub Actions | Jenkins |
|---------|----------------|---------|
| **Hosting** | Cloud (GitHub) | Self-hosted |
| **Cost** | 2000 min/month free | Free (hosting cost) |
| **Setup Time** | 5 minutes | 30-60 minutes |
| **Maintenance** | None | Regular updates |
| **Flexibility** | Moderate | High |
| **Custom Actions** | Marketplace | Full control |
| **Secrets** | GitHub UI | Jenkins UI |
| **Logs** | 1 year retention | Configurable |
| **Artifacts** | 90 days | Configurable |
| **Concurrent Builds** | Limited by plan | Hardware limited |
| **Private Runners** | Paid feature | Default |
| **Integration** | Native GitHub | Webhook needed |
| **Learning Curve** | Easy | Moderate |
| **Community** | Large | Very large |
| **Enterprise Support** | GitHub Enterprise | CloudBees |

---

## When to Use Each

### Use GitHub Actions When:
✅ You want minimal setup  
✅ You're already using GitHub  
✅ You need quick prototyping  
✅ Free tier is sufficient  
✅ You want managed infrastructure  
✅ You need marketplace actions  

### Use Jenkins When:
✅ You need full control  
✅ You have on-premise requirements  
✅ Free tier limits are restrictive  
✅ You need complex pipelines  
✅ You have existing Jenkins infrastructure  
✅ You need enterprise features  
✅ You want unlimited build minutes  

---

## Migration Checklist

Moving from GitHub Actions to Jenkins:

- [ ] Setup Jenkins server
- [ ] Install required plugins
- [ ] Configure 5 credentials
- [ ] Create pipeline job
- [ ] Test Docker builds locally
- [ ] Verify AWS access
- [ ] Test Ansible connection
- [ ] Run first build manually
- [ ] Setup GitHub webhook
- [ ] Configure email notifications
- [ ] Monitor several builds
- [ ] Document custom changes

---

## Both Pipelines Achieve:

✅ Automated Docker image builds  
✅ Push to Docker Hub with tags  
✅ AWS EC2 instance discovery  
✅ SSH configuration  
✅ Ansible deployment  
✅ Health check verification  
✅ Deployment notifications  
✅ Automatic cleanup  
✅ Error handling  
✅ Build caching  

**Result**: Identical deployment outcome, different execution environment!
