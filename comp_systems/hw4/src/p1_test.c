#include <stdio.h> //all includes here
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

// FLAGS and CONDITIONALS will be defined based on command-line args:
// argv[1] = exit value for child process
// argv[2] = sleep time for child process
// argv[3] = FLAG case (1, 2, or 3)
// argv[4] = CONDITIONAL case (1 or 2)

int main(int argc, char *argv[]) {
  int i, status, parent_PID;
  pid_t pid, cpid, w;
  int flag_case, cond_case;
  int flags;
  
  // Check that we have enough arguments
  if (argc < 5) {
    fprintf(stderr, "Usage: %s <exit_value> <sleep_time> <flag_case> <cond_case>\n", argv[0]);
    fprintf(stderr, "  flag_case: 1=WUNTRACED|WCONTINUED, 2=WUNTRACED|WCONTINUED|WNOHANG, 3=WNOHANG\n");
    fprintf(stderr, "  cond_case: 1=(!WIFEXITED && !WIFSIGNALED), 2=(!w || (!WIFEXITED && !WIFSIGNALED))\n");
    return 1;
  }
  
  // Parse the flag and conditional cases
  flag_case = atoi(argv[3]);
  cond_case = atoi(argv[4]);
  
  // Set FLAGS based on flag_case
  switch (flag_case) {
    case 1:
      flags = WUNTRACED | WCONTINUED;
      fprintf(stderr, "Using FLAGS = WUNTRACED | WCONTINUED\n");
      break;
    case 2:
      flags = WUNTRACED | WCONTINUED | WNOHANG;
      fprintf(stderr, "Using FLAGS = WUNTRACED | WCONTINUED | WNOHANG\n");
      break;
    case 3:
      flags = WNOHANG;
      fprintf(stderr, "Using FLAGS = WNOHANG\n");
      break;
    default:
      fprintf(stderr, "Invalid flag_case: %d\n", flag_case);
      return 1;
  }
  
  cpid = fork();
  if (cpid < 0) return 1;
  else if (cpid == 0) {
    sleep(atoi(argv[2])); // Child process sleeps
    exit(atoi(argv[1]));  // Then exits with provided value
  }
  else {
    fprintf(stderr, "Parent process started, child PID: %d\n", cpid);
    fprintf(stderr, "Waiting with flags=%d, cond_case=%d\n", flags, cond_case);
    
    do {
      w = waitpid(cpid, &status, flags);
      fprintf(stderr, "parent=%d, child=%d, status=%d, w=%d\n", getpid(), cpid, status, w);
      
      if (w == -1) {
        fprintf(stderr, "Error in waitpid\n");
        exit(0);
      }
      
      if (w) {
        if (WIFEXITED(status)) 
          fprintf(stderr, "exited naturally, status = %d\n", WEXITSTATUS(status));
        else if (WIFSIGNALED(status)) 
          fprintf(stderr, "killed by signal: %d\n", WTERMSIG(status));
        else if (WIFSTOPPED(status)) 
          fprintf(stderr, "stopped by signal %d\n", WSTOPSIG(status));
        else if (WIFCONTINUED(status))
          fprintf(stderr, "continued\n");
      } else {
        fprintf(stderr, "w=0, WNOHANG returned because child still running\n");
        // Small delay to prevent tight loop with WNOHANG
        usleep(100000); // 100ms
      }
      
      // Check the loop condition based on cond_case
      if (cond_case == 1) {
        fprintf(stderr, "Checking condition C1: ((!WIFEXITED(status)) && (!WIFSIGNALED(status)))\n");
        fprintf(stderr, "WIFEXITED=%d, WIFSIGNALED=%d\n", WIFEXITED(status), WIFSIGNALED(status));
      } else {
        fprintf(stderr, "Checking condition C2: ((!w)||((!WIFEXITED(status)) && (!WIFSIGNALED(status))))\n");
        fprintf(stderr, "w=%d, WIFEXITED=%d, WIFSIGNALED=%d\n", w, WIFEXITED(status), WIFSIGNALED(status));
      }
    } while (cond_case == 1 ? 
            ((!WIFEXITED(status)) && (!WIFSIGNALED(status))) : 
            ((!w) || ((!WIFEXITED(status)) && (!WIFSIGNALED(status)))));
    
    fprintf(stderr, "Parent process exiting\n");
    exit(1);
  }
}
