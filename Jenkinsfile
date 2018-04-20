#!/usr/bin/groovy

// load pipeline functions
// Requires pipeline-github-lib plugin to load library from github

@Library('github.com/lachie83/jenkins-pipeline@dev')

def pipeline = new io.estrado.Pipeline()
def label = "pach-${UUID.randomUUID().toString()}"

podTemplate(
  label: label,
  envVars: [ ],
  serviceAccount: 'jenkins-jenkins',
  containers: [
    containerTemplate(name: 'jnlp',
                      image: 'jenkins/jnlp-slave:3.16-1-alpine',
                      args: '${computer.jnlpmac} ${computer.name}',
                      workingDir: '/home/jenkins',
                      resourceRequestCpu: '200m',
                      resourceLimitCpu: '300m',
                      resourceRequestMemory: '256Mi',
                      resourceLimitMemory: '512Mi'),
    containerTemplate(name: 'docker',
                      image: 'docker:1.12.6',
                      command: 'cat',
                      ttyEnabled: true),
    containerTemplate(name: 'helm',
                      image: 'lachlanevenson/k8s-helm:v2.8.2',
                      command: 'cat',
                      ttyEnabled: true),
    containerTemplate(name: 'kubectl',
                      image: 'lachlanevenson/k8s-kubectl:v1.9.6',
                      command: 'cat',
                      ttyEnabled: true
    containerTemplate(name: 'pachctl',
                      image: 'govcloud/k8s-pachctl:v1.7.0',
                      command: 'cat',
                      ttyEnabled: true)
  ],
  volumes:[
    hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock')
  ]) {

  node ('jenkins-pipeline') {

    def chart_dir = "stable/pachyderm"
    def pachd_ver = "1.7.0rc2"
    def namespace = env.BRANCH_NAME.toLowerCase()

    checkout scm

    // read in required jenkins workflow config values
    def inputFile = readFile('Jenkinsfile.json')
    def config = new groovy.json.JsonSlurperClassic().parseText(inputFile)
    println "pipeline config ==> ${config}"

    // continue only if pipeline enabled
    if (!config.pipeline.enabled) {
        println "pipeline disabled"
        return
    }

    // set additional git envvars for image tagging
    pipeline.gitEnvVars()

    // If pipeline debugging enabled
    if (config.pipeline.debug) {
      println "DEBUG ENABLED"
      sh "env | sort"

      println "Runing kubectl/helm tests"
      container('kubectl') {
        pipeline.kubectlTest()
      }
      container('helm') {
        pipeline.helmConfig()
      }
    }

    def acct = pipeline.getContainerRepoAcct(config)

    // tag image with version, and branch-commit_id
    def image_tags_map = pipeline.getContainerTags(config)

    // compile tag list
    def image_tags_list = pipeline.getMapValues(image_tags_map)

    stage ('test pachyderm deployment') {

      container('helm') {

        def String namespace

        pipeline.helmLint(chart_dir)
        pipeline.helmConfig()

        println "Running dry-run deployment"
        sh "helm upgrade --dry-run \
                         --install ${config.app.name} ${chart_dir} \
                         --set imageTag=latest,replicas=${config.app.replicas},cpu=${config.app.cpu},memory=${config.app.memory},ingress.hostname=${config.app.hostname},pachd.image.tag=${pachd_ver},pachd.worker.tag=${pachd_ver} \
                         --values values.yaml \
                         --namespace=${namespace}"

      }
    }

    stage ('publish container') {
      container('docker') {

        withCredentials([[$class          : 'UsernamePasswordMultiBinding', credentialsId: config.container_repo.jenkins_creds_id,
                        usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
          sh "docker login -u ${env.USERNAME} -p ${env.PASSWORD} ${config.container_repo.host}"
        }

        pipeline.containerBuildPub(
            dockerfile: config.container_repo.dockerfile,
            host      : config.container_repo.host,
            acct      : acct,
            repo      : config.container_repo.repo,
            tags      : image_tags_list,
            auth_id   : config.container_repo.jenkins_creds_id
        )

      }
    }

    if (env.BRANCH_NAME == 'master') {
      stage ('deploy to kubernetes') {
        container('helm') {

          sh "helm upgrade --install ${config.app.name} ${chart_dir} \
                           --set imageTag=latest,replicas=${config.app.replicas},cpu=${config.app.cpu},memory=${config.app.memory},ingress.hostname=${config.app.hostname},pachd.image.tag=${pachd_ver},pachd.worker.tag=${pachd_ver} \
                           --values values.yaml \
                           --namespace=${namespace}"

          if (config.app.test) {
            pipeline.helmTest(
              name          : config.app.name
            )
          }

          pipeline.helmDelete(
              name       : env.BRANCH_NAME.toLowerCase()
          )
        }

        container('helm') {

          sh "helm upgrade --install ${config.app.name} ${chart_dir} \
                           --set imageTag=latest,replicas=${config.app.replicas},cpu=${config.app.cpu},memory=${config.app.memory},ingress.hostname=${config.app.hostname},pachd.image.tag=${pachd_ver},pachd.worker.tag=${pachd_ver} \
                           --values values.yaml \
                           --namespace=${namespace}"

          if (config.app.test) {
            pipeline.helmTest(
              name          : config.app.name
            )
          }

          pipeline.helmDelete(
              name       : env.BRANCH_NAME.toLowerCase()
          )
        }

        container('pachctl') {

          sh "pachctl create-repo images"
          sh "pachctl put-file images master liberty.png -c -f http://imgur.com/46Q8nDz.png"
          sh "pachctl create-pipeline -f pachyderm/edges.json"

        }
      }
    }

  }
}
