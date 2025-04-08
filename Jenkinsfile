pipeline {
    agent any

    environment {
        DOCKER_HUB_REPO = 'genih/tooling-app'
    
    }

     stages {
        stage("Initial cleanup") {
            steps {
                dir("${WORKSPACE}") {
                    deleteDir()
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

      stage('Run Docker Compose') {
            steps {
                script {
                    // Start services using Docker Compose
                    sh """
                    docker-compose -f tooling.yml up 
                    """
                }
            }
        }

        stage('Smoke Test') {
            steps {
                script {
                    def response
                    retry(5) {
                        sleep(time: 20, unit: 'SECONDS')
                        response = sh(script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:5000", returnStdout: true).trim()
                        echo "HTTP Status Code: ${response}"
                        if (response == '200') {
                            echo "Smoke test passed with status code 200"
                        } else {
                            error "Smoke test failed with status code ${response}"
                        }
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    sh "docker login -u ${USERNAME} -p ${PASSWORD}"
                    sh "docker tag tooling_containerization_main-frontend ${DOCKER_HUB_REPO}:${env.BRANCH_NAME}${env.BUILD_NUMBER}"
                    sh "docker push ${DOCKER_HUB_REPO}:${env.BRANCH_NAME}${env.BUILD_NUMBER}"
                }
            }
        }
    



        stage('Stop and Remove Containers') {
            steps {
                script {
                    // Stop and remove Docker containers
                    sh """
                    docker-compose -f tooling.yml down
                    """
                }
            }
        }

        stage('Cleanup') {
            steps {
                script {
                    // Clean up Docker images to save space
                    sh """
                    docker rmi ${DOCKER_HUB_REPO}:${env.BRANCH_NAME}${env.BUILD_NUMBER} || true
                    """
                }
            }
        }
    }

    post {
        always {
            script {
                // Logout from Docker
                sh 'docker logout'
            }
        }
    }
}