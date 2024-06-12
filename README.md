# A Lean 4 script to automatically update deprecated declarations

This repository contains the code to perform the auto-replacements of `deprecated` declarations.

Running `lake exe update_deprecations` assumes that there is a working cache and
uses the information from deprecations to automatically substitute deprecated declarations.

The script handles namespacing, replacing a possibly non-fully-qualified, deprecated name with the fully-qualified non-deprecated name.

The script also attempts to deal with dot-notation, though it uses some heuristics in this case.

It is also possible to use
```bash
lake exe update_deprecations --mods One.Two.Three,Dd.Ee.Ff
```
to limit the scope of the replacements to the modules `One.Two.Three` and `Dd.Ee.Ff`.

As a convenience, the script tries to parse *paths* instead of *module names*:
passing
```bash
lake exe update_deprecations --mods One/Two/Three.lean,Dd.Ee.Ff
```
has the same effect as the command above.

---

## Using `lake exe update_deprecations` in your project

Add
```lean
require UpdateDeprecations from git "https://github.com/adomani/UpdateDeprecations" @ "master"
```
to the `lakefile.lean`.
After that, run
```bash
lake update UpdateDeprecations
```
to download the package.

You are good to go!

Typing
```bash
lake exe update_deprecations --help
```
provides some help.

---

### Testing that the setup works

After `lake update UpdateDeprecations` you should have a copy of the `UpdateDeprecations` repository in you `.lake/packages` folder.

To see the script in action, copy the `UpdateDeprecations/Practice.lean` file from there inside your main project folder, build it and update the deprecations.
```bash
MyProject='MainDir'
cp -i .lake/packages/UpdateDeprecations/UpdateDeprecations/Practice.lean "${MyProject}"/Practice.lean

lake build "${MyProject}".Practice
## some warnings of deprecated declarations

lake exe update_deprecations --mods "${MyProject}"/Practice.lean
# 8 modifications across 1 file, all successful
```
