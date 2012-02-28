#define _SVID_SOURCE
#define _XOPEN_SOURCE 600

#include "debug.h"
#include "helper.h"
#include "subshell.h"
#include "utmp.h"
#include "user.h"

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <pwd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <termios.h>
#include <unistd.h>
#include <utmpx.h>
#include <grp.h>
#include <sys/ioctl.h> /* For ioctl(TIOCSWINSZ) */

#ifndef TIOCSWINSZ /* Hardcode this constant for compiling with lsbcc */
#define TIOCSWINSZ      0x5414
#endif

int initgroups(const char *user, gid_t group);

/*---------------------------------------------------------------------------
 * Name of the file where the PID of the subshell is written.
 */
char * subshell_pidfile = NULL;

/*---------------------------------------------------------------------------
 * Input stream that feeds us with input for the pseudo-terminal.
 * Typically stdin, but not always.
 */
int input_fd = 0;

/*---------------------------------------------------------------------------
 * Output stream where the output from the pseudo-terminal is sent.
 * Typically stdout, but not always.
 */
int output_fd = 1;

/*---------------------------------------------------------------------------
 * This flag is set to 1 when the SIGUSR1 signal is processed
 * by sigusr1_handler().
 */
static int sigusr1_flag = 0;

/*---------------------------------------------------------------------------
 * This flag is set to 1 when the SIGHUP signal is processed
 * by sighup_handler().
 */
static int sighup_flag = 0;

/*---------------------------------------------------------------------------
 * This flag is set to 1 when the SIGCHLD signal is processed
 * by sigchld_handler().
 */
static int sigchld_flag = 0;

/*---------------------------------------------------------------------------
 * Handler for the SIGUSR1 signal, used for synchronization between
 * the parent and the child (subshell).
 */
static void sigusr1_handler(int signal_number, siginfo_t * signal_info, void * context)
{
    sigusr1_flag = 1;
}

/*---------------------------------------------------------------------------
 * A handler for the SIGHUP signal.
 */
static void sighup_handler(int signal_number, siginfo_t * signal_info, void * context)
{
    sighup_flag = 1;
}

/*---------------------------------------------------------------------------
 * A handler for the SIGCHLD signal.
 */
static void sigchld_handler(int signal_number, siginfo_t * signal_info, void * context)
{
    sigchld_flag = 1;
}

/*---------------------------------------------------------------------------
 * A filedescriptor of the master side of the pseudo-terminal.
 */
static int pty_master_fd;

/*---------------------------------------------------------------------------
 * The PID of the subshell process.
 */
static int subshell_pid;

/*---------------------------------------------------------------------------
 * Old tty attrs.
 */
static struct termios tty_attr_old;

/*---------------------------------------------------------------------------
 * Writes the subshell PID to pidfile (if it is specified).
 */
static void write_pidfile(pid_t pid)
{
    if (subshell_pidfile == NULL) return;

    FILE * f = fopen(subshell_pidfile, "w");
    if (f == NULL) {
        error("could not write PID to file '%s'", subshell_pidfile);
        return;
    }

    fprintf(f, "%u|%u\n", getpid(), pid);
    fclose(f);
}

/*---------------------------------------------------------------------------
 * Deletes the previously written pidfile (if any).
 */
static void delete_pidfile(void)
{
    if (subshell_pidfile) {
        remove(subshell_pidfile);
    }
}

/*---------------------------------------------------------------------------
 * This function is called in the subprocess created by spawn_subshell().
 * It is responsible for setting everything up and executing a shell.
 *
 * This call never returns; if it succeeds, the shell executes instead.
 *
 * If a failure occurs during the preparations, or when the shell
 * cannot be started, the subprocess exits with code 127.
 */
static void subshell_worker(
    uid_t user_id,
    gid_t group_id,
    const char * user_name,
    const char * user_home,
    const char * env_path,
    const char * slave_tty,
    const char * env_term
)
{
    /* Get the PID of this process. */
    pid_t subshell_pid = getpid();

    /* Disconnect standard input and output streams. */
    close(0);
    close(1);
    close(2);

    /* This is a stupid phase when we cannot print anything,
     * as the input and output are closed; if something fails,
     * we simply terminate with a nonzero exit code.
     */

    /* Create a new session and disconnect from the controlling tty. */
    if (setsid() != subshell_pid) {
        exit(127);
    }

    /* Connect to the slave part of our pseudo-terminal, attaching
     * standard input and output to it, and make it the controlling
     * tty of the subprocess.
     */
    if (open(slave_tty, O_RDWR|O_APPEND) != 0) {
        error("could not open slave_tty");
        exit(127);
    }
    dup2(0, 1);
    dup2(0, 2);

    /* Send a signal to the parent indicating
     * that we are ready to start the shell, and prepare
     * for receiving an acknowledging signal.
     */
    block_signal(SIGUSR1);
    if (kill(getppid(), SIGUSR1) != 0) {
        exit(127);
    }

    /* Wait for signal from parent. */
    wait_for_signal(SIGUSR1);

    /* From now on, we have again a terminal so we can print messages;
     * they will be sent to the parent via the pseudo-tty.
     */

    /* Reset the environment to give the shell a clean start.
     * Only TERM and HOME variables will be set.
     */
    // clearenv(); // not in LSB!
    environ = NULL; // Not the best way, but a simple one.
    
    setenv("TERM", env_term, 1);
    setenv("HOME", user_home, 1);
    setenv("PATH", env_path, 1);

    /* Become the target user. */
    if (initgroups( user_name, group_id) != 0) {
        if (errno == EPERM) {
            write_string(0, "ptyshell (subshell): could not init groups (insufficient privileges)\n");
        }
        else {
            write_string(0, "ptyshell (subshell): could not init groups (not enough resources?)\n");
        }
        exit(127);
    }
    if (setgid(group_id) != 0) {
        if (errno == EPERM) {
            write_string(0, "ptyshell (subshell): could not switch groups (insufficient privileges)\n");
        }
        else {
            write_string(0, "ptyshell (subshell): could not switch groups (process limit?)\n");
        }
        exit(127);
    }
    if (setuid(user_id) != 0) {
        if (errno == EPERM) {
            write_string(0, "ptyshell (subshell): could not switch users (insufficient privileges)\n");
        }
        else {
            write_string(0, "ptyshell (subshell): could not switch users (process limit?)\n");
        }
        exit(127);
    }

    /* Change the current path to the user's home directory. */
    if (chdir(user_home) != 0) {
        write_string(0, "ptyshell (subshell): could not switch to the home directory\n");
        exit(127);
    }

    unblock_signal(SIGUSR1);
    unblock_signal(SIGCHLD);

    /* Execute the shell. */
    execlp("/bin/bash", "/bin/bash", "-l", "-i", (char *) NULL);

    /* We can only get here when the shell fails to start. */
    write_string(0, "ptyshell (subshell): failed to execute shell");
    exit(127);
}

/*---------------------------------------------------------------------------
 * Spawns a subshell with a pseudo-terminal communicating with it.
 */
int spawn_subshell(uid_t user_id)
{
    struct winsize w;
    
    /* Initialize internal variables. */
    pty_master_fd = -1;
    subshell_pid = (pid_t) -1;

    /* Remember the TERM environment variable; it will be passed
     * to the subshell.
     */
    const char * env_term = getenv("TERM");

    /* Get information about the target user. */
    struct passwd * user_data = getpwuid(user_id);
    if (user_data == NULL) {
        error("could not read user info");
        goto fail;
    }

    /* Determine the user name and home directory. */
    const char * user_home = user_data->pw_dir;
    const char * user_name = user_data->pw_name;
    gid_t group_id = user_data->pw_gid;

    gid_t tty_gid = get_group_id("tty");

    /* Check that the user name and home are sane. */
    if ((user_home == NULL) || (user_home[0] == '\0')) {
        error("user has no home directory");
        goto fail;
    }
    if ((user_name == NULL) || (user_name[0] == '\0')) {
        error("user has no name");
        goto fail;
    }
    
    /* getconf PATH */
    char env_path[1024];
    size_t conf_sz = confstr(_CS_PATH, env_path, sizeof(env_path));
    if ( conf_sz == 0 || conf_sz < sizeof(env_path) ) {
        /* Error */
        strcpy(env_path, "/bin:/usr/bin");
    }

    /* Allocate a pseudo-terminal. */
    pty_master_fd = open("/dev/ptmx", O_RDWR|O_APPEND|O_NOCTTY);
    if (pty_master_fd < 0) {
        error("could not allocate a pseudo-terminal");
        goto fail;
    }

    /* Unlock the slave side of the terminal. */
    if (unlockpt(pty_master_fd) != 0) {
        error("could not unlock the pseudo-terminal");
        goto fail;
    }

    /* Find out the name of the slave part of the terminal. */
    const char * slave_tty = ptsname(pty_master_fd);
    if (slave_tty == NULL) {
        error("could not determine the pseudo-terminal slave name");
        goto fail;
    }

    /* Change the access rights of the slave side to the master. */
    if (grantpt(pty_master_fd) != 0) {
        error("could not set up the pseudo-terminal access rights");
        goto fail;
    }
    
    /* Set the pseudo-terminal width to a big number. */
    w.ws_row = 0;
    w.ws_col = 30000;
    w.ws_xpixel = 0;
    w.ws_ypixel = 0;
    if ( ioctl(pty_master_fd, TIOCSWINSZ, &w) != 0 ) {
        error("could not set up the pseudo-terminal size");
    }
    
    /* Make the test user the owner of the slave part of the terminal;
     * this is required for many tests that read or modify terminal
     * settings.
     */
    if (chown(slave_tty, user_id, tty_gid) != 0) {
        error("Could not change the owner of a tty");
        goto fail;
    }

    /* Establish a signal handler for the SIGUSR1 signal we will use
     * for synchronization with the child. (The handler is the same
     * both for the parent as the child, as it only sets a flag.)
     */
    set_signal_handler(SIGUSR1, sigusr1_handler, SA_RESETHAND);

    /* Set handler for the SIGCHLD stop so that we are informed
     * if the subshell crashes or terminates unexpectedly.
     */
    set_signal_handler(SIGCHLD, sigchld_handler, SA_RESETHAND|SA_NOCLDSTOP);

    /* Block both signal until we are ready to handle them. */
    block_signal(SIGUSR1);
    block_signal(SIGCHLD);

    /* Create the subprocess. */
    subshell_pid = fork();
    if (subshell_pid < 0) {
        error("could not spawn the subshell");
        goto fail;
    }
    if (subshell_pid == 0) {

        /* This code is executed in the subprocess. */
        subshell_worker(user_id, group_id, user_name, user_home, env_path, slave_tty, env_term);
        exit(127);
    }

    /* Print the PID and tty of the subshell first. */
    notify("subshell PID=%u, tty=%s", subshell_pid, slave_tty);
    write_pidfile(subshell_pid);

    /* Wait for the child process to initialize; it will acknowledge this
     * by sending us the SIGUSR1 signal.
     */
    notify("waiting for the subshell to initialize");
    wait_for_2_signals(SIGUSR1, SIGCHLD);

    unblock_signal(SIGCHLD);

    if (sigchld_flag) {
        error("subshell terminated early");
        goto fail;
    }

    if (geteuid() == 0) {

        /* Write an utmp entry describing this "login". */
        struct utmpx utmp_entry;
        init_utmp_entry(&utmp_entry, user_name, slave_tty, subshell_pid);
        if (!write_utmp_entry(&utmp_entry)) {
            goto fail_with_subshell;
        }
    }
    else {
        notify("not running as root, so not writing an utmp entry");
    }

    /* Send the child a signal that it can continue. */
    notify("signaling the subshell to start execution");
    if (kill(subshell_pid, SIGUSR1) != 0) {
        error("error communicating with subshell");
        goto fail_with_subshell;
    }

    /* Disable terminal echoing as it is of no use for us. */
    struct termios tty_attr;
    tcgetattr(input_fd, &tty_attr_old);
    tty_attr = tty_attr_old;
    //cfmakeraw(&tty_attr);
    tty_attr.c_lflag &= ~(ECHO | ECHONL);
    tcsetattr(input_fd, TCSADRAIN, &tty_attr);

    /* Success. */
    notify("subshell is running");
    return 1;

    int status; /* must be declared before the label */

fail_with_subshell:

    /* If we get here, we have managed to create the subshell,
     * but something failed later on. The subshell may or may not
     * exist at this moment (it may died immediately after creation).
     */

    /* Close the terminal; the subshell should terminate. */
    close(pty_master_fd);

    /* Wait for the subshell to terminate
     * (don't be surprised if it does not exist anymore).
     */
    waitpid(subshell_pid, &status, 0);

    /* Delete the PID file and exit. */
    delete_pidfile();
    return 0;

fail:

    /* Cleanup after failure. */
    if (pty_master_fd >= 0) {
        close(pty_master_fd);       /* Close the tty. */
        delete_pidfile();           /* Delete the PID file, if any. */
    }

    return 0;
}

/*---------------------------------------------------------------------------
 * Closes the subshell.
 */
void subshell_close(void)
{
    close(pty_master_fd);
    delete_pidfile();
        
    /* Enable terminal echoing back. */
    tcsetattr(input_fd, TCSADRAIN, &tty_attr_old);

    notify("subshell closed");
}

#define RELAY_BUFFER_SIZE 1024

/*---------------------------------------------------------------------------
 * A loop that relays data from terminal to standard output,
 * and from standard input to terminal. The loop runs until the terminal
 * output is closed (closing the input does not stop it).
 */
int subshell_relay_loop(void)
{
    int flags;
    char buf[RELAY_BUFFER_SIZE];
    struct pollfd pfds[2];

    /* Install handler for the SIGHUP signal which means we should
     * send a hangup character to the terminal.
     */
    set_signal_handler(SIGHUP, sighup_handler, 0);

    /* Use non-blocking reads from terminal. */
    flags = fcntl(pty_master_fd, F_GETFL);
    fcntl(pty_master_fd, F_SETFL, flags | O_NONBLOCK);

    /* Use non-blocking reads from the input. */
    flags = fcntl(input_fd, F_GETFL);
    fcntl(input_fd, F_SETFL, flags | O_NONBLOCK);

    pfds[0].fd = pty_master_fd;
    pfds[0].events = POLLIN;
    pfds[0].revents = 0;
    pfds[1].fd = input_fd;
    pfds[1].events = POLLIN;
    pfds[1].revents = 0;

    for (;;) {

        /* Relay data from the terminal to the output. */
        int bytes_read = read(pty_master_fd, buf, RELAY_BUFFER_SIZE);
        if (bytes_read < 0) {
            if (errno != EAGAIN) {
                break;                      /* no data arrived so far */
            }
        }
        else if (bytes_read == 0) {
            notify("connection closed by subshell");
            break;
        }
        else if (bytes_read > 0) {
            write(output_fd, buf, bytes_read);
            continue; /* Give terminal output higher priority. */
        }

        /* Relay data from the input to the terminal. */
        bytes_read = read(input_fd, buf, RELAY_BUFFER_SIZE);
        if (bytes_read > 0) {
            write(pty_master_fd, buf, bytes_read);
        }
        else if (bytes_read == 0) {

            /* If the standard input is finished, we send Ctrl+D
             * to the terminal and wait for the subshell to finish
             * (this may require an arbitrary time if the subshell
             * is executing a long task).
             */
            buf[0] = '\004';
            write(pty_master_fd, buf, 1);
        }
        else {
            /* ignore errors on input */
        }

        /* If the SIGHUP signal was received in the meantime,
         * send a hangup character to the terminal.
         */
        if (sighup_flag) {
            notify("SIGHUP received");
            buf[0] = '\004';
            write(pty_master_fd, buf, 1);
            sighup_flag = 0;
        }

        /* Check the child process */
        int status;
        int wresult = waitpid(subshell_pid, &status, WNOHANG);
        if ( wresult != 0 ) {
            /* 
             * Child process has exited, but pty_master_file isn't closed for
             * some reason. Stop waiting.
             */
            goto after_waitpid;
        }
        
        /* Wait for input either from the terminal, or from standard input. */
        poll(pfds, 2, -1);
    }

    /* Wait for the subshell process to terminate. */
    int status;
    if (waitpid(subshell_pid, &status, 0) != subshell_pid) {
        error("error while waiting for subshell");
        return -1;
    }
  after_waitpid:
    if (!WIFEXITED(status)) {
        error("subshell terminated abnormally");
        return -1;
    }
    if (WEXITSTATUS(status) != 0) {
        error("subshell terminated with exit code %d", WEXITSTATUS(status));
    }
    return WEXITSTATUS(status);
}
