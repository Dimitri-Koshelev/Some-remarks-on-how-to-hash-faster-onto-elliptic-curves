# Dmitrii Koshelev (the author of the code) was supported by Web3 Foundation (W3F)
# Throughout the code the notation is consistent with author's article 
# "Indifferentiable hashing to ordinary elliptic Fq-curves of j = 0 with the cost of one exponentiation in Fq"

import hashlib
import random
import string

# parameters for the BLS12-381 curve Eb
u = -0xd201000000010000
q = ((u - 1)^2 * r) // 3 + u
assert( ceil(log(q,2).n()) == 381 )
assert(q.is_prime())
assert(q % 27 == 10)
m = (q - 10) // 27

Fq = GF(q)
sb = Fq(2)   # sqrt(b)
b = sb^2
w = b^((q-1) // 3)
assert(w != 1)
w2 = w^2
z = w.nth_root(3)   # zeta
z2 = z^2
c1 = (b/z).nth_root(3)
c2 = c1^2


##############################################################################

	
# auxiliary map from the threefold T to Eb
def hPrime(num0,num1,num2,den, t1,t2):
	v = den^2
	u = num0^2 - b*v	
	th = u*v^8*(u^2*v^25)^m   # theta
	v = th^3*v
	v3 = v^3
	u3 = u^3
	L = [t1, w*t1, w2*t1]
	L.sort()
	n = L.index(t1)
	
	if v3 == u3:
		X = w^n*th
		if v == u:
			Y = 1; Z = 1
		if v == w*u:
			Y = z; Z = z
		if v == w2*u:
			Y = z2; Z = z2
		Y = Y*num0
	if v3 == w*u3:
		X = c1*th*t1
		zu = z*u
		if v == zu:
			Y = 1; Z = 1
		if v == w*zu:
			Y = z; Z = z
		if v == w2*zu:
			Y = z2; Z = z2
		Y = Y*num1	
	if v3 == w2*u3:
		X = c2*th*t2
		z2u = z2*u
		if v == z2u:
			Y = 1; Z = 1
		if v == w*z2u:
			Y = z; Z = z
		if v == w2*z2u:
			Y = z2; Z = z2
		Y = Y*num2
	# elif is not used to respect constant-time execution
		
	X = X*den
	Z = Z*den
	return X,Y,Z
	

# rational map Fq^2 -> T(Fq)
def phi(t1,t2):
	s1 = t1^3
	s2 = t2^3
	s1s1 = s1^2
	s2s2 = s2^2
	global s1s2
	s1s2 = s1*s2
	
	b2 = b^2
	b3 = b*b2
	b4 = b2^2
	a20 = b2*s1s1
	a11 = 2*b3*s1s2
	a10 = 2*b*s1
	a02 = b4*s2s2
	a01 = 2*b2*s2
	
	num0 = sb*(a20 - a11 + a10 + a02 + a01 - 3)
	num1 = sb*(-3*a20 + a11 + a10 + a02 - a01 + 1)
	num2 = sb*(a20 + a11 - a10 - 3*a02 + a01 + 1)
	den = a20 - a11 - a10 + a02 - a01 + 1	
	return num0,num1,num2,den


# map Fq^2 -> Eb(Fq)
def h(t1,t2):
	num0,num1,num2,den = phi(t1,t2)
	X,Y,Z = hPrime(num0,num1,num2,den, t1,t2)
	if s1s2 == 0:
		X = 0; Y = sb; Z = 1
	if den == 0:
		X = 0; Y = 1; Z = 0
	return X,Y,Z
	

# hash function to the plane Fq^2
def eta(s):
	s = s.encode("utf-8")
	s0 = s + b'0'
	s1 = s + b'1'
	# 512 > 510 = 381 + 128 + 1, hence sha512 provides the 128-bit security level
	# (see Lemma 14 of Brier et al.'s article)
	hash0 = hashlib.sha512(s0).hexdigest()
	hash0 = int(hash0, base=16)
	hash1 = hashlib.sha512(s1).hexdigest()
	hash1 = int(hash1, base=16)
	return Fq(hash0), Fq(hash1)
		
	
# resulting hash function to Eb(Fq)	
def H(s):
	t1,t2 = eta(s)
	return h(t1,t2)


##############################################################################


# main 
symbols = string.ascii_letters + string.digits
length = random.randint(0,50)
s = ''.join( random.choices(symbols, k=length) )
Eb = EllipticCurve(Fq, [0,b])
X,Y,Z = H(s)
print( f"\nH({s})   =   ({X} : {Y} : {Z})   =   {Eb(X,Y,Z)}" )
