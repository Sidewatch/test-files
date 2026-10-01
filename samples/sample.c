/* sample.c - exercises common C constructs for syntax highlighting */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_BUFFER 256
#define GREETING "Hello, world"

// A simple struct type definition
typedef struct {
    int id;
    char name[MAX_BUFFER];
    double balance;
} Account;

enum Status { STATUS_OK = 0, STATUS_FAIL = 1 };

// Function definition
static double compute_interest(double principal, double rate) {
    double result = principal * (1.0 + rate);
    return result;
}

int main(int argc, char **argv) {
    Account acct;
    acct.id = 42;
    strncpy(acct.name, GREETING, MAX_BUFFER - 1);
    acct.balance = 1000.50;

    // Function call
    double updated = compute_interest(acct.balance, 0.05);

    printf("Account %d (%s): %.2f\n", acct.id, acct.name, updated);

    enum Status status = STATUS_OK;
    if (status != STATUS_OK) {
        fprintf(stderr, "failure\n");
        return EXIT_FAILURE;
    }

    return 0;
}
