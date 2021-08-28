#include <dirent.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <sys/types.h>

int main() {
	int status;

	printf("%d\n", WNOHANG);
	printf("%d\n", WUNTRACED);
	printf("%d\n", WCONTINUED);
	while (true) {
		wpid = waitpid(0, &status, WUNTRACED);
		if (WIFEXITED(status) || WIFSIGNALED(status)) do break;
	}
}

