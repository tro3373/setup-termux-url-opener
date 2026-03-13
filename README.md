## Setup termux

- Send files
  ```bash
  make deploy-all
  ```
- Install gemini
  ```bash
  pkg install python3
  pkg install nodejs
  npm install -g @google/gemini-cli
  ```

## setup gtasks
```diff
diff --git a/Makefile b/Makefile
index 6349c71..15a8484 100644
--- a/Makefile
+++ b/Makefile
@@ -36,7 +36,7 @@ endif

 build:
        @mkdir -p $(BIN_DIR)
-       @go build -ldflags "$(LDFLAGS)" -o $(BIN) $(CMD)
+       @GOOS=android GOARCH=arm64 go build -ldflags "$(LDFLAGS)" -o $(BIN) $(CMD)

 gog: build
        @if [ -n "$(RUN_ARGS)" ]; then \
```

- setup gog
  - build gog for android arm
    - Modify Makefile above diff in steipete/gogcli and run `make`
      - bin/gog file will be generated
      - send bin/gog to termux:bin
  - setup gog credentials
    - setup gog to use file auth
      - `gog auth keyring file`
      - or
        ```bash
        export GOG_KEYRING_BACKEND=file
        export GOG_KEYRING_PASSWORD=SetPasswordHere
       ```
    - create client secret and download credentials from gcp
    - add cred
      - `gog auth credentials ~/Downloads/client_secret_....json`
      - 
    - add account in pc(browser open and login)
      - `gog auth add you@gmail.com`
    - archive and send termux
      ```sh
      cd ~/.config
      tar -czvf g.tar.gz gogcli
      scp g.tar.gz termux:bin
      ssh termux "cd bin && tar -xzvf g.tar.gz && rm g.tar.gz && mv gogcli ~/.config"
      ```

