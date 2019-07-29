<p align="center"><a href="https://github.com/crazy-max/docker-ejtserver" target="_blank"><img height="128"src="https://raw.githubusercontent.com/crazy-max/docker-ejtserver/master/.res/docker-ejtserver.jpg"></a></p>

<p align="center">
  <a href="https://hub.docker.com/r/crazymax/ejtserver/"><img src="https://img.shields.io/badge/dynamic/json.svg?label=version&query=$.results[1].name&url=https://hub.docker.com/v2/repositories/crazymax/ejtserver/tags&style=flat-square" alt="Latest Version"></a>
  <a href="https://travis-ci.com/crazy-max/docker-ejtserver"><img src="https://img.shields.io/travis/com/crazy-max/docker-ejtserver/master.svg?style=flat-square" alt="Build Status"></a>
  <a href="https://hub.docker.com/r/crazymax/ejtserver/"><img src="https://img.shields.io/docker/stars/crazymax/ejtserver.svg?style=flat-square" alt="Docker Stars"></a>
  <a href="https://hub.docker.com/r/crazymax/ejtserver/"><img src="https://img.shields.io/docker/pulls/crazymax/ejtserver.svg?style=flat-square" alt="Docker Pulls"></a>
  <a href="https://quay.io/repository/crazymax/ejtserver"><img src="https://quay.io/repository/crazymax/ejtserver/status?style=flat-square" alt="Docker Repository on Quay"></a>
  <a href="https://www.codacy.com/app/crazy-max/docker-ejtserver"><img src="https://img.shields.io/codacy/grade/b805833749d54c89ae0584cda5c6cd4d.svg?style=flat-square" alt="Code Quality"></a>
  <br /><a href="https://www.patreon.com/crazymax"><img src="https://img.shields.io/badge/donate-patreon-fb664e.svg?style=flat-square" alt="Support me on Patreon"></a>
  <a href="https://www.paypal.me/crazyws"><img src="https://img.shields.io/badge/donate-paypal-7057ff.svg?style=flat-square" alt="Donate Paypal"></a>
</p>

## About

🐳 [EJT License Server](https://www.ej-technologies.com/license/files) Docker image based on Alpine Linux.<br />
If you are interested, [check out](https://hub.docker.com/r/crazymax/) my other 🐳 Docker images!

## Features

* License server customizable via environment variables
* Persistence of configuration in a single directory
* A custom base url can be provided to download the ejtserver tarball

## Docker

### Environment variables

* `TZ` : The timezone assigned to the container (default `UTC`)
* `PUID` : License server user id (default `1000`)
* `PGID` : License server group id (default `1000`)
* `EJT_ACCOUNT_USERNAME` : Username of your EJT account to download the license server. Can be empty if you use a custom base url to download the ejtserver tarball without HTTP authentication
* `EJT_ACCOUNT_PASSWORD` : Password linked to the username
* `EJTSERVER_VERSION` : EJT License Server version to install. See the [official changelog](https://www.ej-technologies.com/license/changelog.html) for a curated list. (default `1.13.1`)
* `EJTSERVER_DOWNLOAD_BASEURL` : Base url where EJT License Server unix tarball can be downloaded (default `https://licenseserver.ej-technologies.com`)
* `EJTSERVER_LICENSES` : Your floating licenses (comma delimited)
* `EJTSERVER_DISPLAY_HOSTNAMES` : If you want to see host names instead of IP addresses (default `false`)
* `EJTSERVER_LOG_LEVEL` : [Log4J log level](https://logging.apache.org/log4j/2.x/manual/customloglevels.html) of the EJT License Server (default `INFO`)

### Volumes

* `/data` : Contains configuration and the downloaded EJT License Server unix tarball

In this folder you will find those files :

* `ejtserver_unix_*.tar.gz` : The downloaded EJT License Server unix tarball
* `ip.txt` : If you would like to allow only certain IP addresses, enter one IP address per line. If no IP addresses are entered, all IP addresses will be allowed. You can specify IP masks, such as 192.168.2.*
* `users.txt` : If you would like to allow only certain user names, please enter one user name per line. If no user names are entered, all user names will be allowed

### Ports

* `11862` : License server port

### Commands

You also have access to these commands from the container :

* `ejtserver` : This is the license server the daemon launch script. Commands available : `start|stop|run|run-redirect|status|restart|force-reload`.
* `admin` : Admin tool command line based of ejtserver. It allows you to list all active connections and to terminate selected connections. In addition, you can check out a temporary license for use in environments that have no access to the floating license server

Usage :

```bash
docker-compose exec ejtserver admin list
```

## Usage

Docker compose is the recommended way to run this image. You can use the following [docker compose template](examples/compose/docker-compose.yml), then run the container :

```bash
docker-compose up -d
docker-compose logs -f
```

Or use the following minimal command :

```bash
docker run -d -p 11862:11862 --name ejtserver \
  -e TZ="Europe/Paris" \
  -e EJT_ACCOUNT_USERNAME="my_ejt_username" \
  -e EJT_ACCOUNT_PASSWORD="my_ejt_password" \
  -e EJTSERVER_LICENSES="0-0123-0123456789" \
  -v $(pwd)/data:/data \
  crazymax/ejtserver:latest
```

## Update

Recreate the container whenever i push an update :

```bash
docker-compose pull
docker-compose up -d
```

## Notes

### How to use your floating license ?

[ej-technologies'](https://www.ej-technologies.com/) products offer a floating license mode in the license dialog. Choose `Help -> Enter License Key` from the main menu in the JProfiler GUI or the install4j IDE and select the <b>Floating license</b> radio button.

The "Name" and "Company" fields are informational only, unless you choose to restrict the allowed values for the "Name" field as described in README.TXT. In the license server field you have to enter the hostname of the computer where the license server is running. Instead of a host name, an IP address can also be used.

If have a floating license for a certain major version of a product, you can use older versions of the same product with that floating license as well.

Should you require any additional assistance, please contact *support@ej-technologies.com*

### User groups

If you want to partition keys to different groups of users, you can define groups in the file `license.txt` and the access control files `users.txt` and `ip.txt` by inserting group headers :

```
   [group]
```

All entries after a group header belong to that group until a new group is started. If no group has been started, entries are added to the "default" group.

Users are assigned to a group based on the defined groups in the access control files. If users are defined in users.txt, the group is determined by the that file. If the resulting group is the default group, the `ip.txt` file will be used for determining the associated group. If the users.txt file is empty, only the ip.txt file will be used.

In order to partition a single key to different groups in the `license.txt` file, add the key to multiple groups with the following syntax :

```
   n:key
```

where n is the number of concurrent users that should be assigned to the current group. Use different values of n in different groups that add up to the maximum number of current users for the key. For example :

```
[groupA]
4:F-95-10-xxx
[groupB]
6:F-95-10-xxx
```

splits the 10-user key F-95-10-xxx into 4 concurrent users for `[groupA]` and 6 concurrent users for `[groupB]`. In `users.txt`, the groups would be defined as :

```
[groupA]
bob
alice
...


[groupB]
carol
john
...
```

Alternatively, the `ip.txt` file could define groups as :

```
[groupA]
192.162.1.*
[groupB]
192.162.2.*
```

Group names are shown in the log file next to the user name.

## How can I help ?

All kinds of contributions are welcome :raised_hands:!<br />
The most basic way to show your support is to star :star2: the project, or to raise issues :speech_balloon:<br />
But we're not gonna lie to each other, I'd rather you buy me a beer or two :beers:!

[![Support me on Patreon](.res/patreon.png)](https://www.patreon.com/crazymax) 
[![Paypal Donate](.res/paypal.png)](https://www.paypal.me/crazyws)

## License

MIT. See `LICENSE` for more details.<br />
And a special thanks to @ingokegel and [ej-technologies'](https://www.ej-technologies.com/)!
