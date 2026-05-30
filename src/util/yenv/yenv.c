// yenv.c — DYLD-safe env replacement
#include <unistd.h>
#include <stdio.h>

int main(int argc, char *argv[]) {
    if (argc < 2) { fprintf(stderr, "usage: myenv program [args]\n"); return 1; }
    execvp(argv[1], argv + 1);
    perror(argv[1]);
    return 1;
}
