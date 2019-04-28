# Changelog

## 1.13.1-RC2 (2019/03/20)

* Alpine Linux 3.9

## 1.13.1-RC1 (2018/09/27)

* EJT License Server 1.13.1
* Dockerfile maintainer deprecated

## 1.13-RC4 (2018/07/28)

* Alpine Linux 3.8
* Unset sensitive environment variables
* Rename `UID / GID` vars to `PUID / PGID` (best practice)

## 1.13-RC3 (2018/02/16)

* Licenses are now injected through environment variable `EJTSERVER_LICENSES`
* Rename some environment variables
* No need of Supervisor

## 1.13-RC2 (2018/02/06)

* Username and password required if you use the official base url to download the ejtserver tarball
* A custom base url can be provided to download the ejtserver tarball

## 1.13-RC1 (2018/02/06)

* Initial version based on EJT License Server 1.13
