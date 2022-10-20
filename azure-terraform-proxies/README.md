# Azure Proxies



**Tools:**
* [Terraform](https://www.terraform.io/) to automatically create/install software/destroy Azure Proxy Nodes
* Proxy server - [Goproxy](https://github.com/snail007/goproxy)
* Ubuntu 16.04 server
* Systemd to convert goproxy process to the system daemon service


## Installation

* Clone the repo: `$ git clone https://github.com/drevie/azure-terraform-proxies.git`
* Install [CLI Terraform](https://www.terraform.io/intro/getting-started/install.html):

```bash
# example for 0.12.5 version. Check latest here https://www.terraform.io/downloads.html

cd /tmp && wget https://releases.hashicorp.com/terraform/0.12.5/terraform_0.12.5_linux_amd64.zip
sudo unzip terraform_0.12.5_linux_amd64.zip -d /usr/local/bin
rm terraform_0.12.5_linux_amd64.zip
```

* Run `$ terraform init` inside of project directory.

## Configuration

**1)** Provide your `AZURE_SUBSCRIPTION_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, and `AZURE_TENANT_ID` credentials to manage azure resources. It is good practice to have separate user roles with restricted permissions for different projects.

[Check here](https://docs.microsoft.com/en-us/azure/media-services/previous/media-services-portal-get-started-with-aad) how to create a new azure user role and copy credentials. Then create file `terraform.tfvars` (inside of project directory) and put there `AZURE_SUBSCRIPTION_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, and `AZURE_TENANT_ID`, example:

```
AZURE_SUBSCRIPTION_ID = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
AZURE_CLIENT_ID       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
AZURE_CLIENT_SECRET   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
AZURE_TENANT_ID       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```


## Settings

All default settings located in the `config.tf` file. If you want to change the value of variable, don't edit `config.tf` file, instead put your configuration to the `terreform.tfvars` file (create this file if it doesn't exists). Use format `VARIABLE_NAME="value"` inside of `terreform.tfvars` file.

You'll probably want to tweak following settings:

* `AZURE_INSTANCES_COUNT` - the number of proxy servers to create. Default is 5.
* `AZURE_DEFAULT_REGION` - region of instances (proxy servers) where they will be created. Default is `eastus`. Check [available regions here](https://azure.microsoft.com/en-us/global-infrastructure/locations/). 
* `PROXY_TYPE` - type of proxy server. Default is `https` (HTTP/HTTPS) . If you need socks5 anonymous proxy instead, set variable to `socks`.
* `PROXY_PORT` - port of proxy server. Default is `46642`.
* `PROXY_USER` and `PROXY_PASSWORD` - set these variables if you want proxy server use authorization. Defaut is empty (proxy without authorization).

## Usage
### Command line
#### apply

Command `$ terraform apply` will create Azure VMs instances and make instances setup (install and run goproxy server). From output you'll get IP addresses of created instances. Example:

```
$ terraform apply
...

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

instances = [
    54.225.911.634,
    31.207.37.49,
    53.235.228.205,
    52.31.233.217,
    35.213.244.142
]
```

Use these IP addresses to connect to proxy servers (proxy type, port and user/password settings were applied from config.tf, see Settings above).

#### output

Command `$ terraform output` will print IP addresses of created instances. Example:

```
$ terraform output

instances = [
    54.225.911.634,
    31.207.37.49,
    53.235.228.205,
    52.31.233.217,
    35.213.244.142
]
```

#### destroy

Command `$ terraform destroy` will destroy all created instances. Example:

```
$ terraform destroy
...

azurerm_virtual_machine.ProxyNode[4]: Destruction complete after 57s
azurerm_virtual_machine.ProxyNode[0]: Destruction complete after 57s
azurerm_virtual_machine.ProxyNode[3]: Destruction complete after 57s
azurerm_virtual_machine.ProxyNode[2]: Destruction complete after 57s
azurerm_virtual_machine.ProxyNode[1]: Destruction complete after 57s

Destroy complete! Resources: 7 destroyed.
```

## License

[MIT](https://opensource.org/licenses/MIT)
