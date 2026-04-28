pipeline {
    agent any

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '3'))
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {
        stage('Build and Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials', 
                    usernameVariable: 'DOCKERHUB_USERNAME', 
                    passwordVariable: 'DOCKERHUB_PASSWORD'
                )]) {
                    sh '''
                        echo $DOCKERHUB_PASSWORD | docker login -u $DOCKERHUB_USERNAME --password-stdin
                        docker buildx create --name=my_builder --driver=docker-container --driver-opt=memory=1G,cpu-shares=16 --bootstrap --use 
                        docker buildx build --load -t ${DOCKER_IMAGE}:${DOCKER_TAG} . --builder my_builder
                        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                        docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG}
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials', 
                    usernameVariable: 'DOCKERHUB_USERNAME', 
                    passwordVariable: 'DOCKERHUB_PASSWORD'
                )]) {
                    sh '''
                        kubectl create secret docker-registry dockerhub-secret \
                            --docker-server=https://index.docker.io/v1/ \
                            --docker-username="$DOCKERHUB_USERNAME" \
                            --docker-password="$DOCKERHUB_PASSWORD" \
                            --dry-run=client -o yaml | kubectl apply -f -
                    '''
                }

                withCredentials([sshUserPrivateKey(
                    credentialsId: 'k8s-ssh-key', 
                    keyFileVariable: 'SSH_KEY_PATH', 
                    usernameVariable: 'SSH_USERNAME'
                )]) {
                    sh '''
                        scp -i $SSH_KEY_PATH \
                            -o StrictHostKeyChecking=no \
                            -r ${WORKSPACE}/deployment/ \
                            $SSH_USERNAME@${K8S_MASTER_IP}:/home/$SSH_USERNAME/
                        ssh -i $SSH_KEY_PATH \
                            -o StrictHostKeyChecking=no \
                            -o BatchMode=yes \
                            $SSH_USERNAME@${K8S_MASTER_IP} \
                            'bash /home/$SSH_USERNAME/deployment/deploy.sh'
                    '''
                }
            }
        }
    }

    post {
        always {
            sh '''
                docker logout || true
            '''
            cleanWs()
        }
    }
}