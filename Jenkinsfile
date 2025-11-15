pipeline {
    agent any
    
    environment {
        AWS_REGION = 'eu-west-1'
        DOCKER_USERNAME = credentials('docker-username')
        DOCKER_PASSWORD = credentials('docker-password')
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        EC2_SSH_PRIVATE_KEY = credentials('ec2-ssh-private-key')
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                echo 'Checking out code from repository...'
                checkout scm
            }
        }
        
        stage('Setup Docker Buildx') {
            steps {
                echo 'Setting up Docker Buildx...'
                sh '''
                    docker buildx version || {
                        echo "Installing Docker Buildx..."
                        mkdir -p ~/.docker/cli-plugins/
                        wget -O ~/.docker/cli-plugins/docker-buildx https://github.com/docker/buildx/releases/download/v0.12.0/buildx-v0.12.0.linux-amd64
                        chmod +x ~/.docker/cli-plugins/docker-buildx
                    }
                    docker buildx create --use --name mybuilder || docker buildx use mybuilder
                    docker buildx inspect --bootstrap
                '''
            }
        }
        
        stage('Login to Docker Hub') {
            steps {
                echo 'Logging into Docker Hub...'
                sh '''
                    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                '''
            }
        }
        
        stage('Build and Push Client Image') {
            steps {
                echo 'Building and pushing client Docker image...'
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
        
        stage('Build and Push Server Image') {
            steps {
                echo 'Building and pushing server Docker image...'
                sh '''
                    docker buildx build \
                        --platform linux/amd64 \
                        --push \
                        --file ./server/Dockerfile \
                        --tag ${DOCKER_USERNAME}/votex-server:latest \
                        --tag ${DOCKER_USERNAME}/votex-server:${GIT_COMMIT_SHORT} \
                        --cache-from type=registry,ref=${DOCKER_USERNAME}/votex-server:buildcache \
                        --cache-to type=registry,ref=${DOCKER_USERNAME}/votex-server:buildcache,mode=max \
                        ./server
                '''
            }
        }
        
        stage('Configure AWS Credentials') {
            steps {
                echo 'Configuring AWS credentials...'
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
                    chmod 600 ~/.aws/credentials
                    chmod 600 ~/.aws/config
                '''
            }
        }
        
        stage('Get EC2 Instance IP') {
            steps {
                echo 'Retrieving EC2 instance IP address...'
                script {
                    env.INSTANCE_IP = sh(
                        script: '''
                            aws ec2 describe-instances \
                                --filters "Name=tag:Name,Values=votex-server" "Name=instance-state-name,Values=running" \
                                --query "Reservations[0].Instances[0].PublicIpAddress" \
                                --output text
                        ''',
                        returnStdout: true
                    ).trim()
                    echo "EC2 Instance IP: ${env.INSTANCE_IP}"
                }
            }
        }
        
        stage('Setup SSH Key') {
            steps {
                echo 'Setting up SSH key for EC2 access...'
                sh '''
                    mkdir -p ~/.ssh
                    echo "$EC2_SSH_PRIVATE_KEY" > ~/.ssh/votex_key
                    chmod 600 ~/.ssh/votex_key
                    ssh-keyscan -H ${INSTANCE_IP} >> ~/.ssh/known_hosts
                '''
            }
        }
        
        stage('Install Ansible') {
            steps {
                echo 'Installing Ansible and dependencies...'
                sh '''
                    # Check if Ansible is already installed
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
        
        stage('Install Ansible Docker Collection') {
            steps {
                echo 'Installing Ansible Docker collection...'
                sh '''
                    ansible-galaxy collection install community.docker
                '''
            }
        }
        
        stage('Create Ansible Inventory') {
            steps {
                echo 'Creating Ansible inventory file...'
                sh '''
                    echo "[votex_servers]" > ansible/inventory
                    echo "${INSTANCE_IP} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/votex_key" >> ansible/inventory
                    echo "Inventory contents:"
                    cat ansible/inventory
                '''
            }
        }
        
        stage('Update Docker Compose Configuration') {
            steps {
                echo 'Updating docker-compose.yml with Docker Hub images...'
                sh '''
                    sed -i "s|build: ./client|image: ${DOCKER_USERNAME}/votex-client:latest|g" docker-compose.yml
                    sed -i "s|build: ./server|image: ${DOCKER_USERNAME}/votex-server:latest|g" docker-compose.yml
                    echo "Updated docker-compose.yml:"
                    cat docker-compose.yml
                '''
            }
        }
        
        stage('Deploy with Ansible') {
            steps {
                echo 'Deploying application with Ansible...'
                sh '''
                    export ANSIBLE_HOST_KEY_CHECKING=False
                    cd ansible
                    ansible-playbook -i inventory playbook.yml -v
                '''
            }
        }
        
        stage('Deployment Summary') {
            steps {
                echo '🎉 Deployment completed successfully!'
                echo "🌐 Frontend URL: http://${env.INSTANCE_IP}:3000"
                echo "🔗 Backend API: http://${env.INSTANCE_IP}:4000"
                echo "💚 Health Check: http://${env.INSTANCE_IP}:4000/api/health"
                
                script {
                    currentBuild.description = "Deployed to ${env.INSTANCE_IP}"
                }
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up...'
            sh '''
                # Logout from Docker Hub
                docker logout || true
                
                # Clean up sensitive files
                rm -f ~/.ssh/votex_key || true
                rm -f ~/.aws/credentials || true
                rm -f ~/.aws/config || true
            '''
        }
        success {
            echo '✅ Pipeline completed successfully!'
            emailext(
                subject: "SUCCESS: VoteX Deployment - Build #${BUILD_NUMBER}",
                body: """
                    <h2>VoteX Deployment Successful</h2>
                    <p><strong>Build Number:</strong> ${BUILD_NUMBER}</p>
                    <p><strong>Commit:</strong> ${GIT_COMMIT_SHORT}</p>
                    <p><strong>EC2 Instance IP:</strong> ${env.INSTANCE_IP}</p>
                    <p><strong>Frontend URL:</strong> <a href="http://${env.INSTANCE_IP}:3000">http://${env.INSTANCE_IP}:3000</a></p>
                    <p><strong>Backend API:</strong> <a href="http://${env.INSTANCE_IP}:4000">http://${env.INSTANCE_IP}:4000</a></p>
                    <p><strong>Duration:</strong> ${currentBuild.durationString}</p>
                """,
                to: "${env.DEVELOPER_EMAIL}",
                mimeType: 'text/html'
            )
        }
        failure {
            echo '❌ Pipeline failed!'
            emailext(
                subject: "FAILURE: VoteX Deployment - Build #${BUILD_NUMBER}",
                body: """
                    <h2>VoteX Deployment Failed</h2>
                    <p><strong>Build Number:</strong> ${BUILD_NUMBER}</p>
                    <p><strong>Commit:</strong> ${GIT_COMMIT_SHORT}</p>
                    <p><strong>Error:</strong> Check Jenkins console output for details</p>
                    <p><strong>Build URL:</strong> <a href="${BUILD_URL}">${BUILD_URL}</a></p>
                """,
                to: "${env.DEVELOPER_EMAIL}",
                mimeType: 'text/html'
            )
        }
        unstable {
            echo '⚠️ Pipeline is unstable!'
        }
    }
}
