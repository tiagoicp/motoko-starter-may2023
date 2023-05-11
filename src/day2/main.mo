import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Text "mo:base/Text";

import Type "Types";

actor class Homework() {
  type Homework = Type.Homework;
  let homeworkBuffer = Buffer.Buffer<Homework>(0);
  var nextIndex = 0;

  // Add a new homework task
  public shared func addHomework(homework : Homework) : async Nat {
    homeworkBuffer.add(homework);
    nextIndex += 1;
    return nextIndex -1;
  };

  // Get a specific homework task by id
  public shared query func getHomework(id : Nat) : async Result.Result<Homework, Text> {
    let homework = homeworkBuffer.getOpt(id);
    switch (homework) {
      case (?homework) #ok(homework);
      case (_) #err("Id not found");
    };
  };

  // Update a homework task's title, description, and/or due date
  public shared func updateHomework(id : Nat, homework : Homework) : async Result.Result<(), Text> {
    if (id >= nextIndex) return #err("Id not found");

    homeworkBuffer.put(id, homework);
    return #ok;
  };

  // Mark a homework task as completed
  public shared func markAsCompleted(id : Nat) : async Result.Result<(), Text> {
    if (id >= nextIndex) return #err("Id not found");

    let oldHomework = homeworkBuffer.get(id);
    let updatedHomework : Homework = {
      title = oldHomework.title;
      description = oldHomework.description;
      dueDate = oldHomework.dueDate;
      completed = true;
    };
    homeworkBuffer.put(id, updatedHomework);

    return #ok;
  };

  // Delete a homework task by id
  public shared func deleteHomework(id : Nat) : async Result.Result<(), Text> {
    if (id >= nextIndex) return #err("Id not found");

    ignore homeworkBuffer.remove(id);
    return #ok;
  };

  // Get the list of all homework tasks
  public shared query func getAllHomework() : async [Homework] {
    return Buffer.toArray<Homework>(homeworkBuffer);
  };

  // Get the list of pending (not completed) homework tasks
  public shared query func getPendingHomework() : async [Homework] {
    let tempBuffer = Buffer.Buffer<Homework>(0);
    Buffer.iterate<Homework>(
      homeworkBuffer,
      func(homework) {
        if (not homework.completed) {
          tempBuffer.add(homework);
        };
      },
    );

    return Buffer.toArray<Homework>(tempBuffer);
  };

  // Search for homework tasks based on a search terms
  public shared query func searchHomework(searchTerm : Text) : async [Homework] {
    let tempBuffer = Buffer.Buffer<Homework>(0);
    Buffer.iterate<Homework>(
      homeworkBuffer,
      func(homework) {
        if (Text.contains(homework.title, #text searchTerm) or Text.contains(homework.description, #text searchTerm)) {
          tempBuffer.add(homework);
        };
      },
    );

    return Buffer.toArray<Homework>(tempBuffer);
  };
};
