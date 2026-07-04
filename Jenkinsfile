def terraformModule(String moduleDir) {
    dir(moduleDir) {
        sh '''
            terraform init            
            terraform validate

            if [ "${ACTION}" = "plan" ] || [ "${ACTION}" = "apply" ]; then
                terraform plan -out=tfplan
            fi

            if [ "${ACTION}" = "apply" ]; then
                terraform apply -auto-approve tfplan
            fi

            if [ "${ACTION}" = "destroy" ]; then
                terraform destroy -auto-approve
            fi
        '''
    }
}

pipeline {

    agent any

    options {
        ansiColor('xterm')
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Terraform Action'
        )
    }

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        TF_IN_AUTOMATION   = 'true'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Approval') {
            when {
                expression { params.ACTION == 'apply' || params.ACTION == 'destroy' }
            }
            steps {
                input message: "Approve ${params.ACTION.toUpperCase()}?"
            }
        }

        stage('40-Databases') {
            steps {
                script {
                    terraformModule('40-databases')
                }
            }
        }

        stage('50-Backend-ALB') {
            steps {
                script {
                    terraformModule('50-backend-alb')
                }
            }
        }        

        stage('70-ACM') {
            steps {
                script {
                    terraformModule('70-acm')
                }
            }
        }

        stage('80-Frontend-ALB') {
            steps {
                script {
                    terraformModule('80-frontend-alb')
                }
            }
        }

        stage('90-Components') {
            steps {
                script {
                    terraformModule('90-components')
                }
            }
        }

        stage('95-CDN') {
            steps {
                script {
                    terraformModule('95-cdn')
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed.'
        }

        always {
            cleanWs()
        }
    }
}