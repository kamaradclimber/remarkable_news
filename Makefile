.ONESHELL:
# .SILENT:

host=remarkable
cooldown=3600

renews.arm:
	go get ./...
	env GOOS=linux GOARCH=arm GOARM=7 go build -o renews.arm

renews.x86:
	go get ./...
	go build -o renews.x86

# get latest prebuilt releases
.PHONY: download_prebuilt
download_prebuilt:
	curl -LO http://github.com/evidlo/remarkable_news/releases/latest/download/release.zip
	unzip release.zip

# build release
.PHONY: release
release: renews.arm renews.x86
	zip release.zip renews.arm renews.x86

clean:
	rm -f renews.x86 renews.arm release.zip

define install
  $(call setup)
  $(call copy_file,renews.arm)
  $(call backup_suspended)
  $(call copy_file,services/$(1).service,/etc/systemd/system/)
  $(call copy_file,services/$(1).timer,/etc/systemd/system/)
  $(call activate_timer,$(1))
endef

define setup
	eval $(shell ssh-agent -s)
	# make sure we have keys in agent
	ssh -o AddKeysToAgent=yes root@$(host) hostname
endef

define copy_file
  echo "Will copy $(1) into directory $(2)"
	scp $(1) root@$(host):$(2)/
endef

define backup_suspended
	# back up suspend screen.  don't overwrite existing file
	# busybox cp doesn't have -n option, do a hacky alternative
	ssh root@$(host) "cd /usr/share/remarkable/; ls suspended_back.png 2> /dev/null || cp suspended.png suspended_back.png"
endef

define activate_timer
	ssh root@$(host) systemctl daemon-reload
	ssh root@$(host) systemctl enable $(1).timer
	ssh root@$(host) systemctl start $(1).timer
endef

# ----- Sources -----

.PHONY: install_nyt
install_nyt: renews.arm
	$(call install,nyt)

.PHONY: install_nyt_hq
install_nyt_hq: renews.arm
	$(call install,nyt-hq)

.PHONY: install_xkcd
install_xkcd: renews.arm
	$(call install,xkcd)

.PHONY: install_wp
install_wp: renews.arm
	$(call install,wp)

.PHONY: install_picsum
install_picsum: renews.arm
	$(call install,picsum)

.PHONY: install_loremflickr
install_loremflickr: renews.arm
	$(call install,loremflickr)

.PHONY: install_cah
install_cah: renews.arm
	$(call install,cah)

# .PHONY: install_wikipotd
# install_wikipotd: renews.arm
# 	$(call install,wikipotd)
