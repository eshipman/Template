################################################################################
# Author : Evan Shipman
# Version: 1.2
################################################################################
#
# This general purpose Makefile should be reusable for many projects structured
# in the following way:
#   project/
#     build/		- Built executables
#     obj/			- Compiled object files
#     src/			- Source files
#       common/	- Common source files
#       */			- Source files to compile as executables (with common/)
#     lib/			- Directory to add to the library includes list
#       */			- Subdirectories to also add to the library includes list
#     inc/			- Directory to add to the includes list
#       */			- Subdirectories to also add to the includes list
#
# Note: All sources in src/<dir> will be compiled as an executable called <dir>
#       and will be automatically linked with all object files compiled from
#       sources in src/common. For example:
#         The following sources/objects:
#           src/common/util.c    -> obj/src/common/util.c.o
#           src/test123/main.c   -> obj/src/test123/main.c.o
#           src/test456/main.cpp -> obj/src/test456/main.cpp.o
#         Will result in the following executables:
#           obj/src/common/util.c.o + obj/src/test123/main.c.o   -> build/test123
#           obj/src/common/util.c.o + obj/src/test456/main.cpp.o -> build/test456
#     	By default, the following directories will automatically be added to the
#   		list of directories to search for libraries (with -L):
#						lib/, lib/*
#
################################################################################
# Changelog:
# v1.0 - Initial creation
# V1.1 - Changed most @echo calls to $(info) for portability
# V1.2 - Added doxygen build target
################################################################################

# Set the compilers if none already set
CC  ?= gcc
CXX ?= g++

# Set the commands and options used by this Makefile
MKDIR ?= mkdir -p
RM    ?= rm -f
LINK  ?= ln -sf

# Set the project directories
SRC_DIR ?= src
OBJ_DIR ?= obj
BLD_DIR ?= build
INC_DIR ?= inc
LIB_DIR ?= lib
COMMON  ?= common

# Set the C/C++ specific flags
# By default, use older standards for maximum compatibility
CXXFLAGS ?= --std=c++98
CFLAGS   ?= --std=c99

# Set the linker and general flags
LDFLAGS ?=
FLAGS   ?= -O3 -fPIE -g3

################################################################################
## DON'T CHANGE ANYTHING BELOW HERE																						##
## All other variables should be set based on the variables above							##
################################################################################

# Set the directory of source files common to all executables
COM_DIR := $(SRC_DIR)/$(COMMON)

# Each subdirectory in the SRC_DIR is an executable (except COMMON)
EXES := $(addprefix $(BLD_DIR)/,$(shell find $(SRC_DIR) -mindepth 1 -maxdepth 2 \( \! -path "$(COM_DIR)" \) -type d -printf '%f\n'))

# Gather the C/C++ source files, the object names, and dependency files
SRCS := $(shell find $(SRC_DIR) -type f -name '*.cpp' -or -name '*.c')
OBJS := $(SRCS:%=$(OBJ_DIR)/%.o)
DEPS := $(OBJS:.o=.d)

# Separate the common source objects
COBS := $(strip $(foreach file,$(OBJS),$(filter $(OBJ_DIR)/$(COM_DIR)/%,$(file))))

# Set the includes/library path flags and add to the general flags
INC_FLAGS := $(addprefix -I,$(shell find $(INC_DIR) -maxdepth 1 -type d -printf '%f\n') $(SRC_DIR))
LIB_FLAGS := $(addprefix -L,$(shell find $(LIB_DIR) -maxdepth 1 -type d -printf '%f\n'))
FLAGS += -MMD -MP $(INC_FLAGS) $(LIB_FLAGS)

.PHONY: clean all again show

# The default target should just be the executables in $(BLD_DIR)/
all: $(EXES)

again: clean all

# Create a link to $(BLD_DIR)/<exe> at ./<exe>
$(notdir $(EXES)): $(EXES)
	$(info Creating link to $(BLD_DIR)/$@)
	$(LINK) $(BLD_DIR)/$@ $@
	@echo

# Link the executable with the objects from its source dir and the common objects
$(EXES): $(OBJS)
	$(info Linking executable $@)
	$(MKDIR) $(dir $@)
	$(CXX) -I$(SRC_DIR)/$(notdir $@) $(FLAGS) $(CXXFLAGS) -o $@ \
		$(strip $(foreach file,$(OBJS),$(filter $(OBJ_DIR)/$(SRC_DIR)/$(notdir $@)/%,$(file)))) \
		$(COBS) $(LDFLAGS)
	@echo

# Compile the C++ source files
$(OBJ_DIR)/%.cpp.o: %.cpp
	$(info Compiling C++ source file $<)
	$(MKDIR) $(dir $@)
	$(CXX) -I$(dir $<) $(FLAGS) $(CXXFLAGS) -c $< -o $@
	@echo


# Compile the C source files
$(OBJ_DIR)/%.c.o: %.c
	$(info Compiling C source file $<)
	$(MKDIR) $(dir $@)
	$(CC) -I$(dir $<) $(FLAGS) $(CFLAGS) -c $< -o $@
	@echo

# Generate doxygen docs
docs:
	$(info Generating documentation)
	$(MKDIR) docs
	doxygen Doxyfile
	@echo

# Show the major defined variables for debugging purposes
show:
	$(info Executables : $(EXES))
	$(info Source Files: $(SRCS))
	$(info Object Files: $(OBJS))
	$(info Dependencies: $(DEPS))
	$(info Common Objs.: $(COBS))

# Remove all built objects, executables, and links
clean:
	$(RM) -r $(OBJ_DIR) $(BUILD_DIR) $(EXES) $(notdir $(EXES)) 2>/dev/null

-include $(DEPS)
