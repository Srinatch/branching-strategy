pipeline {

    // Run pipeline on any Jenkins agent/node
    agent any

    // Parameters allow dynamic pipeline execution
    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'GitHub Branch Name')
    }

    // Environment variables
    environment {
        JAVA_HOME = "/usr/lib/jvm/java-17-openjdk"
        MAVEN_HOME = "/opt/maven"
        PATH = "${JAVA_HOME}/bin:${MAVEN_HOME}/bin:${env.PATH}"
    }

    stages {

        stage('Checkout Code') {
            steps {
                // Pull code from GitHub repository
                git branch: "${params.BRANCH_NAME}", url: 'https://github.com/yourrepo/devops-jenkins-project.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                // Execute shell script to install Java and Maven automatically
                sh 'chmod +x install_tools.sh'
                sh './install_tools.sh'
            }
        }

        stage('Verify Tools') {
            steps {
                // Verify Java installation
                sh 'java -version'

                // Verify Maven installation
                sh 'mvn -version'
            }
        }

        stage('Build Application') {
            steps {
                // Build the Maven project
                sh 'mvn clean package'
            }
        }

    }

    post {

        success {
            // Show success message if pipeline completes successfully
            echo "BUILD SUCCESSFUL 🚀"
        }

        failure {
            // If build fails run cleanup script
            echo "BUILD FAILED ❌"

            sh 'chmod +x cleanup.sh'
            sh './cleanup.sh'
        }

        always {
            // Clean Jenkins workspace after execution
            cleanWs()
        }

    }

}