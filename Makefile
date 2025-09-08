SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c # -c: Needed in .SHELLFLAGS. Default is -c.
.DEFAULT_GOAL := deploy

dotenv := $(PWD)/.env
-include $(dotenv)

deploy:
	@scp .env cookies.json termux-url-opener termux:bin/

deploy-keys:
	@scp .env cookies.json termux:bin/

deploy-all: deploy-keys
	@scp termux-url-opener k n ogp prompt.md termux:bin/

