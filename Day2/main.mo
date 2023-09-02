import Buffer "mo:base/Buffer";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Nat "mo:base/Nat";

actor {
    type Time = Time.Time;
// Step 1 - Define a record type Homework that reps a HW task
    type Homework = {
    title : Text;
    description : Text;
    dueDate : Time.Time;
    completed : Bool;
};

// Step 2 - Define a variable called homeworkDiary to store homework tasks
    let homeworkDiary = Buffer.Buffer<Homework>(0);

// Step 3 - Implement addHomework, which accepts a homework of type Homework
    public shared func addHomework(homework: Homework) : async Nat {
        let index = homeworkDiary.size();
        homeworkDiary.add(homework);
        return index;
    };

// Step 4 - Implement getHomework, which accepts a homeworkId of type Nat...
    public shared func getHomework(homeworkId: Nat) : async Result.Result<Homework, Text> {
        switch(homeworkDiary.getOpt(homeworkId)){
          case(null){
            return #err("Homework with id : " # Nat.toText(homeworkId) # "has not been found");
    };
    case(? homework){   
        return #ok(homework);
             };
        };
    };     
            
// Step 5 - Implement updateHomework, which accepts a homeworkId of type Nat...
    public shared func updateHomework(homeworkId: Nat, homework: Homework) : async Result.Result<(), Text> {
        switch(homeworkDiary.getOpt(homeworkId)){
            case(null){
      return #err("Homework with id : " # Nat.toText(homeworkId) # "has not been found");
        };
        case(_){
      homeworkDiary.put(homeworkId, homework);
      return #ok();
        };
      };
    };

// Step 6 - Implement markAsComplete, which accepts a homeworkId of type Nat...
    public shared func markAsCompleted(homeworkId: Nat) : async Result.Result<(), Text> {
        switch(homeworkDiary.getOpt(homeworkId)){
            case(null){ 
              return #err("Homework with id : " # Nat.toText(homeworkId) # "has not been found");
        }; 
        case(?homework){
            let updatedHomework = {
                title = homework.title;
                description = homework.description;
                dueDate = homework.dueDate;
                completed = true;
            };
            homeworkDiary.put(homeworkId, updatedHomework);
            return #ok(());
            };
        };
    };

// Step 7 - Implement deleteHomework, which accepts a homeworkId of type Nat...
    public shared func deleteHomework(homeworkId: Nat) : async Result.Result<(), Text> {
        switch(homeworkDiary.getOpt(homeworkId)){
            case(null){ 
              return #err("Homework with id : " # Nat.toText(homeworkId) # " has not been found");
        };
        case(?homework){
            ignore homeworkDiary.remove(homeworkId);
            return #ok();    
        };
    };
};

// Step 8 - Implement getAllHomework, which returns the list of all homework tasks...
    public shared query func getAllHomework() : async [Homework] {
        return Buffer.toArray(homeworkDiary);
    };

// Step 9 - Implement getPendingHomework which returns the list of all uncompleted homework...
    public shared query func getPendingHomework() : async [Homework] {
        let pendingHomework = Buffer.clone(homeworkDiary);
    pendingHomework.filterEntries(func(_, homework) = (homework.completed == false));
        return Buffer.toArray(pendingHomework);
    };

// Step 10 - Implement a searchHomework query function that accepts a searchTerm of type Text...
    public shared query func searchHomework(searchTerm: Text) : async [Homework] {
        let searchHW = Buffer.clone(homeworkDiary);
        searchHW.filterEntries(func(_, x) = (Text.contains(x.title, #text searchTerm) or Text.contains(x.description, #text searchTerm)));
        return Buffer.toArray(searchHW);
    };
};