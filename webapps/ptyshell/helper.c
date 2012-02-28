#include "helper.h"

#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/*---------------------------------------------------------------------------
 * Determines the current signal mask for the calling process.
 */
void get_signal_mask(sigset_t * mask)
{
    sigprocmask(SIG_SETMASK, NULL, mask);
}

/*---------------------------------------------------------------------------
 * Blocks the specified signal.
 */
void block_signal(int signal_number)
{
    sigset_t mask;

    sigemptyset(&mask);
    sigaddset(&mask, signal_number);
    sigprocmask(SIG_BLOCK, &mask, NULL);
}

/*---------------------------------------------------------------------------
 * Unblocks the specified signal.
 */
void unblock_signal(int signal_number)
{
    sigset_t mask;

    sigemptyset(&mask);
    sigaddset(&mask, signal_number);
    sigprocmask(SIG_UNBLOCK, &mask, NULL);
}

/*---------------------------------------------------------------------------
 * Sets up a handler for the given signal.
 * The 'flags' parameter can contain these bits: SA_NOCLDSTOP, SA_NOCLDWAIT,
 * SA_RESETHAND, SA_ONSTACK, SA_RESTART, SA_NODEFER (see sigaction() manpage).
 */
void set_signal_handler(int signal_number, signal_handler_t handler, int flags)
{
    struct sigaction action;
    memset(&action, 0, sizeof(action));

    action.sa_sigaction = handler;
    sigemptyset(&action.sa_mask);
    action.sa_flags = SA_SIGINFO|flags;
    sigaction(signal_number, &action, NULL);
}

/*---------------------------------------------------------------------------
 * Waits for reception of the given signal (which must have a handler).
 */
void wait_for_signal(int signal_number)
{
    sigset_t signal_mask;

    /* Block all signals except the desired one. */
    sigfillset(&signal_mask);
    sigdelset(&signal_mask, signal_number);

    /* Unblock critical signals that should always be acted upon. */
    sigdelset(&signal_mask, SIGTERM);
    sigdelset(&signal_mask, SIGSEGV);
    sigdelset(&signal_mask, SIGILL);
    sigdelset(&signal_mask, SIGBUS);
    sigdelset(&signal_mask, SIGINT);

    sigsuspend(&signal_mask);
}

/*---------------------------------------------------------------------------
 * Waits for reception of one of two signals (both must have a handler).
 */
void wait_for_2_signals(int signal_number1, int signal_number2)
{
    sigset_t signal_mask;

    /* Block all signals, except for the two desired ones. */
    sigfillset(&signal_mask);
    sigdelset(&signal_mask, signal_number1);
    sigdelset(&signal_mask, signal_number2);

    /* Unblock critical signals that should always be acted upon. */
    sigdelset(&signal_mask, SIGTERM);
    sigdelset(&signal_mask, SIGSEGV);
    sigdelset(&signal_mask, SIGILL);
    sigdelset(&signal_mask, SIGBUS);
    sigdelset(&signal_mask, SIGINT);

    sigsuspend(&signal_mask);
}

/*---------------------------------------------------------------------------
 * Writes a string to the file represented by a file descriptor.
 * The string must be short enough to allow atomic writing.
 */
void write_string(int fd, const char * str)
{
    int length = strlen(str);
    write(fd, str, length);
}
