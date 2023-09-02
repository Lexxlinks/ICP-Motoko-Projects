import Text "mo:base/Text";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Int "mo:base/Int";
import Timer "mo:base/Timer";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Error "mo:base/Error";
import Option "mo:base/Option";
import IC "ic";
import Types "types";


actor Verifier {
    public type StudentProfile = {
    name : Text;
    team : Text;
    graduate : Bool;
};

// Part 1:
// Step 1 - Define a variable named studentProfileStore, which is a HashMap for storing student profile.
    stable var stableMap : [(Principal, StudentProfile)] = [];
    let studentProfileStore = HashMap.fromIter<Principal, StudentProfile>(stableMap.vals(), stableMap.size(), Principal.equal, Principal.hash);

// Step 2 - Implement the addMyProfile function which accepts a profile of type StudentProfile
    public shared ({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
        let student : StudentProfile = {
            name = profile.name;
            team = profile.team;
            graduate = profile.graduate;
        };
        studentProfileStore.put(caller, student);
        return #ok();
    };
// Step 3 - Implement the seeAProfile query function, which accepts a principal p of type Principal and returns the optional corresponding student profile.
    public shared query func seeAProfile(p : Principal) : async Result.Result<StudentProfile, Text> {
        let student = studentProfileStore.get(p);
        
        switch (student) {
            case (null) {
                return #err("Student not found");
            };
            case (?student) {
                return #ok(student);
            };
        };
    };
// Step 4 - Implement the updateMyProfile function which allows a student to perform a modification
    public shared ({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
        let student : ?StudentProfile = studentProfileStore.get(caller);
        
        switch (student) {
            case (null) {
                #err("Student not found");
            };
            case (?Student) {
                let studentUpdate = {
                    name = profile.name;
                    team = profile.team;
                    graduate = profile.graduate;
                };
                studentProfileStore.put(caller, studentUpdate);
                return #ok();
            };
        };
    };
// Step 5 - Implement the deleteMyProfile function which allows a student to delete its student profile.
    public shared ({ caller }) func deleteMyprofile() : async Result.Result<(), Text> {
        let student : ?StudentProfile = studentProfileStore.get(caller);

        switch (student) {
            case (null) {
                #err("Student not found");
            };
            case (?student) {
                studentProfileStore.delete(caller);
                return #ok();
            };
        };
    };
// Part 2 - Testing of the simple calculator.
    public type TestResult = Result.Result<(), TestError>;
    public type TestError = {
        #UnexpectedValue : Text;
        #UnexpectedError : Text;
    };
// Step 1 - Implement the test function that takes a canisterId of type Principal
    public shared func test(canisterId: Principal) : async TestResult {
        let calculator = actor(Principal.toText(canisterId)) : actor {
            add: (Int) -> async (Int);
            reset: () -> async (Int);
            sub: (Nat) -> async (Int);
        };
// Verifying reset
    var ans: Int = 0;
    
    try {
        ans := await calculator.reset();
    } catch (e) {
        return #err(#UnexpectedError("The function reset is not defined"));
    };

    try {
        ans := await calculator.add(1);
    } catch (e) {
        return #err(#UnexpectedError("The function add is not defined"));
    };

    try {
        ans := await calculator.sub(1);
    } catch (e) {
        return #err(#UnexpectedError("The function sub is nod defined"));
    };
    ans := await calculator.reset();
    ans := await calculator.add(1);

    if(not (ans == 1)){
      return #err(#UnexpectedValue("The function add is not well implemented"));
    };

    ans := await calculator.reset();
    ans := await calculator.sub(1);

    if(not (ans == -1)){
      return #err(#UnexpectedValue("The function sub is not well implemented"));
    };

    ans := await calculator.reset();
    if(not (ans == 0)){
      return #err(#UnexpectedValue("The function reset is not well implemented"));
};
        return #ok();
};
// Part 3 - Implement the verifyOwnership function that takes a canisterId/Verify the controller of the calculator.
    type CanisterSEttings = IC.CanisterSettings;
    public func verifyOwnership(canisterId : Principal, p : Principal) : async Bool {
        let interface : IC.ManagementCanister = actor ("aaaaa-aa");
        try {
            let result = await interface.canister_status({canister_id = canisterId});
            let controllers = result.settings.controllers;
            return false;

        } catch (e) {
            let message = Error.message(e);
            let controllers : [Principal] = IC.parseControllersFromCanisterStatusErrorIfCallerNotController(message);
            for (i in controllers.vals()) {
                if (i == p) {
                    return true;
                };
            };
            return false;
        };
    };
// Part 4 - Implement the verifyWork function that takes a canisterId of type Principal and a principalId
    public shared func verifyWork(canisterId: Principal, p : Principal) : async Result.Result<(), Text> {
        let verify : TestResult = await test(canisterId);
        let studentDefault: Types.StudentProfile = {name="name"; team= "team"; graduate= false};
        
        switch (verify) {
            case (#err(val)){
                switch(val) {
                    case(#UnexpectedValue(text)) {return #err(text) };
                    case(#UnexpectedError(text)) {return #err(text) };

                };
            };
            case(#ok) {
                if(await verifyOwnership(canisterId, p)){
                    let student = Option.get((studentProfileStore.get(p)), studentDefault);
                    let studentUpdated = {
                        name = student.name;
                        team = student.team;
                        graduate = true;
                    };
                    studentProfileStore.put(p, studentUpdated);
                    return #ok();
                };
                return #err("The caller is not the controller of the canister");
            };
        };
    };
// Step 5 - preupgrade & postupgrade safeguard

system func preupgrade() {
    stableMap := Iter.toArray(studentProfileStore.entries());
  };

system func postupgrade() {
    stableMap := [];
  };
}