## Use Admin image as the builder
## Ref. Pulling and tagging base images
## https://www.ibm.com/docs/en/mas-cd/maximo-manage/continuous-delivery?topic=environment-pulling-tagging-base-images
FROM localhost/manage-admin-dev as admin

USER root

## Remove base image customizations (which will be linked from the host)
## and make commonly used classes as folders mounted into container
## NOTE: The assumption is that all custom classes are places under custom.*
##       Java package. Adjust the cleanup section below to match your setup.
WORKDIR /opt/IBM/SMP/maximo/applications/maximo
RUN rm -rf businessobjects/classes/custom \
	&& rm -rf maximouiweb/webmodule/WEB-INF/classes/custom

## Replace web.xml for maximo-all maximo-x
WORKDIR /opt/IBM/SMP/maximo/deployment/was-liberty-default/config-deployment-descriptors/maximo-all/maximo-x/webmodule/WEB-INF/
RUN mv web.xml web-oidc.xml
RUN mv web-guest.xml  web-guest-oidc.xml
RUN mv web-dev.xml  web.xml
RUN mv web-guest-dev.xml  web-guest.xml

## Replace web.xml for maximo-all maximouiweb
WORKDIR /opt/IBM/SMP/maximo/deployment/was-liberty-default/config-deployment-descriptors/maximo-all/maximouiweb/webmodule/WEB-INF/
RUN mv web.xml web-oidc.xml
RUN mv web-dev.xml  web.xml

## Replace web.xml for maximo-all maxrestweb
WORKDIR /opt/IBM/SMP/maximo/deployment/was-liberty-default/config-deployment-descriptors/maximo-all/maxrestweb/webmodule/WEB-INF/
RUN mv web.xml web-oidc.xml
RUN mv web-dev.xml  web.xml

## Replace web.xml for maximo-all mboweb
WORKDIR /opt/IBM/SMP/maximo/deployment/was-liberty-default/config-deployment-descriptors/maximo-all/mboweb/webmodule/WEB-INF/
RUN mv web.xml web-oidc.xml
RUN mv web-dev.xml  web.xml

## Replace web.xml for maximo-all meaweb
WORKDIR /opt/IBM/SMP/maximo/deployment/was-liberty-default/config-deployment-descriptors/maximo-all/meaweb/webmodule/WEB-INF/
RUN mv web.xml web-oidc.xml
RUN mv web-dev.xml  web.xml

## create the EAR file
WORKDIR /opt/IBM/SMP/maximo/deployment/was-liberty-default
RUN ./maximo-all.sh


## Build the final image
FROM localhost/manage-all-dev

## Copy the new EAR file from the admin builder
COPY --from=admin /opt/IBM/SMP/maximo/deployment/was-liberty-default/deployment/maximo-all/maximo-all-server/apps/maximo-all.ear /config/apps/

## Expand application
## NOTE: The trick is to simply unzip EAR to the directory of exact same name and continue
##       unzipping nested libraries (JARs) and modules (WARs) in a similar fashion. 
##       Example below presents the most common use case for businessobjects.jar and maximouiweb.war
##       but it can be easily extended with others, like: mboejb.jar, meaweb.war, etc.
WORKDIR /config/apps
RUN mv maximo-all.ear _maximo-all.ear \
	&& mkdir maximo-all.ear \
	&& unzip -qq _maximo-all.ear -d maximo-all.ear \
	&& ( \
		cd maximo-all.ear \
		&& mv businessobjects.jar _businessobjects.jar \
		&& mv maximouiweb.war _maximouiweb.war \
		&& mkdir businessobjects.jar maximouiweb.war \
		&& unzip -qq _businessobjects.jar -d businessobjects.jar \
		&& unzip -qq _maximouiweb.war -d maximouiweb.war \
		&& rm -f _businessobjects.jar _maximouiweb.war \
	) \
	&& rm -f _maximo-all.ear

## Fix local authentication
## NOTE: IBM's Dockerfile does it at the time of admin image build which takes no effect
WORKDIR /config
RUN mv server.xml server-oidc.xml \
	&& mv server-dev.xml server.xml \
	&& sed -i '/wmqJmsClient/d' server.xml
## Uncomment following line to extend base server.xml config with server-custom.xml (e.g. JMS config, etc.)
# COPY server-custom.xml /config/

## Set the env vars 
## Ref. "Building and deploying development images"
## https://www.ibm.com/docs/en/mas-cd/maximo-manage/continuous-delivery?topic=environment-building-deploying-development-images
ENV DB_SSL_ENABLED=nossl
ENV MXE_DB_URL='jdbc:db2://9.30.213.13:50000/bludb'
ENV MXE_DB_SCHEMAOWNER=maximo
ENV MXE_DB_DRIVER='com.ibm.db2.jcc.DB2Driver'
ENV MXE_SECURITY_OLD_CRYPTO_KEY=SzUwFenwARerIQCMotXkisoU
ENV MXE_SECURITY_CRYPTO_KEY=SzUwFenwARerIQCMotXkisoU
## NOTE: Set MXE_SECURITY_OLD_CRYPTOX_KEY and MXE_SECURITY_CRYPTOX_KEY environment variables still missing (2024-08-15)
##       in the IBM's Dockerfile (https://www.ibm.com/docs/en/SSLPL8_cd/com.ibm.mam.doc/config/dockerfile.zip)
ENV MXE_SECURITY_OLD_CRYPTOX_KEY=tzuxfEQruriVKmlTbrBZipDi
ENV MXE_SECURITY_CRYPTOX_KEY=tzuxfEQruriVKmlTbrBZipDi
ENV MXE_USEAPPSERVERSECURITY=0
ENV MXE_DB_USER=maximo
ENV MXE_DB_PASSWORD=maximo
ENV MXE_MASDEPLOYED=0
ENV LC_ALL=en_US.UTF-8

## Setup debugging options
## Ref. Open Liberty -> Default environment variables
## https://openliberty.io/docs/latest/reference/default-environment-variables.html)
ENV WLP_DEBUG_SUSPEND=n
ENV WLP_DEBUG_REMOTE=y

USER 1001

## Override base image startup command and run server in debug mode
CMD ["/opt/ibm/wlp/bin/server", "debug", "defaultServer"]
