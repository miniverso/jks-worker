pipeline {
  agent {
    kubernetes {
      label 'jenkins-pod'
    }
  }
  
  stages {
      stage('Docker Build'){
        steps {
            script {
              sh 'faas-cli build  -t miniverso/jenkins-worker .'
            }
        }
      }
  }
}