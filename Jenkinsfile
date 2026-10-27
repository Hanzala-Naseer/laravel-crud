
pipeline {
    agent any

    environment {
        BACKEND_IMAGE = 'laravel-backend:latest'
        FRONTEND_IMAGE = 'laravel-frontend:latest'
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
        MINIKUBE_HOME = '/home/hanzala'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'git log -1 --oneline'
            }
        }

       stage('Test Laravel') {
    steps {
        sh '''
            docker run --rm \
              -v "$WORKSPACE:/src:ro" \
              -w /tmp \
              php:8.3-cli bash -lc '
                set -e
                apt-get update
                apt-get install -y git unzip libzip-dev libsqlite3-dev curl
                docker-php-ext-install pdo_sqlite zip

                mkdir -p /tmp/app
                cp -a /src/. /tmp/app/
                cd /tmp/app

                curl -fsSL https://getcomposer.org/installer \
                  -o /tmp/composer-setup.php
                php /tmp/composer-setup.php \
                  --install-dir=/usr/local/bin \
                  --filename=composer

                cp .env.example .env
                composer install --no-interaction
                php artisan key:generate

                DB_CONNECTION=sqlite \
                DB_DATABASE=:memory: \
                php artisan test
              '
        '''
    }
}

        stage('Build Docker Images') {
            steps {
                sh '''
                    docker build -t "$BACKEND_IMAGE" .
                    docker build -t "$FRONTEND_IMAGE" ./frontend
                '''
            }
        }

        stage('Load Images into Minikube') {
            steps {
                sh '''
                    minikube image load "$BACKEND_IMAGE"
                    minikube image load "$FRONTEND_IMAGE"
                    minikube image ls
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    kubectl apply -f k8s/
                    kubectl rollout status deployment/laravel-backend --timeout=180s
                    kubectl rollout status deployment/laravel-frontend --timeout=180s
                    kubectl rollout status deployment/mysql --timeout=180s
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    kubectl get deployments
                    kubectl get pods
                    kubectl get services
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Check the stage logs above.'
        }
    }
}
