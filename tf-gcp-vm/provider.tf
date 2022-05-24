provider "google" {
  credentials = file("auth.json")

  project = "kypo-lite"
  region  = "europe-west3"
  zone    = "europe-west3-c"
}
