import UpdateDeprecations.Main

open UpdateDeprecations

run_cmd
  let fn := "True.hish"
  let s1 := ".hish and more text"
  let s2 := "hish and more text"
  let _s3 := "ish and more text"
  if findNamespaceMatch fn s1 != some ".hish" then Lean.logInfo "error"
  if findNamespaceMatch fn s2 != some "hish"  then Lean.logInfo "error"
  --if findNamespaceMatch fn _s3 != none         then Lean.logInfo "error"

/-- info: true -/
#guard_msgs in
#eval
  let str := "  refine' ⟨_, _⟩"
  replaceCheck str "_" "?_" 11 == "  refine' ⟨?_, _⟩"

/-- info: true -/
#guard_msgs in
#eval
  let str := "  refine' ⟨_, _⟩"
  replaceCheck str "" "?" 11 == "  refine' ⟨?_, _⟩"

/-- info: true -/
#guard_msgs in
#eval
  let str := "  refine' ⟨_, _⟩"
  replaceCheck str "refine'" "refine" 2 == "  refine ⟨_, _⟩"

/-- info: true -/
#guard_msgs in
#eval
  let str := "  refine' ⟨_, _⟩"
  replaceCheck str "'" "" 8 == "  refine ⟨_, _⟩"

open Lean Elab Command
run_cmd liftTermElabM do
  let fil ← `(build| ././././$(mkIdent `MyProject)/$(mkIdent `new.lean))
  guard <| toFile fil == "MyProject/new.lean"
