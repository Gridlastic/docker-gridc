# Gridlastic Connect Tunnel Client (gridc)
Securely connect your private [Gridlastic][gridlastic] selenium grid to your test environment. Test web sites on localhost using http or https (no need to deploy a ssl certificate) and https sites via TCP. Access your selenium grid hub via localhost.


## Features

  * **Small**: Built using [Alpine][alpine], about 20mb in size.
  * **Simple**: Use environment variables to start encrypted tunnels to your local/remote/docker test environment in seconds.
  * **Secure**: Tunnel endpoints accessible only by your private Gridlastic selenium grid nodes. Runs as non-root user with a random UID `6838` (to avoid mapping to an existing UID).

## Quick demo start for Docker Desktop MAC/Windows

    $ docker run --rm -it -p 3030:3030 --name running-gridc -e GRIDC_ENDPOINT_SUBDOMAIN= -e GRIDC_USERNAME= -e GRIDC_ACCESS_KEY= -e GRIDC_PROTOCOL=https -e GRIDC_SUBDOMAIN=hostmachine-hello-world -e GRIDC_ADDR_DOMAIN=host.docker.internal -e GRIDC_ADDR_PORT=8001 -e GRIDC_API=3030 gridlastic/docker-gridc

The above docker command can be copied pre-filled with credentials from your Gridlastic dashboard after grid launch. The credentials `GRIDC_ENDPOINT_SUBDOMAIN`, `GRIDC_USERNAME` and `GRIDC_ACCESS_KEY` are all available after launch of your Gridlastic selenium grid. On the host machine, creates a tunnel to a site (existing or not) on `localhost:8001`. If you have a site active on `localhost:8001` you can run tests to it or start a site on port `8001` like

    $ docker run --rm -p 8001:80 --detach --name test-gridc-site gridlastic/docker-hello-world

To tunnel to the test site use this in your selenium test code:

    $ driver().get("https://hostmachine-hello-world.<GRIDC_ENDPOINT_SUBDOMAIN>.gridlastic.com:8091");
    

Use the client [Rest API][gridlastic-connect-api] to dynamically create more tunnels or get active tunnels like:

```
http://localhost:3030/api/tunnels
```


## Environment variables

Configure your tunnel via environment variables (via `-e`):

  * `GRIDC_ENDPOINT_SUBDOMAIN` - Gridlastic Connect subdomain (different from your selenium grid hub subdomain), see your Gridlastic dashboard after you launched your grid. 
  * `GRIDC_USERNAME` - Gridlastic username, see your Gridlastic dashboard after you launched your grid. 
  * `GRIDC_ACCESS_KEY` - Gridlastic access key, see your Gridlastic dashboard after you launched your grid. 
  * `GRIDC_PROTOCOL` - Can be `https`, `http`  or `tcp`. If set to `tcp`, Gridlastic Connect will allocate a port instead of a subdomain and proxy TCP requests directly to your application. Endpoint access for `https` is on port `8091` and for `http` port `8090`
  * `GRIDC_SUBDOMAIN` - Is used to create the endpoint for your selenium grid nodes. Must be unique (real time) per selenium grid and a valid single DNS string (no dots and 3-63 characters) to avoid tunnel name conflicts. Subdomains are associated with protocol `http` and `https`. If not specified a random value is assigned by the server. 
  * `GRIDC_ADDR_DOMAIN` - Domain name/IP/docker container name of service to tunnel to, leave empty if service is on `localhost`.
  * `GRIDC_ADDR_PORT` - Port of service to tunnel to, like `80`
  * `GRIDC_HUB` - Port to tunnel to your Gridlastic selenium grid hub, like `4444`. Optional.
  * `GRIDC_API` - Activates client [Rest API][gridlastic-connect-api] on port, like `3030`. Optional.
  * `GRIDC_START_CONFIG_TUNNELS` - If set to `all` starts all defined tunnels in the configuration file. Specify individual tunnels for selective starts like `-e "GRIDC_START_CONFIG_TUNNELS=tunnel-1 tunnel-2"`. Note: special behavior with `GRIDC_CONFIG_SUBDOMAIN_UUID_PREFIX`
  * `GRIDC_CONFIG_SUBDOMAIN_UUID_PREFIX` - Use this variable to create unique subdomain endpoints. If empty defaults to `$HOSTNAME` (container ID) when used with `GRIDC_START_CONFIG_TUNNELS`. Tip: start the container(s) from your test runner with your own unique subdomain prefix that you can use in your selenium tests.


## EXAMPLES

## Start an additional gridc/tunnel container linking to the docker-hello-world container above, accessing the site on internal container port 80


If you have an web service running in a container named `test-gridc-site` listening on internal container port 80:

    $ docker run --rm -it --link test-gridc-site --name running-gridc-linked-to-test-site -e GRIDC_ENDPOINT_SUBDOMAIN= -e GRIDC_USERNAME= -e GRIDC_ACCESS_KEY= -e GRIDC_PROTOCOL=https -e GRIDC_SUBDOMAIN=container-hello-world -e GRIDC_ADDR_DOMAIN=test-gridc-site -e GRIDC_ADDR_PORT=80 gridlastic/docker-gridc

In your selenium code you access the tunnel like:


    $ driver().get("https://container-hello-world.<GRIDC_ENDPOINT_SUBDOMAIN>.gridlastic.com:8091");


## Use a custom gridc configuration file

Replace the `config-template.cfg` file with your own. All environmental variables are substituted automatically upon container start using `envsubst` so you can also add your own variables.

    $ docker run --rm -it -v /local/path/to/custom-config-template.cfg:/home/gridc/config-template.cfg -e GRIDC_ENDPOINT_SUBDOMAIN= -e GRIDC_USERNAME= -e GRIDC_ACCESS_KEY= -e GRIDC_START_CONFIG_TUNNELS=all gridlastic/docker-gridc



Example `custom-config-template.cfg`

```
server_addr: ${GRIDC_ENDPOINT_SUBDOMAIN}.gridlastic.com:443
http_proxy:
username:
password:
tunnels:
  hostmachine_port_8001:
    subdomain: ${GRIDC_CONFIG_SUBDOMAIN_UUID_PREFIX}-hostmachine-8001
    proto:
      https: host.docker.internal:8001
```

Note that the line `server_addr: ${GRIDC_ENDPOINT_SUBDOMAIN}.gridlastic.com:443` must always be present in any custom config file and is the only line in the default `config-template.cfg`. The variable `GRIDC_CONFIG_SUBDOMAIN_UUID_PREFIX` has special behavior when used with `GRIDC_START_CONFIG_TUNNELS`, see environmental variables. Also, you can provide the credentials in the config file although we recommend you use environment variables. http_proxy can be used to reach Gridlastic via a corporate proxy. An alternative to creating tunnels using a configuration file is to use the [Rest API][gridlastic-connect-api]. 



## Start TCP tunnel to a local https site


    $ docker run --rm -it -e GRIDC_ENDPOINT_SUBDOMAIN= -e GRIDC_USERNAME= -e GRIDC_ACCESS_KEY= -e GRIDC_PROTOCOL=tcp -e GRIDC_ADDR_DOMAIN=host.docker.internal -e GRIDC_ADDR_PORT=443 gridlastic/docker-gridc

TCP endpoints do not have subdomains but are issued a random port between `9000-9999` by the server. To tunnel to the test site use this in your selenium test code:

    $ driver().get("https://<GRIDC_ENDPOINT_SUBDOMAIN>.gridlastic.com:9xxx");

where the port `9xxx` is randomly assigned or can be requested in the config file like:

```
tunnels:
  my_https_site:
    remote_port: 9xxx
    proto:
      tcp: host.docker.internal:443
```
Also, when mapping to a https site serving valid or self signed ssl, the domain names do not match so the browser displays a certificate error message which can be resolved by adding flags to your selenium code like for 

Chrome (options):

    $ options.addArguments("ignore-certificate-errors");


Firefox (profile):

    $ profile.setAcceptUntrustedCertificates(true);


Note that this method is for internal direct IP https sites with no redirects etc. To test production/other remote sites see [Github repo docker-gridc-squid][docker-gridc-squid]. Keep in mind that unlike subdomains which have unlimited unique endpoint capability, tcp ports are limited and must also be coordinated to avoid tunnel conflicts if they are specifically requested in the config file. Leave `remote_port:` empty in the config file for randomly assigned. An alternative to creating tunnels using a configuration file is to use the [Rest API][gridlastic-connect-api].  Read more about [Gridlastic Connect TCP tunneling][gridlastic-connect-tcp].

## Test a remote https site using a standard forwarding proxy like Squid

See [Github repo docker-gridc-squid][docker-gridc-squid]

 

## Create multiple tunnels in docker compose (see [Github repo docker-gridc][docker-gridc] for docker-compose.yml and custom-config-template.cfg)

Example docker-compose.yml

```
version: '3.8'
services:
  test-web-site:
    image: "gridlastic/docker-hello-world"
    ports:
      - "8001:80"

  gridc-config-tunnels:
    image: gridlastic/docker-gridc
    volumes:
      - ./custom-config-template.cfg:/home/gridc/config-template.cfg
    environment:
      GRIDC_ENDPOINT_SUBDOMAIN: ${GRIDC_ENDPOINT_SUBDOMAIN}
      GRIDC_USERNAME: ${GRIDC_USERNAME}
      GRIDC_ACCESS_KEY: ${GRIDC_ACCESS_KEY}
      GRIDC_CONFIG_SUBDOMAIN_UUID_PREFIX: ${GRIDC_CONFIG_SUBDOMAIN_UUID_PREFIX}
      GRIDC_START_CONFIG_TUNNELS: all

    

  test-web-site-1:
    image: "gridlastic/docker-hello-world"

  test-web-site-2:
    image: "gridlastic/docker-hello-world"
 
    
  gridc-tunnel-to-web-site-1:
    image: gridlastic/docker-gridc
    environment:
      GRIDC_ENDPOINT_SUBDOMAIN: ${GRIDC_ENDPOINT_SUBDOMAIN}
      GRIDC_USERNAME: ${GRIDC_USERNAME}
      GRIDC_ACCESS_KEY: ${GRIDC_ACCESS_KEY}
      GRIDC_PROTOCOL: https
      GRIDC_SUBDOMAIN: ${GRIDC_CONFIG_SUBDOMAIN_UUID_PREFIX}-test-web-site-1
      GRIDC_ADDR_DOMAIN: test-web-site-1
      GRIDC_ADDR_PORT: 80
      
  gridc-tunnel-to-web-site-2:
    image: gridlastic/docker-gridc
    environment:
      GRIDC_ENDPOINT_SUBDOMAIN: ${GRIDC_ENDPOINT_SUBDOMAIN}
      GRIDC_USERNAME: ${GRIDC_USERNAME}
      GRIDC_ACCESS_KEY: ${GRIDC_ACCESS_KEY}
      GRIDC_PROTOCOL: https
      GRIDC_SUBDOMAIN: ${GRIDC_CONFIG_SUBDOMAIN_UUID_PREFIX}-test-web-site-2
      GRIDC_ADDR_DOMAIN: test-web-site-2
      GRIDC_ADDR_PORT: 80
```

Start:

```
Linux/Mac
export GRIDC_ENDPOINT_SUBDOMAIN=<your Gridlastic Connect subdomain>
export GRIDC_USERNAME=<your Gridlastic grid username>
export GRIDC_ACCESS_KEY=<your Gridlastic grid access_key>
export GRIDC_CONFIG_SUBDOMAIN_UUID_PREFIX=x-y-z


Windows (CMD)
set GRIDC_ENDPOINT_SUBDOMAIN=<your Gridlastic Connect subdomain>
set GRIDC_USERNAME=<your Gridlastic grid username>
set GRIDC_ACCESS_KEY=<your Gridlastic grid access_key>
set GRIDC_CONFIG_SUBDOMAIN_UUID_PREFIX=x-y-z


Windows (Powershell)
$Env:GRIDC_ENDPOINT_SUBDOMAIN = "<your Gridlastic Connect subdomain>"
$Env:GRIDC_USERNAME = "<your Gridlastic grid username>"
$Env:GRIDC_ACCESS_KEY = "<your Gridlastic grid access_key>"
$Env:GRIDC_CONFIG_SUBDOMAIN_UUID_PREFIX = "x-y-z"
```


    $ docker-compose up


Will create 3 web site containers and 3 gridc containers with 3 tunnel endpoints to the test web sites that you can access in your selenium code like:

    $ driver().get("https://x-y-z-hostmachine-8001.<GRIDC_ENDPOINT_SUBDOMAIN>.gridlastic.com:8091");
    $ driver().get("https://x-y-z-test-web-site-1.<GRIDC_ENDPOINT_SUBDOMAIN>.gridlastic.com:8091");
    $ driver().get("https://x-y-z-test-web-site-2.<GRIDC_ENDPOINT_SUBDOMAIN>.gridlastic.com:8091");
    
 In this example you could also specify all 3 tunnels in the config file and use a single gridc container. You can also [programmatically][gridlastic-connect-api] create tunnels using just one client. 
    





## Use the Client Rest API to create tunnels on the fly 

    $ docker run --rm -it -p 3030:3030 --name gridc-api-endpoint -e GRIDC_ENDPOINT_SUBDOMAIN= -e GRIDC_USERNAME= -e GRIDC_ACCESS_KEY= -e GRIDC_API=3030 -e GRIDC_START_CONFIG_TUNNELS=all  gridlastic/docker-gridc

    
Note: unless the `GRIDC_API` parameter is passed along with tunnel parameters or the `GRIDC_HUB` parameter, the parameter `GRIDC_START_CONFIG_TUNNELS` must be set to `all`. Read more about how to use the [Rest API][gridlastic-connect-api].


## Start the selenium grid hub endpoint in its own container


    $ docker run --rm -it -p 4444:4444 --name gridc-hub-endpoint -e GRIDC_ENDPOINT_SUBDOMAIN= -e GRIDC_USERNAME= -e GRIDC_ACCESS_KEY= -e GRIDC_HUB=4444 gridlastic/docker-gridc

Hub API access endpoint in your selenium code becomes `http://<USERNAME:ACCESS_KEY>@localhost:4444/wd/hub` or if you started your grid with the option "Gridlastic Connect Hub Endpoint" selected to "hub credentials disabled" you can drop the credentials and use `http://localhost:4444/wd/hub`. Access the grid console like `http://localhost:4444/grid/console`. 



## Feedback

Report issues/questions/feature requests at `support@gridlastic.com`.



[gridlastic]:       	https://www.gridlastic.com/
[gridlastic-connect]:	https://www.gridlastic.com/gridlastic-connect.html
[gridlastic-connect-tcp]:	https://www.gridlastic.com/gridlastic-connect.html#tcp
[gridlastic-connect-api]:	https://www.gridlastic.com/gridlastic-connect.html#dynamic_tunnel_creation
[alpine]:				https://registry.hub.docker.com/_/alpine
[docker-gridc]:   		https://github.com/gridlastic/docker-gridc
[docker-gridc-squid]:   https://github.com/gridlastic/docker-gridc-squid