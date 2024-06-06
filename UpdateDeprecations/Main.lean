/-
Copyright (c) 2024 Damiano Testa. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Damiano Testa
-/
import Cli.Basic
import Lean.Elab.Frontend

/-!
# Script to automatically update deprecated declarations

This file contains the code to perform the auto-replacements of `deprecated` declarations.

Running `lake exe update_deprecations` assumes that there is a working cache and
uses the information from deprecations to automatically substitute deprecated declarations.

The script handles namespacing, replacing a possibly non-fully-qualified, deprecated name with the fully-qualified non-deprecated name.

It is also possible to use
```bash
lake exe update_deprecations --mods One.Two.Three,Dd.Ee.Ff
```
to limit the scope of the replacements to the modules `One.Two.Three` and `Dd.Ee.Ff`.

Currently, this does *not* work with dot-notation.
I will update the script once the deprecation warning for dot-notation becomes available.
-/

namespace UpdateDeprecations

/-- `findNamespaceMatch fullName s` assumes that
* `fullName` is a string representing the fully-qualified name of a declaration
  (e.g. `Nat.succ` instead of `succ` or `.succ`);
* `s` is a string beginning with a possibly non-fully qualified name
  (e.g. any of `Nat.succ`, `succ`, `.succ`, possibly continuing with more characters).

If `fullName` and `s` could represent the same declaration, then `findNamespaceMatch` returns
`some <prefix of s matching namespaced fullName>` else it returns `none`
-/
def findNamespaceMatch (fullName s : String) : Option String :=
  Id.run do
  let mut comps := fullName.splitOn "."
  for _ in comps do
    let noDot := ".".intercalate comps
    if noDot.isPrefixOf s then return noDot
    let withDot := "." ++ noDot
    if withDot.isPrefixOf s then return withDot
    comps := comps.drop 1
  dbg_trace "No tail segment of '{fullName}' is a prefix of '{s}'"
  return none

/-- `replaceCheck s check repl st` takes as input
* a "source" `String` `s`;
* a `String` `check` representing what should be replaced;
* a replacement `String` `repl`;
* a natural number `st` representing the number of characters in `s` until the beginning of `check`.

If `check` coincides with the substring of `s` beginning at `st`, then it returns `some s` with the
identified occurrence of `check` replaced by `repl`.
Otherwise, it returns `none`.
-/
def replaceCheck (s check repl : String) (st : Nat) : Option String :=
  match findNamespaceMatch check (s.drop st) with
    | none => none
    | some check =>
      let sc := s.toList
      let fi := st + check.length
      some ⟨sc.take st ++ repl.toList ++ sc.drop fi⟩

/-- `substitutions lines dat` takes as input the array `lines` of strings and the "instructions"
`dat : Array ((String × String) × (Nat × Nat))`.
The elements of `dat` are of the form `((old, new), (line, column))` where
* `(old, new)` is a pair of strings, representing
  the current text `old` and the replacement text `new`;
* `(line, column)` is a pair of natural number representing the position of the start of the `old`
  text.

For each replacement instruction, if the substring of `lines[line]!` starting at `column` is `old`,
then `substitutions` replaces `old` with `new`, otherwise, it leaves the string unchanged.

Once all the instructions have been parsed, `substitutions` returns a count of the number of
successful substitutions, the number of unsuccessful substitutions and the array of strings
incorporating all the substitutions.
-/
def substitutions (lines : Array String) (dat : Array ((String × String) × (Nat × Nat))) :
    (Nat × Nat) × Array String := Id.run do
  let mut new := lines
  let mut replaced := 0
  let mut unreplaced := 0
  for ((check, repl), (l', c)) in dat do
    let l := l' - 1
    match replaceCheck new[l]! check repl c with
      | some newLine => new := new.modify l (fun _ => newLine); replaced := replaced + 1
      | none => unreplaced := unreplaced + 1
  ((replaced, unreplaced), new)

/-- `getBuild` checks if there is an available cache.  If this is the case, then it returns
the replayed build, otherwise it asks to build/download the cache.
The optional `mods` argument is an array of module names, limiting the build to the given
array, if `mods ≠ #[]`. -/
def getBuild (mods : Array String := #[]) : IO String := do
  -- for the entries of `mods` that end in `.lean`, remove the ending and replace `/` with `.`
  let mods := mods.map fun mod =>
    if mod.takeRight 5 == ".lean" then
      (mod.dropRight 5).replace ⟨[System.FilePath.pathSeparator]⟩ "." else mod
  let build ← IO.Process.output { cmd := "lake", args := #["build", "--no-build"] ++ mods }
  if build.exitCode != 0 then
    IO.println "There are out of date oleans. Run `lake build` or `lake exe cache get` first"
    return default
  return build.stdout

open Lean

section build_syntax

/-- `Corrections` is the `HashMap` storing information about corrections.
The entries of the array associated to each `System.FilePath` are the two pairs
* `(oldString, newString)`,
* `(row, column)`.
-/
abbrev Corrections := HashMap System.FilePath (Array ((String × String) × (Nat × Nat)))

/-- extend the input `Corrections` with the given data. -/
def extend (s : Corrections) (fil : System.FilePath) (oldNew : String × String) (pos : Nat × Nat) :
    Corrections :=
  let corrections := (s.find? fil).getD default
  s.insert fil (corrections.push (oldNew, pos))

/-- A custom syntax category for parsing the output lines of `lake build`:
a `buildSeq` consists of a sequence of `build` followed by `Build completed successfully.` -/
declare_syntax_cat buildSeq

/-- A custom syntax category for parsing the output lines of `lake build`. -/
declare_syntax_cat build

/-- Syntax for a successfully built file. -/
syntax "ℹ [" num "/" num "]" ident ident : build

/-- Syntax for a file with warnings. -/
syntax "⚠ [" num "/" num "]" ident ident : build

/-- A `buildSeq` consists of a sequence of `build` followed by `Build completed successfully.` -/
syntax build* "Build completed successfully." : buildSeq

/-- Syntax for the output of a file in `lake build`, e.g. `././././MyProject/Path/To/File.lean`. -/
syntax "././././" sepBy(ident, "/") : build

/-- a deprecated declaration. -/
syntax "warning:" build ":" num ":" num ": `" ident
  "` has been deprecated, use `" ident "` instead" : build

end build_syntax

open System.FilePath in
/-- `toFile bld` takes as input a `` `build``-syntax representing a file and returns
the corresponding `System.FilePath`. -/
def toFile : TSyntax `build → System.FilePath
  | `(build| ././././ $xs/*) =>
    let xs := xs.getElems
    let last := match xs.back.getId.toString.splitOn ⟨[extSeparator]⟩ with
                      | [fil, "lean"] => addExtension fil "lean"
                      | [f] => f
                      | _ => default
    xs.pop.foldr (·.getId.toString / ·) last
  | _ => default

section elabs

/-- extracts the corrections from a `build` syntax. -/
def getCorrections : TSyntax `build → Option (System.FilePath × (String × String) × (Nat × Nat))
  | `(build| warning: $fil:build: $s : $f : `$depr` has been deprecated, use `$new` instead) =>
    let oldNewName := (depr.getId.toString, new.getId.toString)
    (toFile fil, oldNewName, s.getNat, f.getNat)
  | _ => default

/-- Parse the output of `lake build` and perform the relevant substitutions. -/
elab bds:build* tk:"Build completed successfully." : command => do
  let mut s : Corrections := {}
  for bd in bds do
    if let some (fil, oldNew, pos) := getCorrections bd then
      s := extend s fil oldNew pos
  let modifiedFiles ← s.foldM (init := {}) fun summary fil arr => do
    let mut summary : HashMap System.FilePath (Nat × Nat) := summary
    -- sort the corrections, so that the lines are parsed in reverse order and, within each line,
    -- the corrections are applied also in reverse order
    let arr := arr.qsort fun (_, (l1, c1)) (_, (l2, c2)) => l2 < l1 || (l1 == l2 && c2 < c1)
    let lines ← IO.FS.lines fil
    let ((replaced, unreplaced), replacedLines) := substitutions lines arr
    let (m, n) := (summary.find? fil).getD (0, 0)
    summary := summary.insert fil (m + replaced, n + unreplaced)
    if replacedLines != lines then
      let newFile := ("\n".intercalate replacedLines.toList).trimRight.push '\n'
      IO.FS.writeFile fil newFile
    return summary
  let noFiles := modifiedFiles.size
  let msg :=
    if noFiles == 0 then m!"No modifications needed"
    else if modifiedFiles.toArray.all (fun (_, _, x) => x == 0) then
      let totalModifications := modifiedFiles.fold (fun a _ (x, _) => a + x) 0
      let toMo := m!"{totalModifications} modification" ++ if totalModifications == 1 then m!"" else "s"
      let moFi := m!" across {noFiles} file" ++ if noFiles == 1 then m!"" else "s"
      toMo ++ moFi ++ ", all successful"
    else
      modifiedFiles.fold (init := "| File | mods | unmods |\n|-|-|")
        fun msg fil (modified, unmodified) =>
          let mods := if modified == 0 then " 0" else s!"+{modified}"
          let unmods := if unmodified == 0 then " 0" else s!"-{unmodified}"
          msg ++ s!"\n| {fil} | {mods} | {unmods} |"
  logInfoAt tk m!"{msg}"
  logInfoAt tk m!"{noFiles}"
end elabs

open Cli in
/-- Implementation of the `update_deprecations` command line program.
The exit code is the number of files that the command updates/creates. -/
def updateDeprecationsCLI (args : Parsed) : IO UInt32 := do
  let mods := ← match args.flag? "mods" with
              | some mod => return mod.as! (Array String)
              | none => return #[]
  dbg_trace "{mods}"
  let buildOutput ← getBuild mods
  dbg_trace "after build '{buildOutput}'"
  if buildOutput.isEmpty then return 1
  --Lean.initSearchPath (← Lean.findSysroot)
  dbg_trace "after findSys"
  -- create the environment with `import UpdateDeprecations.Main`
  let env : Environment ← importModules (leakEnv := true) #[{module := `UpdateDeprecations.Main}] {}
  dbg_trace "after env"
  -- process the `lake build` output, catching messages
  let (_, msgLog) ← Lean.Elab.process buildOutput env {}
  let exitCode := ← match msgLog.msgs.toArray with
    | #[msg, exCode] => do
      IO.println f!"{(← msg.toString).trimRight}"
      return String.toNat! (← exCode.toString).trimRight
    | msgs => do
      IO.println f!"{← msgs.mapM (·.toString)}"
      return 1
  if exitCode == 0 then return 0
  -- the exit code is the total number of changes that should have happened, whether or not they
  -- actually took place modulo `UInt32.size = 4294967296` (returning 1 if the remainder is `0`).
  -- In particular, the exit code is `0` if and only if no replacement was necessary.
  else return ⟨max 1 (exitCode % UInt32.size), by unfold UInt32.size; omega⟩

/-- Setting up command line options and help text for `lake exe update_deprecations`. -/
def updateDeprecations : Cli.Cmd := `[Cli|
  updateDeprecations VIA updateDeprecationsCLI; ["0.0.1"]
  "\nPerform the substitutions suggested by the output of `lake build` on the whole project. \
  You can run this on some modules only, using the optional `--mods`-flag: running\n\n\
  lake exe update_deprecations --mods One.Two.Three,Dd.Ee.Ff\n\n\
  only updates the deprecations in `One.Two.Three` and `Dd.Ee.Ff`. \
  Note that you should provide a comma-separated list of module names, with no spaces between them. \
  As a convenience, the script tries to parse *paths* instead of *module names*: \
  passing\n\n\
  lake exe update_deprecations --mods One/Two/Three.lean,Dd.Ee.Ff\n\n\
  has the same effect as the command above."

  FLAGS:
    mods : Array String; "you can pass an array of modules using the `--mods`-flag \
                          e.g. `--mods One.Two.Three,Dd.Ee.Ff`"
]

end UpdateDeprecations

/-- The entrypoint to the `lake exe update_deprecations` command. -/
def main (args : List String) : IO UInt32 := UpdateDeprecations.updateDeprecations.validate args
