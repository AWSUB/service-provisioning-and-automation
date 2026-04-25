pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "whateveraws/personal"
        DOCKER_TAG = "service-provisioning-and-automation"
    }

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
                    sh """
                        echo $DOCKERHUB_PASSWORD | docker login -u $DOCKERHUB_USERNAME --password-stdin
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    """
                }
            }
        }
    }
}