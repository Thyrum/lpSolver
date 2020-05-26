# Generic C++ Makefile
# Aron de Jong, 2020-04-05

# This makefile is used to build generic C/C++ projects with automatic
# dependency checking. Feel free to use it, assuming that the teacher allows it
# and you leave this header in place. This makefile was built by Aron de Jong,
# drawing inspiration from the webpage below and from the makefile created by 
# Arthur van der Staaij.
# http://make.mad-scientist.net/papers/advanced-auto-dependency-generation/

# The makefile provides the following build targets:
# all:   build the release executable
# debug: build the debug executable
# run:   build and run the release executable
# drun:  build and run the debug executable
# c:     clean all the build files
# clean: clean all the build files, executables and empty directories

# To run the program with arguments when calling `run` or `drun`, set ARGS to
# the arguments or call using
#   make run ARGS="arguments here"

# All the options can be set by editing the values above the warning header
# below. Notice that, because of automatic dependency checking, providing a
# header extension is not required. The content of the options should be as 
# follows:
# 
# CXX            The compiler to be used
# CXXFLAGS       General compiler flags
# LDLIBS         Library flags or names for the linker (-l<libname>)
# RELEASE_FLAGS  Compiler flags for the release build
# DEBUG_FLAGS    Compiler flags for the debug build
# EXECNAME_R     Name for the release executable
# EXECNAME_D     Name for the debug executable
#
# BLD_DIR        Directory containing all build files (and SUBDIR directories)
# SRC_DIR        Directory containing all source files
# INC_DIR        Directory / directories containing all header files
# LIB_DIR        Directory containing all libraries
# BIN_DIR        Directory in which to put the executables (binaries)
# DEP_SUBDIR     Directory containing all dependency files generated in the
#                build proces
# OBJ_SUBDIR_R   Directory containing all object files for the release build
# OBJ_SUBDIR_D   Directory containing all object files for the debug build
# 
# MAKE_CMD       Command to be used when recusively calling make
# ECHO_CMD       Command to be used when printing text to the console
# RM             Command to be used when deleting files
# 
# SRC_EXT        Extension for source files
# ARGS           Arguments to be passed to the program when executing

# The above condenses to a directory structure as follows:
# --|-- Makefile
#   |-- SRC_DIR
#   |    +-- *.SRC_EXT
#   |
#   |-- INC_DIR
#   |    +-- [header files]
#   |
#   |-- BLD_DIR
#   |    |-- OBJ_SUBDIR_R
#   |    |-- OBJ_SUBDIR_D
#   |    +-- DEP_SUBDIR
#   |
#   +-- LIB_DIR
#        |-- *.so
#        |-- [libname]/
#             |-- Makefile
#             +-- [Other library files]

# For automatically building libraries, the makefile executes all makefiles in
# the subdirectories of LIB_DIR (not going into subdirectories recursively).
# After these calls, LIB_DIR should contain all the .so files required by the
# LDLIBS.


# ---- Compiler flags ----
CXX            = g++

CXXFLAGS       = -Wall -Wextra -std=c++11
LDLIBS         =
RELEASE_FLAGS  = -O3
DEBUG_FLAGS    = -g

EXECNAME_R     = solve
EXECNAME_D     = $(EXECNAME_R)_debug

# ---- Directories ----
BLD_DIR        = build
SRC_DIR        = src
INC_DIR        = include
LIB_DIR        = lib
BIN_DIR        = .

DEP_SUBDIR     = deps
OBJ_SUBDIR_R   = obj/release
OBJ_SUBDIR_D   = obj/debug

# ---- Commands ----
MAKE_CMD       = make --no-print-directory
ECHO_CMD       = echo -e
RM             = rm -f

# --- Misc ----
SRC_EXT        = cc
ARGS           =


#=============================================================================#
#----------------- Are you sure you know what you're doing? ------------------#
#=============================================================================#


#This comma is required to be able to substitute commas using patsubst
COMMA        := ,

DEP_DIR       = $(BLD_DIR)/$(DEP_SUBDIR)
OBJ_DIR_R     = $(BLD_DIR)/$(OBJ_SUBDIR_R)
OBJ_DIR_D     = $(BLD_DIR)/$(OBJ_SUBDIR_D)

SOURCES       = $(wildcard $(SRC_DIR)/*.$(SRC_EXT))
OBJS_R        = $(patsubst $(SRC_DIR)/%.$(SRC_EXT),$(OBJ_DIR_R)/%.o,$(SOURCES))
OBJS_D        = $(patsubst $(SRC_DIR)/%.$(SRC_EXT),$(OBJ_DIR_D)/%.o,$(SOURCES))

DEPS          = $(patsubst $(SRC_DIR)/%.$(SRC_EXT),$(DEP_DIR)/%.d,$(SOURCES))

INC_FLAGS     = $(patsubst %,-I%,$(INC_DIR))
LIB_FLAGS     = $(patsubst %,-L%,$(LIB_DIR))
RPATH_FLAGS   = $(if $(LIB_DIR),-Wl$(COMMA)-rpath=$(LIB_DIR)/,)
DEP_GEN_FLAGS = -MT $@ -MMD -MP -MF $(DEP_DIR)/$*.Td

TARGET_R      = $(if $(EXECNAME_R),$(BIN_DIR)/$(EXECNAME_R),$(BIN_DIR)/a.out)
TARGET_D      = $(if $(EXECNAME_D),$(BIN_DIR)/$(EXECNAME_D),$(BIN_DIR)/debug.a.out)

LIB_SUBDIRS   = $(sort $(dir $(wildcard $(LIB_DIR)/*/Makefile)))

# Set temporary dependency file as permanent one and update object
POST_COMPILE  = @mv -f $(DEP_DIR)/$*.Td $(DEP_DIR)/$*.d && touch $@

COL_RESET     = "\033[0m"
COL_1         = "\033[1;34m"
COL_2         = "\033[1;36m"


.PRECIOUS: $(SRC_DIR)/. $(OBJ_DIR_R)/. $(OBJ_DIR_D)/. $(DEP_DIR)/.


.PHONY: all release
all: $(TARGET_R)
release: all

.PHONY: debug
debug: $(TARGET_D)

.PHONY: run rrun
run: all
	$(TARGET_R) $(ARGS)
rrun: run

.PHONY: drun
drun: debug
	$(TARGET_D) $(ARGS)


%/.:
	mkdir -p $@


$(TARGET_R): $(LIB_SUBDIRS) $(OBJS_R) | $(BIND_DIR)/.
	$(CXX) $(CXXFLAGS) $(RELEASE_FLAGS) $(LIB_FLAGS) $(OBJS_R) $(RPATH_FLAGS) $(LDLIBS) -o $@

$(TARGET_D): $(LIB_SUBDIRS) $(OBJS_D) | $(BIND_DIR)/.
	$(CXX) $(CXXFLAGS) $(DEBUG_FLAGS)   $(LIB_FLAGS) $(OBJS_D) $(RPATH_FLAGS) $(LDLIBS) -o $@


.PHONY: $(LIB_SUBDIRS)
$(LIB_DIR)/%/:
	@$(ECHO_CMD) "$(COL_1)Now building the $(COL_2)$*$(COL_1) library$(COL_RESET)"
	@cd $@; $(MAKE_CMD)
	@$(ECHO_CMD) "$(COL_1)Done building the $(COL_2)$*$(COL_1) library$(COL_RESET)"

# 
# To make object files when we have a dependency file premade
$(OBJ_DIR_R)/%.o: $(SRC_DIR)/%.$(SRC_EXT) $(DEP_DIR)/%.d | $(OBJ_DIR_R)/. $(DEP_DIR)/.
	$(CXX) $(CXXFLAGS) $(RELEASE_FLAGS) $(INC_FLAGS) -c $< -o $@ $(DEP_GEN_FLAGS)
	$(POST_COMPILE)

$(OBJ_DIR_D)/%.o: $(SRC_DIR)/%.$(SRC_EXT) $(DEP_DIR)/%.d | $(OBJ_DIR_D)/. $(DEP_DIR)/.
	$(CXX) $(CXXFLAGS) $(DEBUG_FLAGS)   $(INC_FLAGS) -c $< -o $@ $(DEP_GEN_FLAGS)
	$(POST_COMPILE)


.PHONY: c
c:
	$(RM) $(OBJ_DIR_R)/*.o
	$(RM) $(OBJ_DIR_D)/*.o
	$(RM) $(DEP_DIR)/*.d
	$(RM) $(DEP_DIR)/*.Td

.PHONY: clean
clean: c
	$(RM) $(TARGET_R)
	$(RM) $(TARGET_D)
	find -P . -mindepth 1 -type d -empty -delete
	@for i in $(libs); do \
		echo -e "$(COL_1)Now cleaning the $(COL_2)$$(basename $$i)$(COL_1) library$(COL_RESET)"; \
		cd $$i; \
		$(MAKE_CMD) clean; \
		cd -; \
		echo -e "$(COL_1)Done cleaning the $(COL_2)$$(basename $$i)$(COL_1) library$(COL_RESET)"; \
	done;


$(DEPS): ;
include $(wildcard $(DEPS))
