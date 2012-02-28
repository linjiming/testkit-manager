#ifndef USER_H
#define USER_H

#include <sys/types.h>      /* uid_t */

uid_t uid_from_user_name(const char * name);


gid_t get_group_id(const char * group_name);

#endif
