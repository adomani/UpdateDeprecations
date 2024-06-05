import Lake
open Lake DSL

package «UpdateDeprecations» where
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩, -- pretty-prints `fun a ↦ b`
    ⟨`autoImplicit, false⟩,
    ⟨`relaxedAutoImplicit, false⟩
  ]

require Cli from git "https://github.com/leanprover/lean4-cli" @ "main"

lean_lib «UpdateDeprecations» where
  -- add library configuration options here
lean_lib Cache

/-- `lake exe update_deprecations` automatically updates deprecations. -/
lean_exe update_deprecations where
  srcDir := "scripts"
  supportInterpreter := true

@[default_target]
lean_exe «updatedeprecations» where
  root := `Main
