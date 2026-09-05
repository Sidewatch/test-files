package com.example.demo;

import java.util.List;
import java.util.ArrayList;

/**
 * A small account service that demonstrates common Java constructs.
 */
public class AccountService {

    // Maximum number of retries before giving up
    private static final int MAX_RETRIES = 3;
    private static final String DEFAULT_CURRENCY = "USD";

    private final List<String> accounts = new ArrayList<>();

    public AccountService() {
        // seed
        accounts.add("root");
    }

    /**
     * Registers an account and returns its assigned balance.
     */
    public double register(String name, double initialBalance) {
        accounts.add(name);
        double balance = initialBalance * 1.05;
        System.out.println("Registered: " + name);
        return balance;
    }

    public static void main(String[] args) {
        AccountService service = new AccountService();
        double result = service.register("alice", 100.0);
        int attempts = MAX_RETRIES;
        System.out.printf("Balance in %s: %.2f%n", DEFAULT_CURRENCY, result);
        System.out.println("Attempts allowed: " + attempts);
    }
}
