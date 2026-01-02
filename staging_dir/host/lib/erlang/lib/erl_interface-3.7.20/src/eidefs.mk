#
# %CopyrightBegin%
# 
# Copyright Ericsson AB 2004-2009. All Rights Reserved.
# 
# The contents of this file are subject to the Erlang Public License,
# Version 1.1, (the "License"); you may not use this file except in
# compliance with the License. You should have received a copy of the
# Erlang Public License along with this software. If not, it can be
# retrieved online at http://www.erlang.org/.
# 
# Software distributed under the License is distributed on an "AS IS"
# basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
# the License for the specific language governing rights and limitations
# under the License.
# 
# %CopyrightEnd%
#

# ----------------------------------------------------------------------

# Have the ei and erl_interface libs been compiled for threads?
EI_THREADS=true

# Threads flags
THR_DEFS= -D_THREAD_SAFE -D_REENTRANT -DPOSIX_THREADS -D_POSIX_THREAD_SAFE_FUNCTIONS

# Threads libs
THR_LIBS=-lpthread

# ----------------------------------------------------------------------
