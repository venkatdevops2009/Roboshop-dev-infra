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
        AWS_DEFAULT_REGION = "us-east-1"
        TF_IN_AUTOMATION = "true"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Format Check') {
            when {
                expression { params.ACTION != "destroy" }
            }
            steps {
                sh '''
                terraform -chdir=roboshop-dev-infra/40-database fmt -check
                terraform -chdir=roboshop-dev-infra/50-backend-alb fmt -check
                terraform -chdir=roboshop-dev-infra/70-acm fmt -check
                terraform -chdir=roboshop-dev-infra/80-forntend-alb fmt -check
                terraform -chdir=roboshop-dev-infra/90-componets fmt -check
                terraform -chdir=roboshop-dev-infra/95-cdn fmt -check
                '''
            }
        }

        stage('Terraform Validate') {
            when {
                expression { params.ACTION != "destroy" }
            }
            steps {

                sh '''
                terraform -chdir=roboshop-dev-infra/40-database init
                terraform -chdir=roboshop-dev-infra/50-backend-alb init
                terraform -chdir=roboshop-dev-infra/70-acm init
                terraform -chdir=roboshop-dev-infra/80-forntend-alb init
                terraform -chdir=roboshop-dev-infra/90-componets init
                terraform -chdir=roboshop-dev-infra/95-cdn init                
                '''
            }
        }

        stage('Terraform Plan') {

            when {
                expression {
                    params.ACTION == "plan" || params.ACTION == "apply"
                }
            }

            steps {

                sh '''
                terraform -chdir=roboshop-dev-infra/40-database plan -out=tfplan
                terraform -chdir=roboshop-dev-infra/50-backend-alb plan -out=tfplan
                terraform -chdir=roboshop-dev-infra/70-acm plan -out=tfplan
                terraform -chdir=roboshop-dev-infra/80-forntend-alb plan -out=tfplan
                terraform -chdir=roboshop-dev-infra/90-componets plan -out=tfplan
                terraform -chdir=roboshop-dev-infra/95-cdn plan -out=tfplan                 
                '''

            }

        }

        stage('Approval') {

            when {
                expression {
                    params.ACTION == "apply"
                }
            }

            steps {
                input message: "Approve Infrastructure Deployment?"
            }

        }

        stage('Terraform Apply - Database') {

            when {
                expression {
                    params.ACTION == "apply"
                }
            }

            steps {

                dir('roboshop-dev-infra/40-database') {

                    sh '''
                    terraform apply -auto-approve tfplan
                    '''

                }

            }

        }

        stage('Terraform Apply - Backend') {

            when {
                expression {
                    params.ACTION == "apply"
                }
            }

            steps {

                dir('roboshop-dev-infra/50-backend') {

                    sh '''
                    terraform apply -auto-approve tfplan
                    '''

                }

            }

        }

        stage('Terraform Apply - ACM') {

            when {
                expression {
                    params.ACTION == "apply"
                }
            }

            steps {

                dir('roboshop-dev-infra/70-acm plan') {

                    sh '''
                    terraform apply -auto-approve tfplan
                    '''

                }

            }

        }

        stage('Terraform Apply - Frontend') {

            when {
                expression {
                    params.ACTION == "apply"
                }
            }

            steps {

                dir('roboshop-dev-infra/80-forntend-alb plan') {

                    sh '''
                    terraform apply -auto-approve tfplan
                    '''

                }

            }

        }

        stage('Terraform Apply - Components') {

            when {
                expression {
                    params.ACTION == "apply"
                }
            }

            steps {

                dir('roboshop-dev-infra/90-components plan') {

                    sh '''
                    terraform apply -auto-approve tfplan
                    '''

                }

            }

        }

        stage('Terraform Apply - cdn') {

            when {
                expression {
                    params.ACTION == "apply"
                }
            }

            steps {

                dir('roboshop-dev-infra/95-cdn plan') {

                    sh '''
                    terraform apply -auto-approve tfplan
                    '''

                }

            }

        }

        
        stage('Terraform Destroy') {

            when {
                expression {
                    params.ACTION == "destroy"
                }
            }

            steps {

                input message: "Destroy Infrastructure?"

                sh '''
                terraform -chdir=roboshop-dev-infra/40-database destroy -auto-approve

                terraform -chdir=roboshop-dev-infra/50-backend-alb destroy -auto-approve

                terraform -chdir=roboshop-dev-infra/70-acm destroy -auto-approve

                terraform -chdir=roboshop-dev-infra/80-forntend-alb destroy -auto-approve

                terraform -chdir=roboshop-dev-infra/90-componets destroy -auto-approve

                terraform -chdir=roboshop-dev-infra/95-cdn destroy -auto-approve                

                '''

            }

        }

    }

    post {

        success {
            echo "Deployment Completed Successfully."
        }

        failure {
            echo "Deployment Failed."
        }

        always {
            cleanWs()
        }

    }

}