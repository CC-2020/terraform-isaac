provider"google" {
    credentials= "${file("account.json")}"
    project= "ID_PROYECTO"
    region= "europe-west1"
    zone= "europe-west1-b"
  }