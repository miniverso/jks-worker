def imageName = "registry.gitlab.com/miniverso/jks-worker"

pipeline {
  agent {
    kubernetes {
      label 'jenkins-pod'
    }
  }
  stages {
    stage('Build Docker Image') {
      when{
        anyOf {
          branch 'main'
          branch 'develop'
        }
      }
      steps {
        script {
          def TAG = (env.BRANCH_NAME == "main" ) ? 'prd' : 'dev'
          sh "docker build \
                --network host \
                --add-host=github.com:`dig +short github.com` \
                --add-host=registry.yarnpkg.com:`dig +short registry.yarnpkg.com | head -2 | tail -1` \
                -t ${imageName}:${TAG} ."          
        }
      }
    }

    stage('Creating Release and Tagging') {
      environment {
        TOKEN = credentials('gh-token')
      }
      when{
        anyOf {
          branch 'develop'
        }
      }
      steps {
          sh 'npm install'               
          sh 'GH_TOKEN=$TOKEN node_modules/semantic-release/bin/semantic-release.js'
      }
    }  

    stage('Publish Docker Image') {
      environment {
        REGISTRY = credentials('gitlab');
      }
      when{
        anyOf {
          branch 'main'
          branch 'develop'
        }
      }
      steps {
        script {
          def TAGA = sh(returnStdout: true, script: "git tag --sort version:refname | tail -1 | cut -c2-6").trim()
          def TAGB = sh(returnStdout: true, script: "git tag --sort version:refname | tail -1 | cut -c2-4").trim()
          def TAGC = sh(returnStdout: true, script: "git tag --sort version:refname | tail -1 | cut -c2-2").trim()
          
          def TAG = (env.BRANCH_NAME == "main" ) ? 'prd' : 'dev'

          sh "docker tag ${imageName}:${TAG} ${imageName}:${TAGA}"
          sh "docker tag ${imageName}:${TAG} ${imageName}:${TAGB}"
          sh "docker tag ${imageName}:${TAG} ${imageName}:${TAGC}"

          sh 'docker login -u $REGISTRY_USR -p $REGISTRY_PSW registry.gitlab.com'
          sh "docker push ${imageName} --all-tags"
        }
      }
    }
  }
}