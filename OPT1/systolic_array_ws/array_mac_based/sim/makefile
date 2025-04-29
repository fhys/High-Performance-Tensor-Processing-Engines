
vcs:
		vcs -R -j24 -full64 +v2k +vc -cpp g++-4.8 -cc gcc-4.8 -fsdb +neg_tchk -negdelay +notimingcheck +nospecify +define+FSDB -sverilog -l run.log -f filelist.f -LDFLAGS "-Wl,--no-as-needed" 
vd:
	verdi -sv -f filelist.f -ssf *.fsdb -nologo

cl:
	rm -rf *.fsdb *.rc *.key *.log *.conf simv* csrc verdi*