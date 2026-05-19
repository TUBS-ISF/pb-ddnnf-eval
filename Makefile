all:
	$(MAKE) -C jobs all

fm-benchmark:
	$(MAKE) -C jobs fm-benchmark

isolated:
	$(MAKE) -C jobs isolated

random:
	$(MAKE) -C jobs random
