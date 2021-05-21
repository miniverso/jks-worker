def imageName = "miniverso/jenkins-worker"

pipeline {
  agent {
    kubernetes {
      label 'jenkins-pod'
    }
  }
  stages {
    stage('Build Docker Image') {
      steps {
        script {
          def TAG = (env.BRANCH_NAME == "master" ) ? 'prd' : 'dev'
          sh "docker build \
                --network host \
                --add-host=\"github.com:`dig +short github.com`\" \
                --add-host=\"raw.githubcontent.com:`dig +short raw.githubcontent.com`\" \
                -t ${imageName}:${TAG} ."          
        }
      }
    }

    stage('Creating Release and Tagging') {
      when { 
         not {
          branch 'master';
        }
      }
      environment {
        TOKEN = credentials('gh-token')
      }
      steps {
          sh 'npm install'               
          sh 'GH_TOKEN=$TOKEN node_modules/semantic-release/bin/semantic-release.js'
      }
    }  

    // stage('Publish Docker Image') {
    //   steps {
    //     script {
    //       def TAG = sh(returnStdout: true, script: "git tag --sort version:refname | tail -1 | cut -c2-6").trim()
    //       def TAGA = sh(returnStdout: true, script: "git tag --sort version:refname | tail -1 | cut -c2-4").trim()
    //       def TAGB = sh(returnStdout: true, script: "git tag --sort version:refname | tail -1 | cut -c2-2").trim()
          
    //       def B_TAG = (env.BRANCH_NAME == "develop" ) ? 'stage' : (env.BRANCH_NAME == "master" ) ? 'prod' : 'latest'
          
    //       sh "docker tag ${imageName}:${B_TAG} ${imageName}:${TAG}"
    //       sh "docker tag ${imageName}:${B_TAG} ${imageName}:${TAGA}"
    //       sh "docker tag ${imageName}:${B_TAG} ${imageName}:${TAGB}"

    //       withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
    //         sh "docker login -p ${PASSWORD} -u ${USERNAME} "
    //       }

    //       sh "docker push ${imageName}"
    //     }
    //   }
    // }
  }
}