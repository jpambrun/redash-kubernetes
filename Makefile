DOCKER_REPO?=nanit
REDASH_APP_NAME=redash
REDASH_FOLDER=app
REDASH_IMAGE_TAG=$(shell git log -n 1 --pretty=format:%h $(REDASH_FOLDER))
REDASH_IMAGE_NAME=$(DOCKER_REPO)/$(REDASH_APP_NAME):$(REDASH_IMAGE_TAG)
REDASH_DATABASE_URL?=$(shell curl -s config/$(NANIT_ENV)/$(REDASH_APP_NAME)/database_url)
REDASH_NAME?=$(shell curl -s config/$(NANIT_ENV)/$(REDASH_APP_NAME)/name)
REDASH_HOST?=$(shell curl -s config/$(NANIT_ENV)/$(REDASH_APP_NAME)/host)
REDASH_MAIL_SERVER?=$(shell curl -s config/$(NANIT_ENV)/$(REDASH_APP_NAME)/mail_server)
REDASH_MAIL_PORT?=$(shell curl -s config/$(NANIT_ENV)/$(REDASH_APP_NAME)/mail_port)
REDASH_MAIL_USERNAME?=$(shell curl -s config/$(NANIT_ENV)/$(REDASH_APP_NAME)/mail_username)
REDASH_MAIL_PASSWORD?=$(shell curl -s config/$(NANIT_ENV)/$(REDASH_APP_NAME)/mail_password)
REDASH_MAIL_DEFAULT_SENDER?=$(shell curl -s config/$(NANIT_ENV)/$(REDASH_APP_NAME)/mail_default_sender)

NGINX_NAME=$(REDASH_APP_NAME)-nginx
NGINX_FOLDER=nginx
NGINX_IMAGE_TAG=$(shell git log -n 1 --pretty=format:%h $(NGINX_FOLDER))
NGINX_IMAGE_NAME=$(DOCKER_REPO)/$(NGINX_NAME):$(NGINX_IMAGE_TAG)
NGINX_HTPASSWD?=$(shell curl -s config/$(NANIT_ENV)/$(REDASH_APP_NAME)/htpasswd)

define generate-dep
	echo "CHECKING VARIABLES"
	if [ -z "$(REDASH_DATABASE_URL)" ]; then echo "ERROR: REDASH_DATABASE_URL is empty!"; exit 1; fi
	if [ -z "$(REDASH_HOST)" ]; then echo "ERROR: REDASH_HOST is empty!"; exit 1; fi
	if [ -z "$(REDASH_NAME)" ]; then echo "ERROR: REDASH_NAME is empty!"; exit 1; fi
	if [ -z "$(REDASH_MAIL_SERVER)" ]; then echo "ERROR: REDASH_MAIL_SERVER is empty!"; exit 1; fi
	if [ -z "$(REDASH_MAIL_PORT)" ]; then echo "ERROR: REDASH_MAIL_PORT is empty!"; exit 1; fi
	if [ -z "$(REDASH_MAIL_USERNAME)" ]; then echo "ERROR: REDASH_MAIL_USERNAME is empty!"; exit 1; fi
	if [ -z "$(REDASH_MAIL_PASSWORD)" ]; then echo "ERROR: REDASH_MAIL_PASSWORD is empty!"; exit 1; fi
	if [ -z "$(REDASH_MAIL_DEFAULT_SENDER)" ]; then echo "ERROR: REDASH_MAIL_DEFAULT_SENDER is empty!"; exit 1; fi
	if [ -z "$(NGINX_HTPASSWD)" ]; then echo "ERROR: NGINX_HTPASSWD is empty!"; exit 1; fi
	echo "VARIABLES OK"
	sed -e '\
		s,{{REDASH_DATABASE_URL}},$(REDASH_DATABASE_URL),s; \
		s,{{REDASH_APP_NAME}},$(REDASH_APP_NAME),s; \
		s,{{REDASH_IMAGE_NAME}},$(REDASH_IMAGE_NAME),s; \
		s,{{REDASH_NAME}},$(REDASH_NAME),s; \
		s,{{REDASH_HOST}},$(REDASH_HOST),s; \
		s,{{REDASH_DATABASE_URL}},$(REDASH_DATABASE_URL),s; \
		s,{{REDASH_MAIL_SERVER}},$(REDASH_MAIL_SERVER),s; \
		s,{{REDASH_MAIL_PORT}},$(REDASH_MAIL_PORT),s; \
		s,{{REDASH_MAIL_USERNAME}},$(REDASH_MAIL_USERNAME),s; \
		s,{{REDASH_MAIL_PASSWORD}},$(REDASH_MAIL_PASSWORD),s; \
		s,{{REDASH_MAIL_DEFAULT_SENDER}},$(REDASH_MAIL_DEFAULT_SENDER),s; \
		s,{{NGINX_HTPASSWD}},$(NGINX_HTPASSWD),s; \
		s,{{NGINX_APP_NAME}},$(NGINX_APP_NAME),s; \
		s,{{NGINX_IMAGE_NAME}},$(NGINX_IMAGE_NAME),s; \
		' kube/dep.yml
endef

define generate-svc
	sed -e 's/{{APP_NAME}}/$(REDASH_APP_NAME)/g;s/{{SVC_NAME}}/$(REDASH_APP_NAME)/g' kube/svc.yml
endef

deploy: docker
	$(call generate-dep) | kubectl apply -f -
	kubectl get svc $(REDASH_APP_NAME) || $(call generate-svc) | kubectl create -f -

docker: docker-redash docker-nginx

docker-redash:
	sudo docker pull $(REDASH_IMAGE_NAME) || (sudo docker build -t $(REDASH_IMAGE_NAME) $(REDASH_FOLDER) && sudo docker push $(REDASH_IMAGE_NAME))

docker-nginx:
	sudo docker pull $(NGINX_IMAGE_NAME) || (sudo docker build -t $(NGINX_IMAGE_NAME) $(NGINX_FOLDER) && sudo docker push $(NGINX_IMAGE_NAME))
