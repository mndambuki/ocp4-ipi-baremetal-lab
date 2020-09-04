# Terraform parameters
ENVIRONMENT       := localhost
TERRAFORM         := terraform
TF_FILES_PATH     := src
TF_BACKEND_CONF   := configuration/backend
TF_VARIABLES      := configuration/tfvars
LIBVIRT_IMGS_PATH := src/storage/images
OCP_VERSION       := 4.5.4
OCP_RELEASE       := $(shell echo $(OCP_VERSION) | head -c 3)
OCP_INSTALLER     := openshift-baremetal-install
FCOS_VERSION      := 32.20200629.3.0
FCOS_IMAGE_PATH   := $(LIBVIRT_IMGS_PATH)/fedora-coreos-$(FCOS_VERSION).x86_64.qcow2

all: init deploy test

require:
	$(info Installing dependencies...)
	@./requirements.sh

download-installer:
ifeq (,$(wildcard $(OCP_INSTALLER)))
	$(info Downloading Openshift installer...)
	@OCP_RELEASE_IMAGE=`curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$(OCP_VERSION)/release.txt | grep 'Pull From: quay.io' | awk '{ print $$NF }'`;\
	oc adm release extract \
		--command "openshift-baremetal-install" \
		--registry-config "output/openshift-install/$${ENVIRONMENT}/pull-secret.json" \
		$${OCP_RELEASE_IMAGE};
endif

download-images:
ifeq (,$(wildcard $(FCOS_IMAGE_PATH)))
	$(info Downloading Fedora CoreOS image...)
	curl -s -S -L -f -o $(FCOS_IMAGE_PATH).xz \
		https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/$(FCOS_VERSION)/x86_64/fedora-coreos-$(FCOS_VERSION)-qemu.x86_64.qcow2.xz

	unxz -c $(FCOS_IMAGE_PATH).xz > $(FCOS_IMAGE_PATH)

	$(RM) -f $(FCOS_IMAGE_PATH).xz
else
	$(info Fedora CoreOS image already exists)
endif

setup-dns:
	$(info Elevating privileges...)
	@sudo -v

	$(info Configuring dnsmasq...)
	@sudo chmod 777 /etc/NetworkManager/conf.d
	@sudo chmod 777 /etc/NetworkManager/dnsmasq.d

init: download-installer download-images setup-dns
	$(info Initializing Terraform...)
	$(TERRAFORM) init \
		-backend-config="$(TF_BACKEND_CONF)/$(ENVIRONMENT).conf" $(TF_FILES_PATH)

changes:
	$(info Get changes in infrastructure resources...)
	$(TERRAFORM) plan \
		-var=OCP_VERSION=$(OCP_VERSION) \
		-var=OCP_ENVIRONMENT=$(ENVIRONMENT) \
		-var-file="$(TF_VARIABLES)/default.tfvars" \
		-var-file="$(TF_VARIABLES)/$(ENVIRONMENT).tfvars" \
		-out "output/tf.$(ENVIRONMENT).plan" \
		$(TF_FILES_PATH)

deploy: changes
	$(info Deploying infrastructure...)
	$(TERRAFORM) apply output/tf.$(ENVIRONMENT).plan

test:
	$(info Testing infrastructure...)

clean-installer:
	$(info Deleting Openshift installation files...)
	$(RM) -f openshift-baremetal-install
	$(RM) -rf output/openshift-install/$(ENVIRONMENT)

clean-dns:
	$(info Elevating privileges...)
	@sudo -v

	$(info Restoring network configuration...)
	@sudo chmod 755 /etc/NetworkManager/conf.d
	@sudo chmod 755 /etc/NetworkManager/dnsmasq.d
	@sudo systemctl restart NetworkManager

clean-vbmc:
	$(info Removing VMBC hosts...)
	@./output/vmbc/dettach-ipmi-hosts.sh

clean: changes clean-installer clean-dns clean-vbmc
	$(info Destroying infrastructure...)
	$(TERRAFORM) destroy \
		-auto-approve \
		-var=OCP_VERSION=$(OCP_VERSION) \
		-var=OCP_ENVIRONMENT=$(ENVIRONMENT) \
		-var-file="$(TF_VARIABLES)/default.tfvars" \
		-var-file="$(TF_VARIABLES)/$(ENVIRONMENT).tfvars" \
		$(TF_FILES_PATH)
	$(RM) -rf .terraform
	$(RM) -rf output/tf.$(ENVIRONMENT).plan
	$(RM) -rf state/terraform.$(ENVIRONMENT).tfstate
