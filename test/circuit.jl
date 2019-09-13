using Sym, Yao

A(i, j) = control(i, j=>shift(2Sym.SymReal(Sym.Constant(:π))/(1<<(i-j+1))))
B(n, k) = chain(n, j==k ? put(k=>H) : A(j, k) for j in k:n)
qft(n) = chain(B(n, k) for k in 1:n)

G = A(1, 2)(3)

mat(SymComplex, qft(3))
M1 = Matrix(mat(SymComplex, B(2, 2)))
M2 = Matrix(mat(SymComplex, B(2, 1)))

c = B(2, 1)

M1 = mat(SymComplex, c[1])
M2 = mat(SymComplex, c[2])

@which Base.promote_op(*, eltype(M1), eltype(M2))


@which mat(SymComplex, c[1]) * mat(SymComplex, c[2])

@which mat(SymComplex, B(2, 1))

ex = M1[1, 1] * M2[1, 1]

M[4, 3]

mat(SymComplex, qft(2))

