pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = "docker.io"
        DOCKER_IMAGE = "francdocmain/tooling-app"
        COMPOSE_FILE = "tooling.yml"
    }

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'Git branch to build')
    }

    stages {
        stage('Initial cleanup') {
            steps {
                dir("${WORKSPACE}") {
                    deleteDir()
                }
            }
        }

        stage('SCM Checkout') {
            steps {
                script {
                    // Dynamically select the branch based on the parameter
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: "${params.BRANCH_NAME}"]],
                        userRemoteConfigs: [[url: 'https://github.com/francdomain/tooling_containerization.git']]
                    ])
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def branchName = params.BRANCH_NAME
                    env.TAG_NAME = branchName == 'main' ? 'latest' : "${branchName}-0.0.${env.BUILD_NUMBER}"

                    // Build Docker image with a dynamic tag based on branch name
                    sh """
                    docker-compose -f ${COMPOSE_FILE} build --build-arg TAG_NAME=${env.TAG_NAME}
                    """
                }
            }
        }

        stage('Run Docker Compose') {
            steps {
                script {
                    // Start services using Docker Compose
                    sh """
                    docker-compose -f ${COMPOSE_FILE} up -d
                    """
                }
            }
        }

        stage('Smoke Test') {
            steps {
                script {
                    // Test if tooling site HTTP endpoint returns status code 200
                    def response = sh(script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:5001", returnStdout: true).trim()
                    if (response != '200') {
                        error "Smoke test failed with status code ${response}"
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    // Use Jenkins credentials to login to Docker and push the image
                    withCredentials([usernamePassword(credentialsId: 'docker-credentials', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                        sh """
                        echo ${PASSWORD} | docker login -u ${USERNAME} --password-stdin ${DOCKER_REGISTRY}
                        docker tag ${DOCKER_IMAGE}:${env.TAG_NAME} ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${env.TAG_NAME}
                        docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${env.TAG_NAME}
                        """
                    }
                }
            }
        }

        stage('Stop and Remove Containers') {
            steps {
                script {
                    // Stop and remove Docker containers
                    sh """
                    docker-compose -f ${COMPOSE_FILE} down
                    """
                }
            }
        }

        stage('Cleanup Docker Images') {
            steps {
                script {
                    // Clean up Docker images to save space
                    sh """
                    docker rmi ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${env.TAG_NAME} || true
                    """
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout'
        }
    }
}