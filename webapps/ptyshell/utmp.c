#include "debug.h"
#include "utmp.h"

#include <assert.h>
#include <string.h>
#include <time.h>
#include <utmpx.h>

/* Initializes the utmp structure so that it represents a login
 * or logout event.
 *
 * Parameters:
 *    entry - the entry to be initialized
 *    user_name - user name for a login, or NULL for a logout
 *    tty_name - name of the terminal
 *    shell_pid - PID of the login shell
 *
 * Returns true on success, false on failure.
 */
int init_utmp_entry(
    struct utmpx * entry,
    const char * user_name,
    const char * tty_name,
    pid_t shell_pid
)
{
    time_t current_time;

    /* Clear the entry to zeros first. */
    memset(entry, 0, sizeof(*entry));

    /* If we want a login entry, simulate a shell process running
     * on the terminal; if we want a logout, simulate an already
     * finished shell.
     */
    entry->ut_type = user_name ? USER_PROCESS : DEAD_PROCESS;

    /* For a login entry, a terminal line must be specified;
     * for a logout entry, it stays filled with zeros.
     */
    if (user_name) {
        strcpy(entry->ut_line, tty_name + strlen("/dev/"));
    }

    /* Fill in the utmp id from the terminal name. */
    strcpy(entry->ut_id, tty_name + strlen("/dev/tty"));

    /* For a login entry, a user name must be specified;
     * for a logout entry, it stays filled with zeros.
     */
    if (user_name) {
        strcpy(entry->ut_user, user_name);
    }

    /* Store the specified PID as the shell PID. */
    entry->ut_pid = shell_pid;

    /* For a login entry, a login time must be specified;
     * for a logout entry, it stays zero.
     */
    if (user_name) {
        time(&current_time);
        entry->ut_tv.tv_sec = current_time;
        entry->ut_tv.tv_usec = 0;
    }

    /* The 'ut_host' and 'ut_addr' fields are left empty because we simulate
     * a local connection. Also the 'ut_session' field is left empty
     * as it is not used for terminal sessions.
     */

    /* Done. */
    return 1;
}

/* Writes a previously prepared utmp entry to the utmp file.
 * Returns true on success, false on failure.
 */
int write_utmp_entry(struct utmpx * entry)
{
    /* Open the utmp file. */
    setutxent();

    /* Write the entry. */
    if (pututxline(entry) == NULL) {
        error("Could not write utmp entry");
        return 0;
    }

    /* Close the utmp file. */
    endutxent();

    /* Success. */
    return 1;
}
