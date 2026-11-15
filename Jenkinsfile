// SkyStore CI/CD pipeline: Git -> Jenkins -> Docker -> (AWS via Terraform)
pipeline {
    agent any

    environment {
        IMAGE_NAME     = 'skystore'
        IMAGE_TAG      = "${env.BUILD_NUMBER}"
        CONTAINER_NAME = 'skystore-app-ci'
        CI_NETWORK     = 'skystore_default'
        // Convex deployment URL (set as a Jenkins global env var; falls back to project default)
        VITE_CONVEX_URL = "${env.VITE_CONVEX_URL ?: 'https://shiny-stingray-832.convex.cloud'}"
    }

    stages {
        stage('Checkout (Git)') {
            steps {
                checkout scm
                sh 'git log -1 --pretty="Commit: %h by %an - %s"'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                docker build \
                  --build-arg VITE_CONVEX_URL=${VITE_CONVEX_URL} \
                  -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:ci-latest .
                '''
            }
        }

        stage('Smoke Test') {
            steps {
                sh '''
                docker rm -f smoke-${BUILD_NUMBER} >/dev/null 2>&1 || true
                docker run -d --name smoke-${BUILD_NUMBER} --network ${CI_NETWORK} ${IMAGE_NAME}:${IMAGE_TAG}
                sleep 4
                if curl -s http://smoke-${BUILD_NUMBER}/ | grep -q "<title>Cloudlet</title>"; then
                  echo "Smoke test PASSED"
                else
                  docker logs smoke-${BUILD_NUMBER}; docker rm -f smoke-${BUILD_NUMBER}; exit 1
                fi
                docker rm -f smoke-${BUILD_NUMBER}
                '''
            }
        }

        stage('Deploy Container') {
            steps {
                sh '''
                docker rm -f ${CONTAINER_NAME} >/dev/null 2>&1 || true
                docker run -d --name ${CONTAINER_NAME} -p 3001:80 --restart unless-stopped ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }
    }

    post {
        success { echo 'SkyStore built, tested and deployed. CI deployment: http://localhost:3001' }
        failure { echo 'Pipeline failed!' }
    }
}
