(* ****** ****** *)
#include
"share\
/atspre_staload.hats"
(* ****** ****** *)
#staload
"./../../mylib/mylib.dats"
(* ****** ****** *)
(*
implement
main0 = lam () => ()
*)
(* ****** ****** *)
typedef tvar = string
typedef topr = string
(* ****** ****** *)
datatype term =
//
| TMint of int
| TMbtf of bool
//
| TMvar of tvar
| TMlam of (tvar, term)
| TMapp of (term, term)
//
| TMopr of (topr, termlst)
//
| TMif0 of (term, term, term)
//
where termlst = mylist(term)
//
(* ****** ****** *)
extern
fun
print_term(t0:term): void
extern
fun
fprint_term
(out:FILEref, t0:term): void
(* ****** ****** *)
implement
print_term(t0) =
fprint_term(stdout_ref, t0)
(* ****** ****** *)
implement
fprint_val<term> = fprint_term
(* ****** ****** *)
overload print with print_term
overload fprint with fprint_term
(* ****** ****** *)

implement
fprint_term
(out, t0) =
(
case+ t0 of
|
TMint(i0) =>
fprint!(out, "TMint(", i0, ")")
|
TMbtf(b0) =>
fprint!(out, "TMbtf(", b0, ")")
|
TMvar(v0) =>
fprint!(out, "TMvar(", v0, ")")
|
TMlam(v0, t1) =>
fprint!(out, "TMlam(", v0, ";", t1, ")")
|
TMapp(t1, t2) =>
fprint!(out, "TMapp(", t1, ";", t2, ")")
|
TMopr(nm, ts) =>
fprint!(out, "TMopr(", nm, ";", ts, ")")
|
TMif0(t1, t2, t3) =>
fprint!(out, "TMif0(", t1, ";", t2, ";", t3, ")")
)

(* ****** ****** *)

val x = TMvar("x")
val y = TMvar("y")
val z = TMvar("z")

(* ****** ****** *)

val I = TMlam("x", x) // lam x. x
val K = TMlam("x", TMlam("y", x)) // lam x. lam y. x
val K' = TMlam("x", TMlam("y", y)) // lam x. lam y. y
val S = TMlam("x", TMlam("y", TMlam("z", TMapp(TMapp(x, z), TMapp(y, z)))))

(* ****** ****** *)

(*
(* ****** ****** *)
//
HX-2022-09-14:
How to test:
myatscc lambda0.dats && ./lambda0_dats
*)
//
val () = println!("I = ", I)
val () = println!("K = ", K)
val () = println!("S = ", S)
val () = println!("K' = ", K')
//
(* ****** ****** *)
//
val omega =
TMlam("x", TMapp(x, x))
//
val Omega = TMapp(omega, omega)
//
val () = println!("omega = ", omega)
val () = println!("Omega = ", Omega)
//
(* ****** ****** *)
implement main0() = () // HX: it is a dummy
(* ****** ****** *)

extern
fun
term_interp(t0: term): term
extern
fun
termlst_interp(ts: termlst): termlst

(* ****** ****** *)

extern
fun
term_subst0 // t0[x0 -> sub]
(t0: term, x0: tvar, sub: term): term
extern
fun
termlst_subst0 // t0[x0 -> sub]
(ts: termlst, x0: tvar, sub: term): termlst

(* ****** ****** *)

implement
term_interp(t0) =
(
case+ t0 of
//
|TMint _ => t0
|TMbtf _ => t0
//
|TMvar _ => t0
//
|TMlam _ => t0
(*
// HX: please note
// no evaluagtion under lambda!!!
|
TMlam(x1, t1) =>
TMlam(x1, t1) where
{
val t1 = term_interp(t1)
}
*)
//
|
TMapp(t1, t2) =>
let
val t1 = term_interp(t1)
val t2 = term_interp(t2)
in//let
case+ t1 of
| TMlam(x1, tt) =>
term_interp
(term_subst0(tt, x1, t2))
| _(*non-TMlam*) => TMapp(t1, t2) // type-error
end // let // end of [TMapp]
//
|
TMopr(nm, ts) =>
TMopr(nm, ts) where
{
val ts =
termlst_interp(ts) }
//
|
TMif0(t1, t2, t3) =>
let
val t1 = term_interp(t1)
in//let
case+ t1 of
|
TMbtf(b1) =>
if b1
then term_interp(t2) else term_interp(t3)
|
_(*non-TMbtf*) =>
TMif0(t1, term_interp(t2), term_interp(t3)) // type-error
end // let // end of [TMif0]
) (* case+ *) // end of [term_interp]

(* ****** ****** *)

implement
termlst_interp(ts) =
(
case+ ts of
|
mylist_nil() =>
mylist_nil()
|
mylist_cons(t1, ts) =>
mylist_cons
(term_interp(t1), termlst_interp(ts))
)

(* ****** ****** *)

val
SKK = TMapp(TMapp(S, K), K)
val () =
println!("interp(SKK) = ", term_interp(SKK))

(* ****** ****** *)
(*
HX: This is non-terminating evaluation!!!
val () =
println!("interp(Omega) = ", term_interp(Omega))
*)
(* ****** ****** *)

implement
term_subst0(t0, x0, sub) =
(
case+ t0 of
//
| TMint _ => t0
| TMbtf _ => t0
//
| TMvar(x1) =>
  if x0 = x1 then sub else t0
//
| TMlam(x1, tt) =>
  if x0 = x1 then t0 else
  TMlam(x1, term_subst0(tt, x0, sub))
//
| TMapp(t1, t2) =>
  TMapp(t1, t2) where
  {
    val t1 = term_subst0(t1, x0, sub)
    val t2 = term_subst0(t2, x0, sub)
  }
//
| TMopr(nm, ts) =>
  TMopr(nm, ts) where
  {
    val ts =
    termlst_subst0(ts, x0, sub)
  }
//
| TMif0(t1, t2, t3) =>
  TMif0(t1, t2, t3) where
  {
    val t1 = term_subst0(t1, x0, sub)
    val t2 = term_subst0(t2, x0, sub)
    val t3 = term_subst0(t3, x0, sub)
  }
//
(*
| _ (* otherwise *) =>
(
assert(false); exit(0)) where
{
  val () = print!("term_subst0: t0 = ", t0)
}
*)
//
) (* end of [term_subst0(t0, x0, sub)] *)

(* ****** ****** *)

implement
termlst_subst0(ts, x0, sub) =
(
case+ ts of
|
mylist_nil() => mylist_nil()
|
mylist_cons(t1, ts) =>
mylist_cons
(term_subst0(t1, x0, sub), termlst_subst0(ts, x0, sub))
) (* end of [termlst_subst0(t0, x0, sub)] *)

(* ****** ****** *)

(* end of [CS525-2022-Fall/lecture/lecture-09-21/lambda0.dats] *)
