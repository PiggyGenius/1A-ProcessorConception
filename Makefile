# Verification que l'environement de Xilinx a bien été sourcé
ifeq ($(origin XILINX), undefined)
  $(error Outils Xilinx introuvables, lancez d'abord la commande "source /Xilinx/env-14.7.sh") #'
endif

VERBOSE :=-intstyle xflow # mettre xflow ou silent 

FPGA	  := xc7z010-clg400-1

MIPSC	  := /opt/mips-toolchain-bin/bin/mips-sde-elf-
AS 	      := $(MIPSC)as 
OBJDUMP   := $(MIPSC)objdump 
ASFLAGS   :=  -R -EB -mips3 -non_shared -W 
ODFLAGS   := --section=.text --section=.data --section=.sdata --section=.bss --section=.irq_vec -M no-aliases -M reg-names=numeric -d
OBTOMEM   := bin/objtomem.awk

TOP 	  := MMIPS_simple
ifeq ($(MAKECMDGOALS),autotest_res)
	TOP   := MMIPS_autotest
endif
TOP_OK	  := MMIPS_simple MMIPS_complet MMIPS_autotest
# Verification que le TOP est autorisé
ifeq ($(filter $(TOP),$(TOP_OK)),)
  $(error Toplevel $(TOP) inconnu)
endif
PROG	  := test_lui

SRCDIR    := program
VHDDIR    := vhd
CONFIGDIR := config
ifneq ($(TOP),MMIPS_autotest)
VHD_SRC	  := $(shell sed -e 's/vhdl work "..\/\(.*\)"/\1 /' $(CONFIGDIR)/$(TOP).prj | cat)
VHD_SRC1  := $(filter-out vhd/RAM_%_data.vhd , $(VHD_SRC))
VHD_SRC2  := $(filter vhd/RAM_%_data.vhd , $(VHD_SRC))
endif
VHD_SIMU  := $(shell sed -e 's/vhdl work "..\/\(.*\)"/\1 /' $(CONFIGDIR)/tb_$(TOP)_beh.prj)

OPT_EFFORT := -ol std

TMP	        := .CEPcache
DESTDIR     := $(TMP)/mem
MOI         := CEP-$(shell whoami)
RESDIR      := /tmp/$(MOI)
SYNTHDIR    := $(TMP)/synth
XSTDIR	    := $(SYNTHDIR)/tmp
SIMDIR_FUSE := $(TMP)/sim

DIR := $(TMP) $(DESTDIR) $(SYNTHDIR) $(SIMDIR_FUSE) $(XSTDIR) $(RESDIR) 

# Pas de fichier .s à la racine
ifneq ($(wildcard *.s),)
  $(error Merci de ranger vos .s dans le répertoire program/)
endif
# Fichier PROG.s bien présent dans program/
SRC := $(basename $(notdir $(wildcard $(SRCDIR)/*.s) $(wildcard $(SRCDIR)/*.elf) $(wildcard $(SRCDIR)/*/*.s))) 
ifeq ($(filter $(PROG),$(SRC)),)
  $(error $(PROG) est introuvable dans le répertoire program/ ou un de ses sous-répertoires directs)
endif


SIM_TIME := 1000

RESFILES := $(addprefix $(RESDIR)/,$(patsubst %.s,%.res,$(shell cat program/sequence_test)))

PROG_mem       := $(DESTDIR)/$(notdir $(basename $(PROG))).mem
RAM_PROG_DATA  := $(VHDDIR)/RAM_PROG_data.vhd

XST_CONF  := $(CONFIGDIR)/$(TOP).xst
BMM	  := $(CONFIGDIR)/$(TOP)_RAM.bmm
BMM_BD 	  := $(CONFIGDIR)/$(TOP)_RAM_bd.bmm
CONTRAINTE:= $(CONFIGDIR)/$(TOP).ucf

TOCLEAN = $(TMP) log _impactbatch.log 
TOPOLISH = $(RESDIR) autotest_res

VERB	  := 0
quiet-command = $(if $(filter 1, $(VERB)),$(1), $(if $(2),@echo $(2) && ($(1)) >> log, @$(1)))
qc2 = $(if $(filter 1, $(VERB)),$(1), $(if $(2),@echo $(2) && $(1) > log || ( cat log | grep ERROR: ; exit 1), @$(1)))

vpath %.s program:program/autotest:program/autotest:program/test_prof:program/test_periph
#regles pour creer les repertoires utiles
$(DIR):
	@mkdir -p $@

autotest_res: $(RESFILES)
	@cat $^ > $@

$(RESDIR)/%.res: $(RESDIR)/%_dir | $(RESDIR)
	$(call quiet-command, cd $< ; ./tb_MMIPS_autotest_isim_beh.exe -tclbatch batch.cmd , "  Simu batch $*")
	@if [ ! -s $</test_defaut.res ] ; then echo "$* : TIMEOUT" > $@ ; else echo "$* : `cat $</test_defaut.res`" > $@ ;fi
	@mv $</isim.log $(@D)/$*.log
	@rm -rf $<

$(RESDIR)/ref: $(SIMDIR_FUSE)/tb_$(TOP)_isim_beh.exe | $(RESDIR) 
	@if [ -d $@ ] ; then rm -rf $@ ;fi ; cp -r $(<D) $@ ;  cp $(CONFIGDIR)/batch.cmd $@
	

.PRECIOUS: $(RESDIR)/%.setup $(RESDIR)/%.out $(RESDIR)/%.mem $(RESDIR)/%.irq 

CEPln = ln -s ../$*.$(1) test_defaut.$(1)
$(RESDIR)/%_dir: $(RESDIR)/ref $(RESDIR)/%.mem $(RESDIR)/%.out $(RESDIR)/%.irq $(RESDIR)/%.setup
	@cp -r $< $@ ; cd $@; $(call CEPln,out) ; $(call CEPln,irq) ; $(call CEPln,mem) ; $(call CEPln,setup) 

$(RESDIR)/%.mem : $(DESTDIR)/%.mem
	@cp $< $@

$(RESDIR)/%.setup: %.s $(RESDIR)/%.irq | $(RESDIR)
	@awk '$$1=="#" && $$2=="max_cycle" {print $$3}' < $< > $@ ;\
	if [ ! -s $@ ] ; then echo "100" > $@ ; fi ;\
	if [ -s $(RESDIR)/%.irq ] ; then echo "false" >> $@ ;else echo "true" >> $@ ;fi 

$(RESDIR)/%.out: %.s | $(RESDIR)
	@awk '$$1=="#" && $$2=="pout_start", $$1=="#" && $$2=="pout_end" {if ($$2!~"pout") print $$2 " " $$3}' < $< > $@ 

$(RESDIR)/%.irq: %.s | $(RESDIR)
	@awk '$$1=="#" && $$2=="irq_start", $$1=="#" && $$2=="irq_end" {if ($$2!~"irq") print $$2}' < $< > $@ 

.PHONY : run_simu compil force clean realclean run_fpga

#### Gestion de la mise à jour des mémoires par les programmes et la video
$(DESTDIR)/%.elf: %.s | $(DESTDIR)   
	$(call quiet-command,\
	cat $< | awk -v f=$< 'BEGIN {print ".file \"" f "\""; print ".set noreorder"; print ".line 0";} {print}' \
   	| $(AS) $(ASFLAGS) -o $@ --, "  AS     $<")
$(DESTDIR)/%.mem: $(DESTDIR)/%.elf
	$(call quiet-command, $(OBJDUMP) $(ODFLAGS) $< | awk -f $(OBTOMEM) > $@ ,)
$(DESTDIR)/%.mem: $(SRCDIR)/$(PROG).elf
	$(call quiet-command, $(OBJDUMP) $(ODFLAGS) $< | awk -f $(OBTOMEM) > $@ ,)


$(TMP)/prog: $(TMP) force
	@if [ ! -e $@ ] || [ $(PROG) != `cat $@` ] ; then echo "$(PROG)" > $@  ;fi
# le ln correspond à un workaround du à un bug de data2mem
$(RAM_PROG_DATA): $(PROG_mem) $(TMP)/prog
	$(call quiet-command, ln -s $< tmp_prog.mem && data2mem -bm $(BMM) -bd tmp_prog.mem -o h $@ ; \
	       rm tmp_prog.mem ; sed -i "s/RAM_PROG_data[_[:alnum:]]*/RAM_PROG_data_pkg /g" $@, "  MAJ de $@")


### Simulateur Xilinx
SIM_FUSE_CMD=tb_$(TOP)_isim_beh.cmd
SIM_FUSE_VIEW_CFG=$(CONFIGDIR)/tb_$(TOP)_isim_beh.wcfg
SIM_FUSE_CMD_TCL=onerror {resume};
SIM_FUSE_SIM_OPT=-tclbatch $(SIM_FUSE_CMD) -wdb tb_$(TOP)_isim_beh.wdb -gui

ifneq ($(realpath $(SIM_FUSE_VIEW_CFG)),)
SIM_FUSE_SIM_OPT+=-view ../../$(SIM_FUSE_VIEW_CFG)
else
SIM_FUSE_CMD_TCL+=wave add /; 
endif
ifdef SIM_TIME
SIM_FUSE_CMD_TCL+=run $(SIM_TIME) ns;
endif 

$(SIMDIR_FUSE)/tb_$(TOP)_isim_beh.exe: $(CONFIGDIR)/tb_$(TOP)_beh.prj $(VHD_SIMU) |$(SIMDIR_FUSE)
	$(call quiet-command, cd $(@D) ; fuse $(VERBOSE) -incremental -o $(@F) -prj  ../../$< work.tb_$(TOP) , "  Compilation  ")
	   	

compil : $(SIMDIR_FUSE)/tb_$(TOP)_isim_beh.exe 
run_simu: $(SIMDIR_FUSE)/tb_$(TOP)_isim_beh.exe
	$(call quiet-command, cd $(<D) ; echo "$(SIM_FUSE_CMD_TCL)" >  $(SIM_FUSE_CMD) ; \
		./$(<F)  $(SIM_FUSE_SIM_OPT) , "  Simulation   ")

### Pour la synthèse et placement routage
$(SYNTHDIR)/$(TOP).ngc: $(VHD_SRC1) $(XST_CONF) | $(SYNTHDIR) $(XSTDIR) $(VHD_SRC2)
	$(call qc2, cd $(@D) ; xst $(VERBOSE) -ifn ../../$(XST_CONF) \
	       	-ofn $(TOP).syr , "  Synthèse logique")

$(SYNTHDIR)/%.ngd: $(SYNTHDIR)/%.ngc 
	$(call quiet-command, cd $(@D) ; ngdbuild $(VERBOSE) -bm ../../$(BMM)\
		 -dd _ngo -nt timestamp -uc ../../$(CONTRAINTE)\
		-p $(FPGA) $(<F) $(@F), "  Traduction en format interne")

$(SYNTHDIR)/%.pcf: $(SYNTHDIR)/%.ngd $(CONTRAINTE)
	$(call quiet-command, cd $(@D) ; map $(VERBOSE) -p $(FPGA) -w $(OPT_EFFORT) -r 4 -o $*_map.ncd $(<F) $(@F), "  Adaptation au FPGA choisi")

$(SYNTHDIR)/%.ncd: $(SYNTHDIR)/%.pcf
	$(call quiet-command, cd $(@D) ; par -w $(VERBOSE) $(OPT_EFFORT) $*_map.ncd $(@F) $(<F), "  Placement et Routage")

$(SYNTHDIR)/%.bit: $(SYNTHDIR)/%.ncd $(CONFIGDIR)/bitstream.ut 
	$(call quiet-command, cd $(@D) ; bitgen $(VERBOSE)\
	       -f ../../$(CONFIGDIR)/bitstream.ut $(<F) $(@F), "  Génération du fichier de configuration")

DT2MEMDP  := $(PROG_mem)
DT2MEMOPT := -bd ../$(subst $(TMP)/,,$(PROG_mem))


$(SYNTHDIR)/$(TOP)_download.bit: $(SYNTHDIR)/$(TOP).bit $(DT2MEMDP) $(BMM_BD) $(TMP)/prog
	$(call quiet-command, cd $(@D) ; data2mem $(DT2MEMOPT) -bm ../../$(BMM_BD) \
	       -bt $(<F) -o b $(@F), "  MAJ du fichier de configuration")

$(BMM_BD): $(SYNTHDIR)/$(TOP).ncd 
	$(call quiet-command, bitgen -j -d -w $(DT2MEMOPT) $<,)

bitfile : $(SYNTHDIR)/$(TOP)_download.bit

run_fpga: $(SYNTHDIR)/$(TOP)_download.bit $(CONFIGDIR)/impact.cmd
	$(call quiet-command,  ln -s -f $< download.bit && \
	impact -batch $(CONFIGDIR)/impact.cmd ; rm download.bit, "  Programmation")

force:

clean:
	@rm -rf $(TOCLEAN)

realclean: clean
	@rm -rf $(TOPOLISH)
