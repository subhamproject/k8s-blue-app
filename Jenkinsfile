pipeline{
        agent any
        stages {
                stage('Build') {
                        steps {
                                sh './image_build.sh'
                        }
                }
             stage('Push') {
                        steps {
                                sh './image_push.sh'
                        }
                }
              stage('Deploy') {
                        steps {
                                sh './deploy.sh'
                        }
                }
}
}
