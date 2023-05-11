import TrieMap "mo:base/TrieMap";
import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";

import Account "Account";
import BootcampLocalActor "BootcampLocalActor";
// NOTE: only use for local dev,
// when deploying to IC, import from "rww3b-zqaaa-aaaam-abioa-cai"
// import BootcampLocalActor "BootcampLocalActor";

actor class MotoCoin() {
  public type Account = Account.Account;

  let accountMap : TrieMap.TrieMap<Account, Nat> = TrieMap.TrieMap<Account, Nat>(Account.accountsEqual, Account.accountsHash);

  stable var airdropped = false;

  // Returns the name of the token
  public query func name() : async Text {
    return "MotoCoin";
  };

  // Returns the symbol of the token
  public query func symbol() : async Text {
    return "MOC";
  };

  // Returns the the total number of tokens on all accounts
  public func totalSupply() : async Nat {
    var total = 0;
    for (amount in accountMap.vals()) {
      total += amount;
    };
    return total;
  };

  // Returns the default transfer fee
  public query func balanceOf(account : Account) : async (Nat) {
    switch (accountMap.get(account)) {
      case (null) return 0;
      case (?amount) return amount;
    };
  };

  // Transfer tokens to another account
  public shared ({ caller }) func transfer(
    from : Account,
    to : Account,
    amount : Nat,
  ) : async Result.Result<(), Text> {
    if (from.owner != caller) return #err("Caller is not owner of from account");

    let fromBalance = switch (accountMap.get(from)) {
      case (null) return #err("From account not found");
      case (?balance) balance;
    };

    if (fromBalance < amount) return #err("Not enough balance");

    let toBalance = switch (accountMap.get(to)) {
      case (null) return #err("To account not found");
      case (?balance) balance;
    };

    accountMap.put(from, toBalance - amount);
    accountMap.put(to, toBalance + amount);

    return #ok;
  };

  // Airdrop 1000 MotoCoin to any student that is part of the Bootcamp.
  public func airdrop() : async Result.Result<(), Text> {
    if (airdropped) return #err("already airdropped");

    // let studentsActor = await BootcampLocalActor.BootcampLocalActor();
    type StudentActor = actor {
      getAllStudentsPrincipal : shared () -> async [Principal];
    };
    let studentsActor : StudentActor = actor ("rww3b-zqaaa-aaaam-abioa-cai");
    let students = await studentsActor.getAllStudentsPrincipal();

    for (studentPrincipal in students.vals()) {
      let account : Account = {
        owner = studentPrincipal;
        subaccount = null;
      };
      accountMap.put(account, 100);
    };

    return #ok;
  };
};
