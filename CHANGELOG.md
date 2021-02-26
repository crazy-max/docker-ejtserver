# Changelog

## 1.14-r0 (2021/02/26)

* EJT License Server 1.14

## 1.13.2-r0 (2021/02/11)

* EJT License Server 1.13.2
* Switch to buildx bake

## 1.13.1-RC8 (2020/05/06)

* Switch to Open Container Specification labels as label-schema.org ones are deprecated

## 1.13.1-RC7 (2019/12/07)

* Fix timezone

## 1.13.1-RC6 (2019/11/17)

* Allow to set custom `PUID`/`PGID`
* Allow to use Docker secrets for `EJT_ACCOUNT_USERNAME`, `EJT_ACCOUNT_PASSWORD` and `EJTSERVER_LICENSES`

## 1.13.1-RC5 (2019/10/10)

* Multi-platform Docker image
* Switch to GitHub Actions
* :warning: Stop publishing Docker image on Quay
* :warning: Run as non-root user
* Set timezone through tzdata

> :warning: **UPGRADE NOTES**
> As the Docker container now runs as a non-root user, you have to first stop the container and change permissions to `data` volume:
> ```
> docker-compose stop
> chown -R 1000:1000 data/
> docker-compose pull
> docker-compose up -d
> ```

## 1.13.1-RC4 (2019/08/04)

* Add healthcheck

## 1.13.1-RC3 (2019/07/22)

* OpenJDK JRE 12
* Alpine Linux 3.10

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
