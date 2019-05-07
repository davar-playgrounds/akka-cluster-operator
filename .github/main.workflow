workflow "test on PRs" {
  on = "pull_request"
  resolves = [
    "go-tools",
  ]
}

action "go-tools" {
  uses = "./.github/action/go-tools"
  args = "test -race ./..."
}

workflow "build latest on push to master" {
  on = "push"
  resolves = [
    "goreportcard",
    "push to bintray",
  ]
}

action "if master" {
  uses = "actions/bin/filter@3c0b4f0e63ea54ea5df2914b4fabf383368cd0da"
  args = "branch master"
}

action "operator-sdk" {
  uses = "./.github/action/operator-sdk"
  args = "build lightbend-docker-registry.bintray.io/lightbend/akkacluster-operator:latest"
  needs = ["if master"]
}

action "bintray login" {
  uses = "actions/docker/login@8cdf801b322af5f369e00d85e9cf3a7122f49108"
  needs = [
    "operator-sdk",
  ]
  secrets = [
    "DOCKER_REGISTRY_URL",
    "DOCKER_USERNAME",
    "DOCKER_PASSWORD",
  ]
}

action "push to bintray" {
  uses = "actions/docker/cli@8cdf801b322af5f369e00d85e9cf3a7122f49108"
  args = "push lightbend-docker-registry.bintray.io/lightbend/akkacluster-operator:latest"
  needs = ["bintray login"]
}

action "goreportcard" {
  uses = "./.github/action/curl"
  args = "-d repo=github.com/${GITHUB_REPOSITORY} https://goreportcard.com/checks"
  needs = ["if master"]
}
