module "k8s" {
  source = "./modules/k8s"
}

module "jenkins" {
  source = "./modules/jenkins"
}
