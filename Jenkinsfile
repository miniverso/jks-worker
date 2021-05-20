pipeline {
  agent {
    kubernetes {
      label 'jenkins-pod'
    }
  }
  
  stages {
      stage('hw'){
        steps {
            script {
              sh 'echo "hello world'
            }
        }
      }
  }
}