import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Error "mo:base/Error";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Timer "mo:base/Timer";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";

import IC "Ic";
import Type "Types";

actor class Verifier() {
  type StudentProfile = Type.StudentProfile;
  let studentsMap : HashMap.HashMap<Principal, StudentProfile> = HashMap.HashMap<Principal, StudentProfile>(0, Principal.equal, Principal.hash);

  // STEP 1 - BEGIN
  public shared ({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    let currentProfile = studentsMap.get(caller);
    if (currentProfile != null) return #err("Profile was already added");

    studentsMap.put(caller, profile);
    #ok;
  };

  public shared ({ caller }) func seeAProfile(p : Principal) : async Result.Result<StudentProfile, Text> {
    let currentProfile = studentsMap.get(caller);
    switch (currentProfile) {
      case (null) return #err("Profile not found");
      case (?profile) return #ok(profile);
    };
  };

  public shared func seeAllPrincipals() : async [Principal] {
    return Iter.toArray(studentsMap.keys());
  };

  public shared func seeAllProfiles() : async [StudentProfile] {
    return Iter.toArray(studentsMap.vals());
  };

  public shared ({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    let currentProfile = studentsMap.get(caller);
    if (currentProfile == null) return #err("Profile not found");

    studentsMap.put(caller, profile);
    #ok;
  };

  public shared ({ caller }) func deleteMyProfile() : async Result.Result<(), Text> {
    let currentProfile = studentsMap.get(caller);
    if (currentProfile == null) return #err("Profile not found");

    studentsMap.delete(caller);
    #ok;
  };
  // STEP 1 - END

  // STEP 2 - BEGIN
  type CalculatorInterface = Type.CalculatorInterface;
  public type TestResult = Type.TestResult;
  public type TestError = Type.TestError;

  public func test(canisterId : Principal) : async TestResult {
    let calculatorActor : CalculatorInterface = actor (Principal.toText(canisterId));
    ignore await calculatorActor.reset();
    var result = await calculatorActor.add(3);
    if (result != 3) return #err(#UnexpectedValue("add, did not return expected value"));

    result := await calculatorActor.sub(1);
    if (result != 2) return #err(#UnexpectedValue("sub, did not return expected value"));

    ignore await calculatorActor.reset();
    result := await calculatorActor.add(1);
    if (result != 1) return #err(#UnexpectedValue("reset, did not reset to 0 as expected"));

    return #ok;
  };
  // STEP - 2 END

  // STEP 3 - BEGIN
  // NOTE: Not possible to develop locally,
  // as actor "aaaa-aa" (aka the IC itself, exposed as an interface) does not exist locally
  public func verifyOwnership(canisterId : Principal, p : Principal) : async Bool {
    var controllers : [Principal] = [];
    let managementActor : IC.ManagementCanisterInterface = actor ("aaaaa-aa");
    try {
      let status = await managementActor.canister_status({
        canister_id = canisterId;
      });
      controllers := status.settings.controllers;
    } catch (e) {
      controllers := parseControllersFromCanisterStatusErrorIfCallerNotController(Error.message(e));
    };

    var found = false;
    for (principal in controllers.vals()) {
      if (principal == p) found := true;
    };
    return found;
  };
  // STEP 3 - END

  // STEP 4 - BEGIN
  public shared ({ caller }) func verifyWork(canisterId : Principal, p : Principal) : async Result.Result<(), Text> {
    let studentProfile = switch (studentsMap.get(p)) {
      case (null) return #err("Student not Found, please register first.");
      case (?studentProfile) studentProfile;
    };

    if (studentProfile.graduate) return #err("Already graduated");

    let owner = await verifyOwnership(canisterId, p);
    if (not owner) return #err("Caller is not controller of canister");

    let result = await test(canisterId);
    if (result != #ok) return #err("Canister did not pass test");

    let newProfile : StudentProfile = {
      name = studentProfile.name;
      team = studentProfile.team;
      graduate = true;
    };
    studentsMap.put(p, newProfile);

    return #ok;
  };
  // STEP 4 - END

  // private

  func parseControllersFromCanisterStatusErrorIfCallerNotController(errorMessage : Text) : [Principal] {
    let lines = Iter.toArray(Text.split(errorMessage, #text("\n")));
    let words = Iter.toArray(Text.split(lines[1], #text(" ")));
    var i = 2;
    let controllers = Buffer.Buffer<Principal>(0);
    while (i < words.size()) {
      controllers.add(Principal.fromText(words[i]));
      i += 1;
    };
    Buffer.toArray<Principal>(controllers);
  };
};
