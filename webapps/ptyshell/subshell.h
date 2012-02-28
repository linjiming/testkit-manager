#ifndef SUBSHELL_H
#define SUBSHELL_H

#include <sys/types.h>

extern char * subshell_pidfile;
extern int input_fd;
extern int output_fd;

int spawn_subshell(uid_t user_id);
void subshell_close(void);
int subshell_relay_loop(void);

extern char ** environ;

#endif
