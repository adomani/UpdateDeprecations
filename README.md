# A Lean 4 script to automatically update deprecated declarations

This repository contains the code to perform the auto-replacements of `deprecated` declarations.

Running `lake exe update_deprecations` assumes that there is a working cache and
uses the information from deprecations to automatically substitute deprecated declarations.

The script handles namespacing, replacing a possibly non-fully-qualified, deprecated name with the fully-qualified non-deprecated name.

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

Currently, this does *not* work with dot-notation.
I will update the script once the deprecation warning for dot-notation becomes available.

## Using `lake exe update_deprecations` in your project

Add
```lean
require updateDeprecations from git "https://github.com/adomani/UpdateDeprecations" @ "master"
```
to the `lakefile.lean`.
After that, run
```bash
lake update updateDeprecations
```
to download the package.

You are good to go!

Typing
```bash
lake exe update_deprecations --help
```
provides some help.
