#  Dtree -- distributed dynamic scheduler
#
#  Makefile
#

LIBRARY		= libdtree.a
TEST		= dtreetest

CC		= mpiicc

CCFLAGS		= -openmp -mkl

ifndef DEBUG
CCFLAGS		+= -O3 -g
else
CCFLAGS		+= -O0 -g -DDEBUG_DTREE -DTRACE_DTREE=$(DEBUG)
endif

ifdef SHOW
CCFLAGS		+= -DSHOW_DTREE
endif

ifdef TRACE
CCFLAGS		+= -DTRACE_DTREE=$(TRACE)
endif

ifdef PROFILE
CCFLAGS		+= -DPROFILE_DTREE
endif

ifdef MIC
CCFLAGS		+= -mmic
else
CCFLAGS		+= -mavx
endif

OBJS		= dtree.o
TEST_OBJS	= $(TEST).o

all: $(LIBRARY) $(TEST)

$(LIBRARY): $(OBJS)
	rm -f $(LIBRARY)
	ar qvs $(LIBRARY) $(OBJS)

%.o: %.c
	$(CC) $(CCFLAGS) -c $<

$(TEST): $(LIBRARY) $(TEST_OBJS)
	$(CC) $(CCFLAGS) -o $(TEST) $(TEST_OBJS) -L. -ldtree

clean:
	rm -f $(LIBRARY) $(OBJS) $(TEST_OBJS) $(TEST)

