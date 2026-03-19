
-include benches.mk

CXXFLAGS+=-fdiagnostics-color=always

.PRECIOUS: obj_dir/V%_tb
.PRECIOUS: tb/%_tb.v

test.%: obj_dir/V%_tb $(wildcard src/*.v)
	$<

obj_dir/V%_tb: tb/%_tb.v $(wildcard src/*.v)
	verilator --top-module $(notdir $(basename $<)) --binary tb/*.v src/*.v



tb/%_tb.v:
	@if test '!' -e $@; then \
		echo "Making module $@"; \
		touch $@; \
		echo module "$(patsubst tb/%_tb.v,%, $@)();" >> $@; \
		echo -e "\n\n\nendmodule" >> $@; \
		echo "test.$(patsubst tb/%_tb.v,%, $@)" >> benches.mk; \
	fi


module.%: tb/%_tb.v
	@echo

