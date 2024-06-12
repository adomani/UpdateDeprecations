import UpdateDeprecations.Basic

open Lean UpdateDeprecations

/-- info: ([a, b, c], ([], [])) -/
#guard_msgs in
run_cmd
  let left := "a.b.c".splitOn "."
  let right := "a.b.c".splitOn "."
  logInfo m!"{List.getCommon left right}"

/-- info: ([a, b], ([c], [b', d])) -/
#guard_msgs in
run_cmd
  let left := "a.b.c".splitOn "."
  let right := "a.b.b'.d".splitOn "."
  logInfo m!"{List.getCommon left right}"

/-- info: some ((A'.B' h).C) -/
#guard_msgs in
run_cmd
  let recombined := recombineNamespace "A.B.C" "h.C" "A'.B'"
  logInfo m!"{recombined}"

/--
info: some (ok1)
---
info: some (True.ok2)
---
info: some (True.intro.ok2)
-/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "hello1" "hello1" "ok1"}"
  logInfo m!"{recombineNamespace "True.hello2" "hello2" "True.ok2"}"
  logInfo m!"{recombineNamespace "True.hello2" "True.intro.hello2" "True.ok2"}"

/- `s.splitOn t` is never `[]`
#eval
  let s := ["", "a", "b"]
  let t := ["", "a", "b"]
  Id.run do
  let mut tot := #[]
  for a in s do
    for b in t do
      tot := tot.push <| a.splitOn b
  return tot.all (· ≠ [])
-/

/-- info: some ((by exact True.intro : ).hello2) -/
#guard_msgs in
run_cmd Lean.Elab.Command.liftTermElabM do
  let s := "(by exact True.intro : ).hello2"
  let fullName := "True.hello2"
  logInfo m!"{findFirstEnd fullName s}"

/-- info: some ((by exact True.intro : ).hello2) -/
#guard_msgs in
run_cmd Lean.Elab.Command.liftTermElabM do
  let s := "(by exact True.intro : ).hello2 and then .hello2. more wi"
  let fullName := "True.hello2"
  logInfo m!"{findFirstEnd fullName s}"

set_option linter.deprecated false in
/--
info: true
---
info: true
-/
#guard_msgs in
run_cmd
  let msgs1 := (← get).messages.msgs
  let msgs := (← get).messages.unreported
  let msgs1WithArray := (← get).messages.msgs.toArray
  let msgsWithArray := (← get).messages.unreported.toArray
  logInfo m!"{(← msgs1.mapM (·.toString)).toArray == (← msgs.mapM (·.toString)).toArray}"
  logInfo m!"{(← msgs1WithArray.mapM (·.toString)) == (← msgsWithArray.mapM (·.toString))}"

/--
info: some ((← get).messages.unreported)
---
info: some ((← get).messages.unreported.toArray)
-/
#guard_msgs in
run_cmd
  let msgs := "Lean.MessageLog.msgs"
  let unrep := "Lean.MessageLog.unreported"
  let recombined := recombineNamespace msgs "(← get).messages.msgs" unrep
  logInfo m!"{recombined}"
  let msgsToArray := "(← get).messages.msgs.toArray"
  let recombined := recombineNamespace msgs msgsToArray unrep
  logInfo m!"{recombined}"

/-- info: some (hp.More) -/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "Nat.Prime.ne_two" "hp.ne_two" "Nat.Prime.More"}"

/-- info: some ((Nat.newPrime.More hp).ne_two.symm) -/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "Nat.Prime.ne_two" "hp.ne_two.symm" "Nat.newPrime.More"}"

/-- info: some ((Nat.newPrime.More hp).ne_two) -/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "Nat.Prime.ne_two" "hp.ne_two" "Nat.newPrime.More"}"

/-- info: ([a, b, c], ([], ([], []))) -/
#guard_msgs in
run_cmd
  let fullName := "a.b.c"
  let dotNot := "a.b.c"
  logInfo m!"{splitWithNamespace fullName dotNot}"

/-- info: ([], ([a, b, c], ([], [a, b, c']))) -/
#guard_msgs in
run_cmd
  let fullName := "a.b.c"
  let dotNot := "a.b.c'"
  logInfo m!"{splitWithNamespace fullName dotNot}"

/-- info: ([a, b, c], ([], ([], [d]))) -/
#guard_msgs in
run_cmd
  let fullName := "a.b.c"
  let dotNot := "a.b.c.d"
  logInfo m!"{splitWithNamespace fullName dotNot}"

/-- info: ([b, c], ([a], ([a'], [d]))) -/
#guard_msgs in
run_cmd
  let fullName := "a.b.c"
  let dotNot := "a'.b.c.d"
  logInfo m!"{splitWithNamespace fullName dotNot}"

/-- info: ([b, c], ([a], ([a'], [d, e]))) -/
#guard_msgs in
run_cmd
  let fullName := "a.b.c"
  let dotNot := "a'.b.c.d.e"
  logInfo m!"{splitWithNamespace fullName dotNot}"

/-- info: ([ne_two], ([Nat, Prime], ([hp], [symm]))) -/
#guard_msgs in
run_cmd
  let fullName := "Nat.Prime.ne_two"
  let dotNot := "hp.ne_two.symm"
  logInfo m!"{splitWithNamespace fullName dotNot}"

/-- info: some (myNat.find) -/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "Nat.find" "Nat.find" "myNat.find"}"

/-- info: some (myNat.find) -/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "Nat.find" "find" "myNat.find"}"

/-- info: some (nat.findNew) -/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "Nat.find" "find" "nat.findNew"}"

/-- info: some (Nat.Int.findNew) -/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "Nat.Int.find" "Int.find" "Nat.Int.findNew"}"

/-- info: some (x.findNew) -/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "Nat.Int.find" "x.find" "Nat.Int.findNew"}"

/-- info: none -/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "Nat.Int.find" "x.ind" "Nat.Int.findNew"}"

/-- info: ([a, b, c], ([], [])) -/
#guard_msgs in
run_cmd
  let left := "a.b.c".splitOn "."
  let right := "a.b.c".splitOn "."
  logInfo m!"{List.getCommon left right}"

/-- info: ([a, b], ([c], [b', d])) -/
#guard_msgs in
run_cmd
  let left := "a.b.c".splitOn "."
  let right := "a.b.b'.d".splitOn "."
  logInfo m!"{List.getCommon left right}"

/-- info: some ((A'.B' h).C) -/
#guard_msgs in
run_cmd
  let recombined := recombineNamespace "A.B.C" "h.C" "A'.B'"
  logInfo m!"{recombined}"

/--
info: some (ok1)
---
info: some (True.ok2)
---
info: some (True.intro.ok2)
-/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "hello1" "hello1" "ok1"}"
  logInfo m!"{recombineNamespace "True.hello2" "hello2" "True.ok2"}"
  logInfo m!"{recombineNamespace "True.hello2" "True.intro.hello2" "True.ok2"}"

/- `s.splitOn t` is never `[]`
#eval
  let s := ["", "a", "b"]
  let t := ["", "a", "b"]
  Id.run do
  let mut tot := #[]
  for a in s do
    for b in t do
      tot := tot.push <| a.splitOn b
  return tot.all (· ≠ [])
-/

/-- info: some ((by exact True.intro : ).hello2) -/
#guard_msgs in
run_cmd Lean.Elab.Command.liftTermElabM do
  let s := "(by exact True.intro : ).hello2"
  let fullName := "True.hello2"
  logInfo m!"{findFirstEnd fullName s}"

/-- info: some ((by exact True.intro : ).hello2) -/
#guard_msgs in
run_cmd Lean.Elab.Command.liftTermElabM do
  let s := "(by exact True.intro : ).hello2 and then .hello2. more wi"
  let fullName := "True.hello2"
  logInfo m!"{findFirstEnd fullName s}"

/-- info: some (some string(by exact True.intro : ).ok2 and then .hello2. more wi) -/
#guard_msgs in
run_cmd Lean.Elab.Command.liftTermElabM do
  let beg := "some string"
  let s := beg ++ "(by exact True.intro : ).hello2 and then .hello2. more wi"
  let fullName := "True.hello2"
  let newName := "True.ok2"
  logInfo m!"{ReplData.newLine ⟨fullName, newName, 0, beg.length⟩ #[s]}"

set_option linter.deprecated false in
/--
info: true
---
info: true
-/
#guard_msgs in
run_cmd
  let msgs1 := (← get).messages.msgs
  let msgs := (← get).messages.unreported
  let msgs1WithArray := (← get).messages.msgs.toArray
  let msgsWithArray := (← get).messages.unreported.toArray
  logInfo m!"{(← msgs1.mapM (·.toString)).toArray == (← msgs.mapM (·.toString)).toArray}"
  logInfo m!"{(← msgs1WithArray.mapM (·.toString)) == (← msgsWithArray.mapM (·.toString))}"

/--
info: some ((← get).messages.unreported)
---
info: some ((← get).messages.unreported.toArray)
-/
#guard_msgs in
run_cmd
  let msgs := "Lean.MessageLog.msgs"
  let unrep := "Lean.MessageLog.unreported"
  let recombined := recombineNamespace msgs "(← get).messages.msgs" unrep
  logInfo m!"{recombined}"
  let msgsToArray := "(← get).messages.msgs.toArray"
  let recombined := recombineNamespace msgs msgsToArray unrep
  logInfo m!"{recombined}"

/-- info: some (hp.More) -/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "Nat.Prime.ne_two" "hp.ne_two" "Nat.Prime.More"}"

/-- info: some ((Nat.newPrime.More hp).ne_two.symm) -/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "Nat.Prime.ne_two" "hp.ne_two.symm" "Nat.newPrime.More"}"

/-- info: some ((Nat.newPrime.More hp).ne_two) -/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "Nat.Prime.ne_two" "hp.ne_two" "Nat.newPrime.More"}"

/-- info: ([a, b, c], ([], ([], []))) -/
#guard_msgs in
run_cmd
  let fullName := "a.b.c"
  let dotNot := "a.b.c"
  logInfo m!"{splitWithNamespace fullName dotNot}"

/-- info: ([], ([a, b, c], ([], [a, b, c']))) -/
#guard_msgs in
run_cmd
  let fullName := "a.b.c"
  let dotNot := "a.b.c'"
  logInfo m!"{splitWithNamespace fullName dotNot}"

/-- info: ([a, b, c], ([], ([], [d]))) -/
#guard_msgs in
run_cmd
  let fullName := "a.b.c"
  let dotNot := "a.b.c.d"
  logInfo m!"{splitWithNamespace fullName dotNot}"

/-- info: ([b, c], ([a], ([a'], [d]))) -/
#guard_msgs in
run_cmd
  let fullName := "a.b.c"
  let dotNot := "a'.b.c.d"
  logInfo m!"{splitWithNamespace fullName dotNot}"

/-- info: ([b, c], ([a], ([a'], [d, e]))) -/
#guard_msgs in
run_cmd
  let fullName := "a.b.c"
  let dotNot := "a'.b.c.d.e"
  logInfo m!"{splitWithNamespace fullName dotNot}"

/-- info: ([ne_two], ([Nat, Prime], ([hp], [symm]))) -/
#guard_msgs in
run_cmd
  let fullName := "Nat.Prime.ne_two"
  let dotNot := "hp.ne_two.symm"
  logInfo m!"{splitWithNamespace fullName dotNot}"

/-- info: some (myNat.find) -/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "Nat.find" "Nat.find" "myNat.find"}"

/-- info: some (myNat.find) -/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "Nat.find" "find" "myNat.find"}"

/-- info: some (nat.findNew) -/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "Nat.find" "find" "nat.findNew"}"

/-- info: some (Nat.Int.findNew) -/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "Nat.Int.find" "Int.find" "Nat.Int.findNew"}"

/-- info: some (x.findNew) -/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "Nat.Int.find" "x.find" "Nat.Int.findNew"}"

/-- info: none -/
#guard_msgs in
run_cmd
  logInfo m!"{recombineNamespace "Nat.Int.find" "x.ind" "Nat.Int.findNew"}"

/-- info: MyProject/new.lean -/
#guard_msgs in
run_cmd
  let fil ← `(build| ././././$(mkIdent `MyProject)/$(mkIdent `new.lean))
  logInfo m!"{toFile fil}"
