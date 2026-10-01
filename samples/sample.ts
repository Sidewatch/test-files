// User account service with typed helpers
import { readFileSync } from "fs";

const MAX_RETRIES = 5;
const API_BASE_URL = "https://api.example.com/v1";

interface User {
  id: number;
  name: string;
  email: string;
  isActive: boolean;
}

type UserId = User["id"];

enum Role {
  Admin = "admin",
  Guest = "guest",
}

function greet(user: User): string {
  const prefix = "Hello";
  return `${prefix}, ${user.name}!`;
}

class UserRepository {
  private users: User[] = [];

  add(user: User): void {
    this.users.push(user);
  }

  findById(id: UserId): User | undefined {
    return this.users.find((u) => u.id === id);
  }
}

const repo = new UserRepository();
const alice: User = {
  id: 1,
  name: "Alice",
  email: "alice@example.com",
  isActive: true,
};

repo.add(alice);
const message = greet(alice);
console.log(message, Role.Admin, MAX_RETRIES, API_BASE_URL);

async function loadConfig(path: string): Promise<number> {
  const raw = readFileSync(path, "utf-8");
  return raw.length * 2;
}
