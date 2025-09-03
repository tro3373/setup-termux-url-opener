SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c # -c: Needed in .SHELLFLAGS. Default is -c.
.DEFAULT_GOAL := deploy

dotenv := $(PWD)/.env
-include $(dotenv)

deploy:
	@scp termux-url-opener termux:bin/

deploy-all:
	@scp termux-url-opener k n ogp .env cookies.json prompt.md termux:bin/

