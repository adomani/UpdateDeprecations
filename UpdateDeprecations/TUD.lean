theorem ok1 : True := .intro

@[deprecated ok1]
theorem hello1 : True := .intro

theorem True.ok2 (t : True) : True := t

@[deprecated True.ok2]
theorem True.hello2 (t : True) : True := t.ok2

open True
example : True ∧ True := by
  constructor
  · exact hello1
  · exact hello2 hello1
