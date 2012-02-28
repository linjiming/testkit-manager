#include "user.h"
#include "debug.h"

#include <pwd.h>
#include <stdlib.h>
#include <grp.h>

/*---------------------------------------------------------------------------
 * Determines the UID of the user with the given name.
 * Returns the UID, or (uid_t) -1 if the user is not found.
 */
uid_t uid_from_user_name(const char * name)
{
    struct passwd * pwd = getpwnam(name);
    if (pwd == NULL) return (uid_t) -1;
    return pwd->pw_uid;
}

/*---------------------------------------------------------------------------
 * Get group ID by its name.
 */
gid_t get_group_id(const char * group_name)
{
    struct group * group_info;

    /* Get info about the group. */
    group_info = getgrnam(group_name);
    if (group_info == NULL) {
        error("Could not find group '%s'", group_name);
        exit(127);
    }

    /* Extract the group ID and return it. */
    return group_info->gr_gid;
}
