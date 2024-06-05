import Lake
open Lake DSL

package updateDeprecations where
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩, -- pretty-prints `fun a ↦ b`
    ⟨`autoImplicit, false⟩,
    ⟨`relaxedAutoImplicit, false⟩
  ]

require Cli from git "https://github.com/leanprover/lean4-cli" @ "main"

@[default_target]
lean_lib UpdateDeprecations where
--  -- add library configuration options here

/-- `lake exe update_deprecations` automatically updates deprecations. -/
@[default_target]
lean_exe update_deprecations where
  srcDir := "UpdateDeprecations"
  root := `Main
  supportInterpreter := true
