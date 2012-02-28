#ifndef HELPER_H
#define HELPER_H

#include <signal.h>

/*---------------------------------------------------------------------------
 * A signal handler prototype.
 */
typedef void (* signal_handler_t)(int, siginfo_t *, void *);

void get_signal_mask(sigset_t * mask);
void block_signal(int signal_number);
void unblock_signal(int signal_number);
void set_signal_handler(int signal_number, signal_handler_t handler, int flags);
void wait_for_signal(int signal_number);
void wait_for_2_signals(int signal_number1, int signal_number2);

void write_string(int fd, const char * str);

#endif
