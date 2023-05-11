import Type "Types";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Hash "mo:base/Hash";
import Option "mo:base/Option";
import Order "mo:base/Order";

actor class StudentWall() {
  type Message = Type.Message;
  type Content = Type.Content;
  type Survey = Type.Survey;
  type Answer = Type.Answer;

  var wallMap = HashMap.HashMap<Nat, Message>(0, Nat.equal, Nat32.fromNat);
  var nextId = 0;

  // Add a new message to the wall
  public shared ({ caller }) func writeMessage(c : Content) : async Nat {
    let message : Message = {
      content = c;
      vote = 0;
      creator = caller;
    };

    wallMap.put(nextId, message);
    nextId += 1;

    nextId - 1;
  };

  // Get a specific message by ID
  public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {
    let message = wallMap.get(messageId);
    switch (message) {
      case (?message) #ok(message);
      case (null) #err("Message not found");
    };
  };

  // Update the content for a specific message by ID
  public shared ({ caller }) func updateMessage(messageId : Nat, c : Content) : async Result.Result<(), Text> {
    let message = wallMap.get(messageId);

    let oldMessage : Message = switch (message) {
      case (null) return #err("Message not found");
      case (?message) { message };
    };

    if (oldMessage.creator != caller) return #err("Caller is not owner of message");

    let newMessage : Message = {
      content = c;
      vote = oldMessage.vote;
      creator = oldMessage.creator;
    };
    wallMap.put(messageId, newMessage);

    #ok;
  };

  // Delete a specific message by ID
  public shared ({ caller }) func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
    let message = wallMap.get(messageId);

    let oldMessage : Message = switch (message) {
      case (null) return #err("Message not found");
      case (?message) { message };
    };

    if (oldMessage.creator != caller) return #err("Caller is not owner of message");

    wallMap.delete(messageId);
    #ok;
  };

  // Voting
  public func upVote(messageId : Nat) : async Result.Result<(), Text> {
    let message = wallMap.get(messageId);
    let oldMessage : Message = switch (message) {
      case (null) return #err("Message not found");
      case (?message) { message };
    };

    let newMessage : Message = {
      content = oldMessage.content;
      vote = oldMessage.vote + 1;
      creator = oldMessage.creator;
    };
    wallMap.put(messageId, newMessage);

    return #ok;
  };

  public func downVote(messageId : Nat) : async Result.Result<(), Text> {
    let message = wallMap.get(messageId);
    let oldMessage : Message = switch (message) {
      case (null) return #err("Message not found");
      case (?message) { message };
    };

    let newMessage : Message = {
      content = oldMessage.content;
      vote = oldMessage.vote - 1;
      creator = oldMessage.creator;
    };
    wallMap.put(messageId, newMessage);

    return #ok;
  };

  // Get all messages
  public func getAllMessages() : async [Message] {
    return Iter.toArray(wallMap.vals());
  };

  // Get all messages ordered by votes
  public func getAllMessagesRanked() : async [Message] {
    var iterator = wallMap.vals();
    let voteComparator = func(x : Message, y : Message) : Order.Order {
      if (x.vote > y.vote) { #less } else { #greater };
    };
    iterator := Iter.sort(iterator, voteComparator);

    return Iter.toArray(iterator);
  };
};
