import Lake
open Lake DSL

package «UpdateDeprecations» where
  -- add package configuration options here

lean_lib «UpdateDeprecations» where
  -- add library configuration options here

@[default_target]
lean_exe «updatedeprecations» where
  root := `Main
