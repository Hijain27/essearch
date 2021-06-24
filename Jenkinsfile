pipeline {
    agent any
 
   tools
    {
       maven "Maven"
    }
    environment {
        // This can be nexus3 or nexus2
        NEXUS_VERSION = "nexus3"
        // This can be http or https
        NEXUS_PROTOCOL = "http"
        // Where your Nexus is running
        NEXUS_URL = "localhost:8081"
        // Repository where we will upload the artifact
        NEXUS_REPOSITORY = "repositary-example"
        // Jenkins credential id to authenticate to Nexus OSS
        NEXUS_CREDENTIAL_ID = "nexus-credentials"
        
        registryCredentials = "nexus-credentials"
        registry ="localhost:9001"
        
        
    }
    
    
 stages {
      stage('checkout') {
           steps {
             
                git branch: 'master', url: 'https://github.com/Hijain27/cicdpipline.git'
                
             
            }
        }
        stage('clean package') {
           steps {
             
                sh 'mvn clean'             
          }
        }
        stage('package') {
           steps {
             
                sh 'mvn package'             
          }
        }
        stage("publish to nexus") {
            steps {
                script {
                    // Read POM xml file using 'readMavenPom' step , this step 'readMavenPom' is included in: https://plugins.jenkins.io/pipeline-utility-steps
                    pom = readMavenPom file: "pom.xml";
                    // Find built artifact under target folder
                    filesByGlob = findFiles(glob: "target/*.${pom.packaging}");
                    // Print some info from the artifact found
                    echo "${filesByGlob[0].name} ${filesByGlob[0].path} ${filesByGlob[0].directory} ${filesByGlob[0].length} ${filesByGlob[0].lastModified}"
                    // Extract the path from the File found
                    artifactPath = filesByGlob[0].path;
                    // Assign to a boolean response verifying If the artifact name exists
                    artifactExists = fileExists artifactPath;

                    if(artifactExists) {
                        echo "*** File: ${artifactPath}, group: ${pom.groupId}, packaging: ${pom.packaging}, version ${pom.version}";

                        nexusArtifactUploader(
                            nexusVersion: NEXUS_VERSION,
                            protocol: NEXUS_PROTOCOL,
                            nexusUrl: NEXUS_URL,
                            groupId: pom.groupId,
                            version: pom.version,
                            repository: NEXUS_REPOSITORY,
                            credentialsId: NEXUS_CREDENTIAL_ID,
                            artifacts: [
                                // Artifact generated such as .jar, .ear and .war files.
                                [artifactId: pom.artifactId,
                                classifier: '',
                                file: artifactPath,
                                type: pom.packaging],

                                // Lets upload the pom.xml file for additional information for Transitive dependencies
                                [artifactId: pom.artifactId,
                                classifier: '',
                                file: "pom.xml",
                                type: "pom"]
                            ]
                        );

                    } else {
                        error "*** File: ${artifactPath}, could not be found";
                    }
                }
             }
             }
        stage('Docker Build and Tag') {
            steps {
                sh 'docker build -t firstweb:latest .'
                //sh 'docker tag samplewebapp nikhilnidhi/samplewebapp:$BUILD_NUMBER'
               
          }
        }
        stage('Publish image to Docker Hub') {
          steps {
              script{
                  sh 'docker login -u admin -p Spider@27 localhost:9001'
                  sh  'docker tag firstweb:latest localhost:9001/firstweb:latest'
                  sh 'docker push localhost:9001/firstweb:latest'
                 }
        	
          }
          }
        stage('Run Docker container on Jenkins Agent') {
             
            steps 
                        {
                sh "docker run -d -p 8003:8080 firstweb:latest"
 
            }
        }
  }
}
