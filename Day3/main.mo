import Text "mo:base/Text";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Result "mo:base/Result";


actor {

// Step 0 - Define a variant type called Content
    public type Content = {
    #Text: Text;
    #Image: Blob;
    #Video: Blob;
};

// Step 1- Define a new record type called Message
    public type Message = {
        vote : Int;
        content : Content;
        creator : Principal;
    };
// Step 2 - Define a variable called messageId
    var messageId : Nat = 0;

// Step 3 - Create a variable named wall, which is a HashMap
    private func _hash(id: Nat): Nat32{
    return Text.hash(Nat.toText(id));
  };
    let wall = HashMap.HashMap<Nat, Message>(0, Nat.equal, _hash);
    

// Step 4 - Implement writeMessage, which accepts a content c of type Content
    public shared ({caller}) func writeMessage(c : Content) : async Nat {
        let message : Message = {
            vote = 0;
            creator = caller;
            content = c;
        };
        wall.put(messageId, message);
        messageId += 1;
        return messageId - 1;
    };
// Step 5 - Implement getMessage, which accepts an messageId 
    public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {

        let message : ?Message = wall.get(messageId);

        switch(message) {
            case(null){
                #err("Message not found");
            };
            case(?m){
                #ok(m);
            };
        };
    };
// Step 6 - Implement updateMessage, which accepts a messageId 
     public shared ({caller}) func updateMessage(messageId : Nat, c : Content) : async Result.Result<(),Text> {
        switch (wall.get(messageId)) {
            case (null) {
                return #err("Message not found");
            };
            case (?message) {
                if (message.creator != caller) {
                    return #err("Only the creator of the messge can update it");
                };
                let newMessage = {
                    vote = message.vote;
                    creator = message.creator;
                    content = c;
                };
                wall.put(messageId, newMessage);
                return #ok();
            };
        };
     };
// Step 7 - Implement deleteMessage, which accepts a messageId
        public shared ({caller}) func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
            if ((messageId >= 0 ) and (messageId < wall.size())) {
                wall.delete(messageId);
                return #ok();
            } else {
                return #err("Message ID requested is invalid");
            };
        };
// Step 8 - Implement upVote
        public shared ({caller}) func upVote(messageId : Nat) : async Result.Result<(), Text> {
            switch(wall.get(messageId)) {
                case (null) {
                    return #err("Error trying to obtain message");
                };
                case(?message) {
                    let newMsg : Message = {content = message.content; vote= message.vote+1; creator = message.creator;};
                    ignore wall.replace(messageId, newMsg);
                    return #ok();
                };
            };
        };
// Step 9 - Implement downVote
    public shared func downVote(messageId : Nat) : async Result.Result<(), Text> {
        switch (wall.get(messageId)) {
            case (null) {
            return #err("Message not found");
            };
            case (?message) {
            let newMessage = {
                vote = message.vote - 1;
                creator = message.creator;
                content = message.content;
            };
            wall.put(messageId, newMessage);
            return #ok();
                };
            };
        };
// Step 10 - Implement the query function getAllMessages
    public query func getAllMessages() : async [Message] {
        return Iter.toArray<Message>(wall.vals());
    };
// Step 11 - Implement the query function getAllMessagesRanked
    type Order = Order.Order;
    func compareMessage(m1 : Message, m2 : Message) : Order {
        if(m1.vote == m2.vote){
            return #equal;
        };
        if(m1.vote > m2.vote){
            return #less
        };
        return #greater;
    };
    public query func getAllMessagesRanked() : async [Message] {
        let array : [Message] = Iter.toArray(wall.vals());
        return Array.sort<Message>(array, compareMessage)
    };

}