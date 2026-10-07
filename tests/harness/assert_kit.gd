class_name AssertKit extends RefCounted
# tests/harness/assert_kit.gd  --  the tiny shared harness every test scene uses (GDD 22).
# A check that cannot fail is worse than no check: GDD 0 records two defects that shipped
# because the tests around them were tautologies or had windows too wide to catch a
# regression. Write every assertion so that breaking the system makes it FAIL.

var group_name := ""
var passed := 0
var failed := 0
var failures: Array[String] = []

func _init(p_group: String = "") -> void:
	group_name = p_group

func ok(cond: bool, label: String) -> bool:
	if cond:
		passed += 1
		print("  pass  ", label)
	else:
		failed += 1
		failures.append(label)
		printerr("  FAIL  ", label)
	return cond

func eq(a: Variant, b: Variant, label: String) -> bool:
	return ok(a == b, "%s  (got %s, want %s)" % [label, str(a), str(b)])

func neq(a: Variant, b: Variant, label: String) -> bool:
	return ok(a != b, "%s  (got %s, must not be %s)" % [label, str(a), str(b)])

func near(a: float, b: float, tol: float, label: String) -> bool:
	return ok(absf(a - b) <= tol, "%s  (got %.4f, want %.4f +/-%.4f)" % [label, a, b, tol])

func between(v: float, lo: float, hi: float, label: String) -> bool:
	return ok(v >= lo and v <= hi, "%s  (got %.4f, want %.4f..%.4f)" % [label, v, lo, hi])

func not_null(v: Variant, label: String) -> bool:
	return ok(v != null, "%s  (was null)" % label)

func report() -> int:
	print("")
	print("== %s: %d passed, %d failed ==" % [group_name if group_name != "" else "test", passed, failed])
	for f in failures:
		printerr("   FAILED: ", f)
	return failed

# Call from a test scene's _ready(): report, then exit non-zero so CI/shell scripts notice.
func finish(node: Node) -> void:
	var f := report()
	node.get_tree().quit(1 if f > 0 else 0)
