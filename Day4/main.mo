import Text "mo:base/Text";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Trie "mo:base/Trie";
import Debug "mo:base/Debug";
import TrieMap "mo:base/TrieMap";
import account "account";
import Option "mo:base/Option";

actor class MotoCoin() {

// Step 1 - Define a variable called ledger, which is a TrieMap
    private func accountsEqual(lhs : account.Account, rhs : account.Account) : Bool {
    Principal.equal(lhs.owner, rhs.owner)
  };

  private func accountsHash(lhs : account.Account) : Nat32 {
    Principal.hash(lhs.owner)
  };
    let ledger = TrieMap.TrieMap<account.Account, Nat>(accountsEqual, accountsHash);
      
      


// Step 2 - Implement name which returns the name of the token as a Text
    public shared query func name() : async Text {
        return "MotoCoin";
    };
// Step 3 - Implement symbol which Returns the symbol of the token
    public shared query func symbol() : async Text {
        return "MOC";
};
// Step 4 - Implement totalSupply which returns the total number of MOC token in circulation.
  public shared query func totalSupply() : async Nat {
    var supply = 0;
    for ((key, value) in ledger.entries()){
        supply += value;
    };
    return supply;
};
// Step 5 - Implement balanceOf which takes an account and returns the balance of this account
    public shared query func balanceOf(account : account.Account) : async Nat {
        let balanceOpt = ledger.get(account);
        switch(balanceOpt) {
        case (null) {
            return 0;
        };
        case (?balance) {
            return balance;
        };
    };
};
//Step 6 - Implement transfer that accepts three parameters
   public shared({ caller }) func transfer(from : account.Account, to : account.Account, amount : Nat) : async Result.Result<(), Text> {
    // Retrieve the balance of the sender's account
    let fromBalanceOpt = ledger.get(from);
    switch(fromBalanceOpt) {
        case (?balance) {
            // Check if the sender has enough balance
            if(balance < amount) {
                // If not, return an error message wrapped in an Err result
                return #err("Insufficient balance to transfer");
            } else {
                // Otherwise, deduct the amount from the sender's account
                ledger.put(from, balance - amount);
            };
        };
        case (null) {
            // If the sender's account does not exist in the ledger, return an error message wrapped in an Err result
            return #err("Sender account does not exist");
        };
    };

    // Retrieve the balance of the recipient's account
    let toBalanceOpt = ledger.get(to);
    switch(toBalanceOpt) {
        case (?balance) {
            // If the recipient's account exists in the ledger, add the transferred amount to its balance
            ledger.put(to, balance + amount);
        };
        case (null) {
            // If the recipient's account does not exist in the ledger, create it and set its balance to the transferred amount
            ledger.put(to, amount);
        };
    };

    // Return Ok result to indicate successful transfer
    return #ok();
};
// Step 7 - Implement airdrop which adds 100 MotoCoin to the main account of all students
   public func airdrop() : async Result.Result<(), Text> {

    let motokoCanister = actor("rww3b-zqaaa-aaaam-abioa-cai") : actor {
      getAllStudentsPrincipal : shared () -> async [Principal];
    };
    try {
        let studentList : [Principal] = await motokoCanister.getAllStudentsPrincipal();
        
        for (index in studentList.vals()) {
            let student : account.Account = { owner = index; };
            ledger.put(student, Option.get(ledger.get(student), 0) + 100);
        };
        #ok;
    } catch (err) {
        #err("error in the principals");
    };
   };
 
 }
