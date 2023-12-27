# Makefile

OPENSSL = openssl
STEP    = step
YKMAN   = ykman

RANDOM  = /dev/random

ORG    = Trollwerks
OU     = Stoneglen
L_ORG := $(shell echo $(ORG) | tr A-Z a-z)
L_OU  := $(shell echo $(OU) | tr A-Z a-z)

ROOT_DAYS = 18250   # ~50 years
INT_HOURS = 17520h  # ~2 years

## ----------------------------------------

.PHONY: all
all:
	@echo ""
	@echo "** no default target **  (TBD: list TOC of targets)"
	@echo ""

.PHONY: root-ca
root-ca:
	$(OPENSSL) ecparam \
		-name prime256v1 \
		-genkey \
		-noout \
		-rand $(RANDOM) \
		-out $(L_ORG)-ca-key.pem
	$(OPENSSL) req \
		-x509 \
		-new \
		-days $(ROOT_DAYS) \
		-rand $(RANDOM) \
		-config $(L_ORG)-ca.config \
		-extensions v3_ca \
		-key $(L_ORG)-ca-key.pem \
		-out $(L_ORG)-ca-crt.pem


.PHONY: intermediate-ca
intermediate-ca:
	$(STEP) certificate create \
		--no-password \
		--insecure \
		--not-after $(INT_HOURS) \
		--template intermediate.tpl \
		--set-file $(L_OU)-ou.json \
		--ca $(L_ORG)-ca-crt.pem \
		--ca-key $(L_ORG)-ca-key.pem \
		"$(OU) Intermediate CA" \
		$(L_OU)-crt.pem \
		$(L_OU)-key.pem


.PHONY: clean
clean:
	rm *.pem
