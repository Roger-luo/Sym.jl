using Sym, Yao

A(i, j) = control(i, j=>shift(2Sym.SymReal(Sym.Constant(:π))/(1<<(i-j+1))))
B(n, k) = chain(n, j==k ? put(k=>H) : A(j, k) for j in k:n)
qft(n) = chain(B(n, k) for k in 1:n)

M = mat(SymComplex, qft(3))
