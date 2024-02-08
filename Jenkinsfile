def imageName = "registry.gitlab.com/grupo-loja/jks-worker"
def semantic = "registry.gitlab.com/grupo-loja/semantic-release:prd"

pipeline {
  agent {
    kubernetes {
      label 'jenkins-pod'
    }
  }
  stages {
    stage('Build Docker Image') {
      when{
        not{
          branch 'main'
        }
      }
      steps {
        script {
          def TAG = (env.BRANCH_NAME == "develop" ) ? 'dev' : 'other'
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
        GH_TOKEN = credentials('gh-token')
        REGISTRY = credentials('gl-gitlab')
      }
      when {
        branch 'develop'
      }
      steps {
        sh 'docker login -u $REGISTRY_USR -p $REGISTRY_PSW registry.gitlab.com'
        sh "docker run -v `pwd`:/opt/app -e GH_TOKEN=$GH_TOKEN ${semantic} run"
      }
    }    

    stage('Tagging Image') {
      parallel {
        stage('Tagging Dev') {
          when {
            branch 'develop'
          }
          steps {
            script {
              def TAGA = sh(returnStdout: true, script: './scripts/getTag.sh 3').trim()
              def TAGB = sh(returnStdout: true, script: './scripts/getTag.sh 2').trim()
              def TAGC = sh(returnStdout: true, script: './scripts/getTag.sh 1').trim()

              def TAG = 'dev'

              sh "docker tag ${imageName}:${TAG} ${imageName}:${TAGA}"
              sh "docker tag ${imageName}:${TAG} ${imageName}:${TAGB}"
              sh "docker tag ${imageName}:${TAG} ${imageName}:${TAGC}"
            }
          }
        }
        stage('Tagging Prd') {
          when {
            branch 'main'
          }
          steps {
            script {
              def TAG = sh(returnStdout: true, script: './scripts/getTag.sh 3').trim()

              sh "docker pull ${imageName}:${TAG}"
              sh "docker tag ${imageName}:${TAG} ${imageName}:prd"
            }
          }
        }
      }
    }
    stage('Deploy'){
      when{
        anyOf {
          branch 'main'
          branch 'develop'
        }
      }
      steps{
        script{
          sh "docker push ${imageName} --all-tags"
        }
      }
    }
  }
}