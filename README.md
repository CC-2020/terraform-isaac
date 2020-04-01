# Tarea de Terraform en GCP
En esta tarea se va a crear una instancia principal desde la que se hará el despliegue de una infraestructura mediante el uso de Terraform.

La infraestructura a desarrollar consiste en la creación de una red privada en la que se creará una instancia con Apache, PHP y MySQL.

## Pasos
A continuación, se detallan los pasos que se han seguido para la realización de la tarea.



### Creación de la instancia principal
- Esta instancia es donde se instalará y utilizará Terraform. Creamos una instancia con las siguientes características:
  - __Tipo de máquina__: `n1-standard-1 (1 vCPU, 3,75 GB de memoria)`.
  - __S. O.__: `Ubuntu 18.04`.
  - __Red__: `default`.
  - __Zona__: `europe-west1-b`.

### Configuración de la instancia principal
- Instalamos Terraform:
  ```
  $ sudo apt update
  $ sudo apt-get install wget unzip
  $ wget https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
  $ sudo unzip ./terraform_0.12.24_linux_amd64.zip -d /usr/local/bin/
  ```

- Comprobamos que la instalación es correcta:
  ```
  $ terraform -v
    Terraform v0.12.24
  ```

- Definimos el proovedor:
  - Vamos a GCP y obtenemos la ID del proyecto (parte superior izquierda, pulsamos sobre el nombre del proyecto actual y en la ventana emergente aparecerá a su derecha el ID).
  - Obtenemos un fichero `JSON` de credenciales para acceder a nuestro proyecto. Para ello, accedemos a la siguiente dirección [https://console.cloud.google.com/apis/credentials/serviceaccountkey ](https://console.cloud.google.com/apis/credentials/serviceaccountkey ) y creamos una clave de cuenta de servicio, hay que elegir el servicio `Compute Engine default service account` y en tipo de clave `JSON`. Descargamos nuestro fichero en el equipo local y, en nuestra instancia, creamos un fichero llamado `account.json` en el que copiamos el contenido del fichero que hemos descargado.

  - Con los datos anteriores ya podemos crear un fichero para permitir a Terraform trabajar en nuestro proyecto de GCP. Creamos un fichero `proveedor.tf` para definir GCP como proveedor:
    ```
    $ nano proovedor.tf
    provider"google" {
        credentials= "${file("account.json")}"
        project= "ID_PROYECTO"
        region= "europe-west1"
        zone= "europe-west1-b"
    }
    ```
    donde `ID_PROYECTO` es la ID consultada en el primer punto de la sección actual.

- Configuramos Terraform para que instale los _plugins_ necesarios en base al fichero de configuración anterior:
  ```
  $ terraform init

    Initializing the backend...

    Initializing provider plugins...
    - Checking for available provider plugins...
    - Downloading plugin for provider "google" (hashicorp/google) 3.15.0...

    The following providers do not have any version constraints in configuration,
    so the latest version was installed.

    To prevent automatic upgrades to new major versions that may contain breaking
    changes, it is recommended to add version = "..." constraints to the
    corresponding provider blocks in configuration, with the constraint strings
    suggested below.

    * provider.google: version = "~> 3.15"

    Terraform has been successfully initialized!

    You may now begin working with Terraform. Try running "terraform plan" to see
    any changes that are required for your infrastructure. All Terraform commands
    should now work.

    If you ever set or change modules or backend configuration for Terraform,
    rerun this command to reinitialize your working directory. If you forget, other
    commands will detect it and remind you to do so if necessary.
  ```

### Ficheros para el despliegue de la infraestructura
- Nuestra VPC, llamada `terraform-vpc`, cuenta con el rango CIDR: `10.2.0.0/16` y se va situar en la región: `europe-west1`. Dentro de esta región reservaremos una IP estática para la instancia que vamos a crear, concretamente, la IP: `10.2.0.10`. Toda esta información la introducimos en el fichero `vpc.tf` con el siguiente contenido:

  ```
  $ nano vpc.tf
    resource "google_compute_network" "vpc" {
        name                    = "terraform-vpc"
        auto_create_subnetworks = false
    }
    
    resource "google_compute_subnetwork" "subnet" {
        name          = "terraform-vpc-subnet"
        ip_cidr_range = "10.2.0.0/16"
        region        = "europe-west1"
        network       = google_compute_network.terraform-vpc.self_link
    }

    resource "google_compute_address" "server-ip" {
        name         = "server-ip"
        subnetwork   = google_compute_subnetwork.subnet.id
        address_type = "INTERNAL"
        address      = "10.2.0.10"
        region       = "europe-west1"
    }
    
  ```

- Creamos una reglas para el _firewall_ que nos permita el tráfico interno y conexiones HTTP, ICMP y SSH externas añadiendo al fichero anterior el siguiente contenido:
  ```
  $ nano vpc.tf
    resource "google_compute_firewall" "terraform-allow-icmp-ssh-http" {
        name          = "terraform-allow-icmp-ssh-http"
        network       = google_compute_network.terraform-vpc.name
        source_ranges = ["0.0.0.0/0"]

        allow {
            protocol = "icmp"
        }

        allow {
            protocol = "tcp"
            ports    = ["22", "80"]
        }

    }

    resource "google_compute_firewall" "terraform-allow-all-internal" {
        name          = "terraform-allow-all-internal"
        network       = google_compute_network.terraform-vpc.name
        source_ranges = ["10.2.0.0/16"]

        allow {
            protocol = "icmp"
        }

        allow {
            protocol = "tcp"
            ports    = ["0-65535"]
        }

        allow {
            protocol = "udp"
            ports    = ["0-65535"]
        }

    }

  ```

- Ejecutamos Terraform para que nos cree la VPC:

  ```
  $ terraform apply
  ```

- Creamos una instancia del mismo tipo que la instancia principal pero dentro de la red creada anteriormente con la IP reservada y le instalamos Apache, MySQL y PHP. 
  Para ello, creamos el fichero `instancia.tf` con el siguiente contenido:
  ```
  $ nano instancia.tf
    resource "google_compute_instance" "servidor" {
    name         = "servidor"
    machine_type = "n1-standard-1"
    zone         = "europe-west1-b"

    boot_disk {
        initialize_params {
        image = "ubuntu-os-cloud/ubuntu-1804-lts"
        }
    }

    network_interface {
        subnetwork = google_compute_subnetwork.subnet.id
        network_ip = google_compute_address.server-ip.address
        access_config {
        // Ephemeral IP
        }
    }

    metadata_startup_script = "sudo apt update && sudo apt install apache2 mysql-server php php-mysql -y"

    }
  ```

- Ejecutamos Terraform para que nos cree la instancia:

  ```
  $ terraform apply
  ```

- Podemos comprobar si todo ha salido correctamente accediendo a la IP pública de la instancia que se ha creado para verificar la instalación de Apache.
