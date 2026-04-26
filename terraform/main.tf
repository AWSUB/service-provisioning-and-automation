module "jenkins" {
  source = "./modules/jenkins"
}

module "k8s" {
  source                    = "./modules/k8s"
  jenkins_to_k8s_public_key = module.jenkins.public_key
}

