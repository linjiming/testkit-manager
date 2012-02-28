#include "debug.h"
#include "subshell.h"
#include "user.h"

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

/*---------------------------------------------------------------------------
 * This flag is set when the '--help' argument is used.
 */
int help_requested = 0;

/*---------------------------------------------------------------------------
 * User name or ID of the target user, if specified on the command line
 * (with the '-u' option).
 */
char * target_user = NULL;

/*---------------------------------------------------------------------------
 * Name of the file used for input, if specified (the '--infile' option);
 * otherwise NULL.
 */
char * infile = NULL;

/*---------------------------------------------------------------------------
 * Name of the file used for output, if specified (the '--outfile' option);
 * otherwise NULL.
 */
char * outfile = NULL;

/*---------------------------------------------------------------------------
 * File descriptor of the input file (-1 if not applicable).
 */
int infile_fd = -1;

/*---------------------------------------------------------------------------
 * File descriptor of the output file (-1 if not applicable).
 */
int outfile_fd = -1;

/*---------------------------------------------------------------------------
 * Parses the command line and loads its contents into global variables.
 * Returns nonzero on success.
 * If an error occurs, an error message is printed and zero is returned.
 */
static int process_command_line(int argc, char ** argv)
{
    int target_user_expected = 0;
    int pidfile_expected = 0;
    int infile_expected = 0;
    int outfile_expected = 0;

    /* Read the command line arguments one after one. */
    int i;
    for (i = 1; i < argc; i++) {
        const char * arg = argv[i];

        /* Handle arguments to options. */
        if (target_user_expected) {
            target_user = strdup(arg);
            target_user_expected = 0;
            continue;
        }
        if (pidfile_expected) {
            subshell_pidfile = strdup(arg);
            pidfile_expected = 0;
            continue;
        }
        if (infile_expected) {
            infile = strdup(arg);
            infile_expected = 0;
            continue;
        }
        if (outfile_expected) {
            outfile = strdup(arg);
            outfile_expected = 0;
            continue;
        }

        /* Arguments starting with a dash are options. */
        if (arg[0] == '-') {
            if (strcmp(arg, "--pidfile") == 0) {
                if (subshell_pidfile) {
                    error("the '--pidfile' option can be only used once");
                    return 0;
                }
                pidfile_expected = 1;
            }
            else if (strcmp(arg, "--infile") == 0) {
                if (infile) {
                    error("the '--infile' option can be only used once");
                    return 0;
                }
                infile_expected = 1;
            }
            else if (strcmp(arg, "--outfile") == 0) {
                if (outfile) {
                    error("the '--outfile' option can be only used once");
                    return 0;
                }
                outfile_expected = 1;
            }
            else if (strcmp(arg, "-u") == 0) {
                if (target_user) {
                    error("the '-u' option can be only used once");
                    return 0;
                }
                target_user_expected = 1;
            }
            else if (strcmp(arg, "-v") == 0) {
                verbose = 1;
            }
            else if (strcmp(arg, "--help") == 0) {
                help_requested = 1;
                return 1;
            }
            else {
                error("unrecognized option '%s' (try '--help')", arg);
                return 0;
            }
        }
        else {

            /* This is not an option, but no argument is expected. */
            error("unexpected argument '%s' (try '--help')", arg);
            return 0;
        }
    }

    /* Check for missing arguments. */
    if (target_user_expected) {
        error("missing user name after '-u'");
        return 0;
    }
    if (pidfile_expected) {
        error("missing argument after '--pidfile'");
        return 0;
    }
    if (infile_expected) {
        error("missing argument after '--infile'");
        return 0;
    }
    if (outfile_expected) {
        error("missing argument after '--outfile'");
        return 0;
    }

    return 1;
}

/*---------------------------------------------------------------------------
 * Prints a help text on the standard output.
 */
static void print_help(void)
{
    printf("Usage: ptyshell [OPTIONS]\n");
    printf("\nCreates a pseudo-terminal, starts a shell, logs in, and redirects\n");
    printf("its input and output (by default, sends standard input to terminal\n");
    printf("and output from terminal to standard output).\n");
    printf("\nOptions:\n");
    printf("    --help              Print help and exit.\n");
    printf("    --infile FILE       Read input from file (it can be a FIFO).\n");
    printf("    --outfile FILE      Write terminal output to file.\n");
    printf("    --pidfile FILE      Write subshell PID to file, delete it when done.\n");
    printf("    -u USER             Switch to the given user (privileged operation).\n");
    printf("    -v                  Verbose mode (prints more info to stdout).\n");
    printf("\n");
}

/*---------------------------------------------------------------------------
 * The main function.
 */
int main(int argc, char ** argv)
{
    uid_t start_uid = getuid();
    uid_t target_uid = start_uid;
    int exit_code;

    if (!process_command_line(argc, argv)) {
        return 1;
    }

    if (help_requested) {
        print_help();
        return 0;
    }

    /* Find the target user (if specified). */
    if (target_user) {
        target_uid = uid_from_user_name(target_user);
        if (target_uid == (uid_t) -1) {
            error("user not found: %s");
            goto fail;
        }
    }

/*
    if (target_uid != start_uid && start_uid != 0) {
        error("root access is needed for switching between users");
        goto fail;
    }
*/

    /* Open the input and output file if desired. */
    if (infile) {
        infile_fd = open(infile, O_RDONLY|O_NOCTTY);
        if (infile_fd < 0) {
            error("could not open input file: %s", infile);
            goto fail;
        }
        input_fd = infile_fd;
    }
    if (outfile) {
        outfile_fd = open(outfile, O_WRONLY|O_CREAT|O_TRUNC|O_NOCTTY, 0660);
        if (outfile_fd < 0) {
            error("could not open output file: %s", outfile);
            goto fail;
        }
        output_fd = outfile_fd;
    }

    /* Create the subshell. */
    if (!spawn_subshell(target_uid)) {
        goto fail;
    }

    /* Start relaying input and output from the terminal
     * until the terminal closes on the other side (shell logout).
     */
    exit_code = subshell_relay_loop();

    /* Close the pseudo-terminal. */
    subshell_close();

    /* Close the input and output file if needed. */
    if (infile_fd >= 0) {
        close(infile_fd);
    }
    if (outfile_fd >= 0) {
        close(outfile_fd);
    }
    
    if ( exit_code < 0 ) exit_code = 127;

    return exit_code;

fail:

    return 1;
}
