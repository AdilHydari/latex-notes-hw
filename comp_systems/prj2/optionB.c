// Solution for Project‑2, Problem 1 – OPTION B
// Author: Adil
// Build: gcc -Wall -Wextra -pedantic -std=c11 optionB.c -o option_b_signals
// Run:    ./option_b_signals
// -----------------------------------------------------------
//   -DPART3
// -----------------------------------------------------------

#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <string.h>
#include <sys/wait.h>
#include <errno.h>

#define CHILD_COUNT 4

static const int ALL_SIGS[8] = {
    SIGINT,  SIGABRT, SIGILL, SIGCHLD,
    SIGSEGV, SIGFPE,  SIGHUP, SIGTSTP
};

static const char *sig2str(int signo)
{
    switch (signo) {
    case SIGINT:  return "SIGINT";
    case SIGABRT: return "SIGABRT";
    case SIGILL:  return "SIGILL";
    case SIGCHLD: return "SIGCHLD";
    case SIGSEGV: return "SIGSEGV";
    case SIGFPE:  return "SIGFPE";
    case SIGHUP:  return "SIGHUP";
    case SIGTSTP: return "SIGTSTP";
    default:      return "UNKNOWN";
    }
}

// logical child index
static int g_child_idx = -1;

static void generic_handler(int signo, siginfo_t *info, void *ucontext)
{
    (void)ucontext;

    pid_t self = getpid();
    pid_t sender = (info && info->si_pid) ? info->si_pid : -1;

    // signal info
    fprintf(stderr,
            "[%d] child_idx=%d received %s (%d) from sender=%d\n",
            self, g_child_idx, sig2str(signo), signo, sender);

    // blocking - part 1
    // block SIGTSTP to avoid recursion
    sigset_t block_set, old_set;
    sigemptyset(&block_set);
    sigaddset(&block_set, SIGTSTP);
    sigprocmask(SIG_BLOCK, &block_set, &old_set);
    sigprocmask(SIG_SETMASK, &old_set, NULL);

    if (signo == SIGFPE) {
        // pretend we fixed the error and just return
        return;
    }
    if (signo == SIGSEGV) {
        // suicide for an unrecoverable signal
        _exit(128 + signo);
    }
}

static void install_child_handlers(int child_index)
{
    // Each child catches four signals and blocks two
    int caught[4];
    for (int i = 0; i < 4; ++i)
        caught[i] = ALL_SIGS[(child_index * 4 + i) % 8];

    int permanently_blocked[2] = { caught[0], caught[1] };   // first two

    sigset_t perm_block_set;
    sigemptyset(&perm_block_set);
    sigaddset(&perm_block_set, permanently_blocked[0]);
    sigaddset(&perm_block_set, permanently_blocked[1]);
    if (sigprocmask(SIG_BLOCK, &perm_block_set, NULL) == -1) {
        perror("sigprocmask (child perm block)");
        exit(EXIT_FAILURE);
    }

    // install handlers
    struct sigaction sa = {0};
    sa.sa_sigaction = generic_handler;
    sa.sa_flags     = SA_SIGINFO | SA_RESTART;

    sigemptyset(&sa.sa_mask);
    // block the other two signals
    sigaddset(&sa.sa_mask, caught[2]);
    sigaddset(&sa.sa_mask, caught[3]);

    for (int i = 0; i < 4; ++i) {
        if (sigaction(caught[i], &sa, NULL) == -1) {
            fprintf(stderr, "sigaction failed for %s (%d): %s\n",
                    sig2str(caught[i]), caught[i], strerror(errno));
            exit(EXIT_FAILURE);
        }
    }

    // ignore rest
    struct sigaction ign = {0};
    ign.sa_handler = SIG_IGN;
    for (int i = 0; i < 8; ++i) {
        int sig = ALL_SIGS[i];
        int is_caught = 0;
        for (int j = 0; j < 4; ++j)
            if (sig == caught[j]) is_caught = 1;
        if (!is_caught) sigaction(sig, &ign, NULL);
    }

#ifdef PART3
    // masking rules for Part 3
    // children 0‑1 block
    sigset_t extra;
    sigemptyset(&extra);
    if (child_index < 2) {
        sigaddset(&extra, SIGINT);
        sigaddset(&extra, SIGQUIT);
        sigaddset(&extra, SIGTSTP);
    } else {
        for (size_t i = 0; i < sizeof ALL_SIGS / sizeof ALL_SIGS[0]; ++i)
            if (ALL_SIGS[i] != SIGINT && ALL_SIGS[i] != SIGQUIT && ALL_SIGS[i] != SIGTSTP)
                sigaddset(&extra, ALL_SIGS[i]);
    }
    sigprocmask(SIG_BLOCK, &extra, NULL);
#endif
}

static void child_work(int idx)
{
    g_child_idx = idx;
    install_child_handlers(idx);

    pid_t self = getpid();
    unsigned long long sum = 0ULL;
    int limit = 15;

    for (int i = 0; i <= limit; ++i) {
        sum += i;
        sleep(1); // give time 
    }

    printf("Child[%d] pid=%d sum(0..%d)=%llu done\n", idx, self, limit, sum);
    fflush(stdout);

#ifdef PART3
    sigset_t pending;
    if (sigpending(&pending) == 0) {
        printf("Pending signals for child[%d] (pid=%d): ", idx, self);
        for (int i = 0; i < 8; ++i) {
            if (sigismember(&pending, ALL_SIGS[i]))
                printf("%s ", sig2str(ALL_SIGS[i]));
        }
        printf("\n");
    }
#endif

    _exit(EXIT_SUCCESS);
}

static void ignore_all_target_sigs(void)
{
    struct sigaction ign = {0};
    ign.sa_handler = SIG_IGN;
    for (size_t i = 0; i < sizeof ALL_SIGS / sizeof ALL_SIGS[0]; ++i)
        sigaction(ALL_SIGS[i], &ign, NULL);
}

int main(void)
{
    printf("Parent pid=%d starting (OPTION B – Part 1)\n", getpid());

    // ignore target signals till finish
    ignore_all_target_sigs();

    pid_t children[CHILD_COUNT] = {0};
    for (int i = 0; i < CHILD_COUNT; ++i) {
        pid_t pid = fork();
        if (pid < 0) {
            perror("fork");
            exit(EXIT_FAILURE);
        }
        if (pid == 0) {
            child_work(i);
        }
        children[i] = pid;
    }

    int status;
    while (wait(&status) > 0) {
        if (WIFEXITED(status))
            printf("Parent noticed child exit code=%d\n", WEXITSTATUS(status));
        else if (WIFSIGNALED(status))
            printf("Parent noticed child terminated by %s\n",
                   sig2str(WTERMSIG(status)));
    }

    // restore default disposition
    struct sigaction defa = {0};
    defa.sa_handler = SIG_DFL;
    for (size_t i = 0; i < sizeof ALL_SIGS / sizeof ALL_SIGS[0]; ++i)
        sigaction(ALL_SIGS[i], &defa, NULL);

    printf("Parent (pid=%d) sleeping 10s – now susceptible to default actions…\n", getpid());
    fflush(stdout);
    sleep(10);

#ifdef PART3
    // show pending queue
    sigset_t pending;
    if (sigpending(&pending) == 0) {
        printf("Pending signals for parent: ");
        for (int i = 0; i < 8; ++i)
            if (sigismember(&pending, ALL_SIGS[i]))
                printf("%s ", sig2str(ALL_SIGS[i]));
        printf("\n");
    }
#endif

    printf("Parent done – exiting cleanly.\n");
    return 0;
}
