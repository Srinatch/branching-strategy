pipeline {

    agent any

    triggers {
        githubPush()
        pollSCM('H/5 * * * *')
        cron('0 10 * * *')
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        skipDefaultCheckout()
        retry(2)
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    parameters {

        string(
            name: 'GIT_REPO',
            defaultValue: 'https://github.com/awsdevopssri/Future.git',
            description: 'GitHub Repository URL'
        )

        string(
            name: 'BRANCH',
            defaultValue: 'main',
            description: 'Git Branch'
        )

        string(
            name: 'MAIN_CLASS',
            defaultValue: 'com.example.App',
            description: 'Java Main Class'
        )

        choice(
            name: 'MAVEN_GOAL',
            choices: ['clean package','clean install','package'],
            description: 'Maven Build Goal'
        )

        choice(
            name: 'ENVIRONMENT',
            choices: ['dev','qa','prod'],
            description: 'Deployment Environment'
        )

        booleanParam(
            name: 'CLEAN_ON_FAIL',
            defaultValue: true,
            description: 'Cleanup workspace if build fails'
        )
    }

    environment {
        JAVA_HOME = "/usr/lib/jvm/java-21-openjdk-amd64"
        MAVEN_HOME = "/usr/share/maven"
        PATH = "${JAVA_HOME}/bin:${MAVEN_HOME}/bin:${env.PATH}"
        APP_NAME = "java-devops-app"
    }

    stages {

        stage('Prepare Workspace') {
            steps {
                echo "Cleaning workspace before build"
                cleanWs()
            }
        }

        stage('Checkout Code') {
            steps {
                echo "Cloning repository from ${params.GIT_REPO}"
                git branch: "${params.BRANCH}",
                    url: "${params.GIT_REPO}"
            }
        }

        stage('Build Information') {
            steps {

                echo "==================================="

                echo "Build Number: ${env.BUILD_NUMBER}"
                echo "Git Branch: ${params.BRANCH}"
                echo "Repository: ${params.GIT_REPO}"
                echo "Environment: ${params.ENVIRONMENT}"

                echo "==================================="

                sh 'git log -1 --oneline'
            }
        }

        stage('Verify Tools') {

            steps {

                sh '''
                echo "Checking Java"
                java -version

                echo "Checking Maven"
                mvn -version
                '''
            }
        }

        stage('Build Application') {

            steps {

                echo "Running Maven Goal: ${params.MAVEN_GOAL}"

                sh "mvn ${params.MAVEN_GOAL}"
            }
        }

        stage('Run Tests') {

            steps {

                echo "Running Maven tests"

                sh 'mvn test'

                junit 'target/surefire-reports/*.xml'
            }
        }

        stage('Run Java Application') {

            steps {

                echo "Running Java class ${params.MAIN_CLASS}"

                sh """
                java -cp target/*.jar ${params.MAIN_CLASS}
                """
            }
        }

        stage('Verify Artifact') {

            steps {

                echo "Verifying generated JAR file"

                sh 'ls -lh target/'
            }
        }

        stage('Archive Artifacts') {

            steps {

                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
    }

    post {

        success {

            echo "=================================="
            echo " BUILD SUCCESSFUL "
            echo " Application ${env.APP_NAME} built successfully"
            echo " Environment: ${params.ENVIRONMENT}"
            echo "=================================="
        }

        failure {

            echo "=================================="
            echo " BUILD FAILED "
            echo "=================================="

            script {

                if(params.CLEAN_ON_FAIL == true) {

                    echo "Cleaning workspace due to failure"

                    deleteDir()
                }
            }
        }

        always {

            echo "Cleaning temporary files"

            cleanWs()

            echo "Pipeline execution completed"
        }
    }
}