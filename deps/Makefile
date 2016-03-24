#  Dtree -- distributed dynamic scheduler
#
#  Makefile
#

SHAREDLIB	= libdtree.so

CC		= mpiicc
CCFLAGS		= -openmp -mkl -shared -fpic
LDFLAGS		= -openmp -mkl

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

%.o: %.c
	$(CC) $(CCFLAGS) -c $<

$(SHAREDLIB): $(OBJS)
	$(CC) $(CCFLAGS) -o $(SHAREDLIB) $(OBJS)

$(LIBRARY): $(OBJS)
	rm -f $(LIBRARY)
	ar qvs $(LIBRARY) $(OBJS)

all: $(SHAREDLIB)

clean:
	rm -f $(SHAREDLIB) $(OBJS)

