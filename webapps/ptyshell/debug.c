#include "debug.h"

#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

/*---------------------------------------------------------------------------
 * The verbosity flag.
 */
int verbose = 0;

/*---------------------------------------------------------------------------
 * Prints a message in printf-style if the verbosity flag is set.
 * A newline is added automatically.
 */
void notify(const char * message, ...)
{
    va_list args;

    if (verbose) {

        fputs("ptyshell: ", stderr);

        va_start(args, message);
        vfprintf(stderr, message, args);
        va_end(args);

        putc('\n', stderr);
    }
}

/*---------------------------------------------------------------------------
 * Prints an error message with printf-style formatting (a newline is
 * added automatically).
 */
void error(const char * message, ...)
{
    va_list args;
    const char * errno_desc = NULL;

    /* If errno is set, get its string description. */
    if (errno > 0) {
        errno_desc = strerror(errno);
    }

    fputs("ptyshell: ", stderr);

    va_start(args, message);
    vfprintf(stderr, message, args);
    va_end(args);

    /* If errno was set, append the error description. */
    if (errno_desc) {
        fputs(" [", stderr);
        fputs(errno_desc, stderr);
        putc(']', stderr);
    }

    /* Add a newline. */
    putc('\n', stderr);
}

/*
 * Reports a failed assertion and terminates the program.
 * This call never returns.
 */
void failed_assertion(const char * cond)
{
    fprintf(stderr, "ptyshell: assertion failed: %s\n", cond);
    exit(127);
}

/*
 * Introduces an assertion. If the condition 'x' is not valid
 * at the run-time, the program is immediately terminated.
 */
#define assert(x) if (!(x)) { failed_assertion(#x); }
