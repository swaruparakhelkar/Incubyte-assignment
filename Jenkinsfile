node{
    def app
    def product = "incubyte-assignment"
    stage('clean workspace'){
        echo 'Clean Workspace'
        cleanWs()
    }
    stage('Clone repository') {
        echo "Cloning git repository to workspace"
        checkout([$class: 'GitSCM', branches: [[name: '*/main']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'incubyte_github_token', url: "https://github.com/Lucifer0143/${product}.git"]]])
    }

    stage('Build image') {
        echo 'Build the docker flask image'
        app = docker.build("mpatel143/${product}")
    }

    stage('Test image') {
        echo 'Test the docker flask image'
        app.inside {
            sh 'python test.py'
        }
    }
    stage('Push image') {
        echo 'Push image to the docker hub'
        docker.withRegistry('https://registry.hub.docker.com', 'docker_cred') {
            app.push("${env.BUILD_NUMBER}")
            app.push("latest")
        }
    }
    stage('Update the deployment file'){
    echo 'update the deployment files to re-apply it on deployment'

     sh "sed -i s/%IMAGE_NO%/${env.BUILD_NUMBER}/g flask-deployment.yaml"
     sh "cat flask-deployment.yaml"
    }
    stage('Deploy the flask app'){
      echo 'Deploy the flask image at AWS EKS, on Cluster already present in EKS'
      withCredentials([[
              $class: 'AmazonWebServicesCredentialsBinding',
              credentialsId: 'AWS_CREDS',
              accessKeyVariable: 'AWS_ACCESS_KEY_ID',
              secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
          ]]){
      
      sh '''
              PRODUCT="incubyte-assignment"
              kubectl version --short --client
              aws eks --region ap-south-1 update-kubeconfig --name $PRODUCT-cluster
              kubectl get svc
              echo "Execute the deployment"
              kubectl get namespace $PRODUCT
              if [ $? -eq 0 ]; then
                  echo "namespace $PRODUCT already exists"
                  kubectl get all -n $PRODUCT
              else
                  echo "create $PRODUCT namespace"
                  kubectl create namespace $PRODUCT
              fi
              echo "Apply the deployment"
              kubectl apply -f flask-deployment.yaml
              echo "Create the flask service"
              kubectl apply -f flask-service.yaml
              sleep 5s
              echo "\n\n Deployment details \n\n"
              kubectl get all -n $PRODUCT

              echo "Deployment done successfully"
        '''
    }  }
    stage('Deployment Test'){
        echo 'Test the deployment using curl on service external address'
        withCredentials([[
                $class: 'AmazonWebServicesCredentialsBinding',
                credentialsId: 'AWS_CREDS',
                accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
            ]]){
        sh '''
                PRODUCT="incubyte-assignment"
                echo $PATH
                kubectl get all -n $PRODUCT
                sleep 60s
                EXTERNAL_IP=`kubectl get service flask-service -n $PRODUCT | awk 'NR==2 {print $4}'`
                STATUS_CODE=`curl -s -o /dev/null -w "%{http_code}" http://${EXTERNAL_IP}:5000`
                echo $STATUS_CODE
                if [ $STATUS_CODE -eq 200 ]; then
                    echo "Deployment done successfully"
                else
                    echo "\n\nApplication not responding deployment Failed\n\n "
                    exit 1
                fi
          '''
        } }
        
        stage('Clean docker images from local') {
        
      sh 'docker rmi $(docker images -q -a) --force | true'

  }
}