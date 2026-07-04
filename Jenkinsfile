def modules = [
    '40-databases',
    '50-backend-alb',
    '70-acm',
    '80-frontend-alb',
    '90-components',
    '95-cdn'
]

def terraformModule(String moduleDir) {
    dir(moduleDir) {
        sh '''
            terraform init -input=false
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
        TF_CLI_ARGS        = "-no-color"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Approval') {
            when {
                expression { params.ACTION in ['apply', 'destroy'] }
            }
            steps {
                input message: "Approve ${params.ACTION.toUpperCase()}?"
            }
        }

        stage('Terraform Execution') {
            steps {
                script {

                    def executionOrder = modules

                    // 🔥 Reverse ONLY for destroy
                    if (params.ACTION == 'destroy') {
                        executionOrder = modules.reverse()
                    }

                    executionOrder.each { module ->
                        echo "Running Terraform in ${module}"
                        terraformModule(module)
                    }
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