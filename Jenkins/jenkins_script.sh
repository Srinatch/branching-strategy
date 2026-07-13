pipeline {

    /* -------------------------------------------------
       Run pipeline on any available Jenkins agent
    --------------------------------------------------*/
    agent any

    /* -------------------------------------------------
       Parameters allow dynamic pipeline execution
       User can change these from Jenkins UI
    --------------------------------------------------*/
    parameters {

        // Git repository URL
        string(
            name: 'GIT_REPO',
            defaultValue: 'https://github.com/yourrepo/java-project.git',
            description: 'GitHub Repository URL'
        )

        // Git branch to build
        string(
            name: 'BRANCH',
            defaultValue: 'main',
            description: 'Git Branch'
        )

        // Java main class to run
        string(
            name: 'MAIN_CLASS',
            defaultValue: 'com.example.App',
            description: 'Java Main Class'
        )

        // Maven goals
        choice(
            name: 'MAVEN_GOAL',
            choices: ['clean package','clean install','package'],
            description: 'Maven Build Goal'
        )

        // Environment
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev','qa','prod'],
            description: 'Deployment Environment'
        )

        // Enable cleanup on failure
        booleanParam(
            name: 'CLEAN_ON_FAIL',
            defaultValue: true,
            description: 'Cleanup workspace if build fails'
        )
    }

    /* -------------------------------------------------
       Environment variables
    --------------------------------------------------*/
    environment {

        JAVA_HOME = "/usr/lib/jvm/java-21-openjdk-amd64"
        MAVEN_HOME = "/usr/share/maven"

        PATH = "${JAVA_HOME}/bin:${MAVEN_HOME}/bin:${env.PATH}"

        APP_NAME = "java-devops-app"
    }

    stages {

        /* -------------------------------------------------
           Checkout source code from GitHub
        --------------------------------------------------*/
        stage('Checkout Code') {
            steps {

                echo "Cloning repository from ${params.GIT_REPO}"

                git branch: "${params.BRANCH}",
                    url: "${params.GIT_REPO}"
            }
        }

        /* -------------------------------------------------
           Verify tools installed in Jenkins server
        --------------------------------------------------*/
        stage('Verify Tools') {
            steps {

                sh 'java -version'
                sh 'mvn -version'
            }
        }

        /* -------------------------------------------------
           Build the Java project using Maven
        --------------------------------------------------*/
        stage('Build Application') {
            steps {

                echo "Running Maven Goal: ${params.MAVEN_GOAL}"

                sh "mvn ${params.MAVEN_GOAL}"
            }
        }

        /* -------------------------------------------------
           Run the compiled Java application
        --------------------------------------------------*/
        stage('Run Java Application') {
            steps {

                echo "Running Java class ${params.MAIN_CLASS}"

                sh """
                java -cp target/*.jar ${params.MAIN_CLASS}
                """
            }
        }

        /* -------------------------------------------------
           Archive build artifacts
        --------------------------------------------------*/
        stage('Archive Artifacts') {
            steps {

                archiveArtifacts artifacts: 'target/*.jar',
                fingerprint: true
            }
        }

    }

    /* -------------------------------------------------
       Post actions
    --------------------------------------------------*/
    post {

        success {

            echo "=================================="
            echo " BUILD SUCCESSFUL 🚀"
            echo " Application ${env.APP_NAME} built successfully"
            echo " Environment: ${params.ENVIRONMENT}"
            echo "=================================="
        }

        failure {

            echo "=================================="
            echo " BUILD FAILED ❌"
            echo "=================================="

            script {

                if(params.CLEAN_ON_FAIL == true) {

                    echo "Cleaning workspace due to failure"

                    deleteDir()
                }
            }
        }

        always {

            echo "Pipeline execution completed"
        }
    }
}