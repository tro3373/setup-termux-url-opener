SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c # -c: Needed in .SHELLFLAGS. Default is -c.
.DEFAULT_GOAL := deploy

dotenv := $(PWD)/.env
-include $(dotenv)

deploy:
	@scp .env cookies.json termux-url-opener to_notion.sh to_gtasks.sh to_keep.sh termux:bin/

deploy-keys:
	@scp .env cookies.json termux:bin/

deploy-all: deploy
	@scp k n g gog-reauth ogp prompt.md termux:bin/

