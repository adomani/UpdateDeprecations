import Lake
open Lake DSL

package UpdateDeprecations where
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩, -- pretty-prints `fun a ↦ b`
    ⟨`autoImplicit, false⟩,
    ⟨`relaxedAutoImplicit, false⟩
  ]

require Cli from git "https://github.com/leanprover/lean4-cli" @ "main"

--@[default_target]
lean_lib UpdateDeprecations
--  -- add library configuration options here

--source https://leanprover.zulipchat.com/#narrow/stream/270676-lean4/topic/making.20a.20lean.20executable.20available.20in.20a.20project/near/443401065
/-- `lake exe update_deprecations` automatically updates deprecations. -/
@[default_target]
lean_exe update_deprecations where
  root := `Main
  supportInterpreter := true
