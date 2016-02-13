#  Dtree -- distributed dynamic scheduler
#
#  Makefile
#

LIBRARY		= libdtree.a
SHAREDLIB	= libdtree.so
TEST		= dtreetest

CC		= mpiicc

CCFLAGS		= -openmp -mkl -shared -fpic

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

all: $(LIBRARY) $(SHAREDLIB) $(TEST)

$(LIBRARY): $(OBJS)
	rm -f $(LIBRARY)
	ar qvs $(LIBRARY) $(OBJS)

$(SHAREDLIB): $(OBJS)
	rm -f $(SHAREDLIB)
	$(CC) $(CCFLAGS) -o $(SHAREDLIB) $(OBJS)

%.o: %.c
	$(CC) $(CCFLAGS) -c $<

$(TEST): $(LIBRARY) $(TEST_OBJS)
	$(CC) $(CCFLAGS) -o $(TEST) $(TEST_OBJS) -L. -ldtree

clean:
	rm -f $(LIBRARY) $(OBJS) $(TEST_OBJS) $(TEST)

