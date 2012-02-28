#ifndef UTMP_H
#define UTMP_H

#include <sys/types.h>

struct utmpx;

int init_utmp_entry(
    struct utmpx * entry,
    const char * user_name,
    const char * tty_name,
    pid_t shell_pid
);

int write_utmp_entry(struct utmpx * entry);

#endif
