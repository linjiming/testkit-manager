#ifndef DEBUG_H
#define DEBUG_H

extern int verbose;

void notify(const char * message, ...);
void error(const char * message, ...);

#endif
