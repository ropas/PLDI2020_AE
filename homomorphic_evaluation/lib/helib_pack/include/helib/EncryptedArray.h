/* Copyright (C) 2012-2017 IBM Corp.
 * This program is Licensed under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 *   http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License. See accompanying LICENSE file.
 */
#ifndef HELIB_ENCRYPTEDARRAY_H
#define HELIB_ENCRYPTEDARRAY_H
/**
 * @file EncryptedArray.h
 * @brief Data-movement operations on encrypted arrays of slots
 */
#include <exception>
#include <cmath>
#include <complex>
#include <NTL/Lazy.h>
#include <NTL/pair.h>
#include <NTL/SmartPtr.h>
#include "FHE.h"

typedef std::complex<double> cx_double;

// DIRT: we're using undocumented NTL interfaces here
//   also...this probably should be defined in NTL, anyway....
#define FHE_MORE_UNWRAPARGS(n) NTL_SEPARATOR_##n NTL_REPEATER_##n(NTL_UNWRAPARG)

// these are used to implement PlaintextArray stuff routines

#define PA_BOILER \
    const PAlgebraModDerived<type>& tab = ea.getTab(); \
    const RX& G = ea.getG(); \
    long n = ea.size(); \
    long d = ea.getDegree(); \
    std::vector<RX>& data = pa.getData<type>(); \
    RBak bak; bak.save(); tab.restoreContext(); \


#define CPA_BOILER \
    const PAlgebraModDerived<type>& tab = ea.getTab(); \
    const RX& G = ea.getG(); \
    long n = ea.size(); \
    long d = ea.getDegree(); \
    const std::vector<RX>& data = pa.getData<type>(); \
    RBak bak; bak.save(); tab.restoreContext(); \



class PlaintextArray; // forward reference
class EncryptedArray; // forward reference

/**
 * @class EncryptedArrayBase
 * @brief virtual class for data-movement operations on arrays of slots
 *
 * An object ea of type EncryptedArray stores information about an
 * FHEcontext context, and a monic polynomial G.  If context defines
 * parameters m, p, and r, then ea is a helper abject
 * that supports encoding/decoding and encryption/decryption
 * of std::vectors of plaintext slots over the ring (Z/(p^r)[X])/(G). 
 *
 * The polynomial G should be irreducble over Z/(p^r) (this is not checked).
 * The degree of G should divide the multiplicative order of p modulo m
 * (this is checked). Currently, the following restriction is imposed:
 *
 * either r == 1 or deg(G) == 1 or G == factors[0].
 * 
 * ea stores objects in the polynomial ring Z/(p^r)[X].
 * 
 * Just as for the class PAlegebraMod, if p == 2 and r == 1, then these
 * polynomials are represented as GF2X's, and otherwise as zz_pX's.
 * Thus, the types of these objects are not determined until run time.
 * As such, we need to use a class heirarchy, which mirrors that of
 * PAlgebraMod, as follows.
 * 
 * EncryptedArrayBase is a virtual class
 * 
 * EncryptedArrayDerived<type> is a derived template class, where
 * type is either PA_GF2 or PA_zz_p.
 *
 * The class EncryptedArray is a simple wrapper around a smart pointer to
 * an EncryptedArrayBase object: copying an EncryptedArray object results
 * is a "deep copy" of the underlying object of the derived class.
****************************************************************/

class EncryptedArrayBase {  // purely abstract interface 
public:
  virtual ~EncryptedArrayBase() {}

  virtual EncryptedArrayBase* clone() const = 0;
  // makes this usable with cloned_ptr

  virtual PA_tag getTag() const = 0;

  virtual const FHEcontext& getContext() const = 0;
  virtual const PAlgebra& getPAlgebra() const = 0;
  virtual const long getDegree() const = 0;
  virtual const long getP2R() const = 0;

  //! @brief Right rotation as a linear array.
  //! E.g., rotating ctxt=Enc(1 2 3 ... n) by k=1 gives Enc(n 1 2 ... n-1)
  virtual void rotate(Ctxt& ctxt, long k) const = 0; 

  //! @brief Non-cyclic right shift with zero fill
  //! E.g., shifting ctxt=Enc(1 2 3 ... n) by k=1 gives Enc(0 1  2... n-1)
  virtual void shift(Ctxt& ctxt, long k) const = 0;

  //! @brief right-rotate k positions along the i'th dimension
  //! @param dc means "don't care", which means that the caller guarantees
  //! that only zero elements rotate off the end -- this allows for some
  //! optimizations that would not otherwise be possible
  virtual void rotate1D(Ctxt& ctxt, long i, long k, bool dc=false) const = 0; 

  //! @brief Right shift k positions along the i'th dimension with zero fill
  virtual void shift1D(Ctxt& ctxt, long i, long k) const = 0; 

  ///@{
  //! @name Encoding/decoding methods
  // encode/decode arrays into plaintext polynomials

  // These methods are only defined for some of the derived calsses
  virtual void encode(zzX& ptxt, const std::vector< long >& array) const
  {throw helib::LogicError("EncryptedArrayBase::encode for undefined type");}
  virtual void encode(NTL::ZZX& ptxt, const std::vector< long >& array) const
  {throw helib::LogicError("EncryptedArrayBase::encode for undefined type");}

  virtual void encode(zzX& ptxt, const std::vector< zzX >& array) const
  {throw helib::LogicError("EncryptedArrayBase::encode for undefined type");}
  virtual void encode(zzX& ptxt, const PlaintextArray& array) const
  {throw helib::LogicError("EncryptedArrayBase::encode for undefined type");}

  virtual void encode(NTL::ZZX& ptxt, const std::vector<NTL::ZZX>& array) const
  {throw helib::LogicError("EncryptedArrayBase::encode for undefined type");}
  virtual void encode(NTL::ZZX& ptxt, const PlaintextArray& array) const
  {throw helib::LogicError("EncryptedArrayBase::encode for undefined type");}

  void encode(zzX& ptxt, const std::vector< NTL::ZZX >& array) const
  { NTL::ZZX tmp; encode(tmp, array); convert(ptxt, tmp); }

  // These methods are only defined for some of the derived calsses
  virtual void decode(std::vector< long  >& array, const NTL::ZZX& ptxt) const
  {throw helib::LogicError("EncryptedArrayBase::decode for undefined type");}
  virtual void decode(std::vector<NTL::ZZX>& array, const NTL::ZZX& ptxt) const
  {throw helib::LogicError("EncryptedArrayBase::decode for undefined type");}
  virtual void decode(PlaintextArray& array, const NTL::ZZX& ptxt) const
  {throw helib::LogicError("EncryptedArrayBase::decode for undefined type");}

  virtual void random(std::vector< long >& array) const = 0; // must be defined

  // These methods are only defined for some of the derived calsses
  virtual void random(std::vector< NTL::ZZX >& array) const
  {throw helib::LogicError("EncryptedArrayBase::decode for undefined type");}

  // FIXME: Inefficient implementation, calls usual decode and returns one slot
  long decode1Slot(const NTL::ZZX& ptxt, long i) const
  { std::vector< long > v; decode(v, ptxt); return v.at(i); }
  void decode1Slot(NTL::ZZX& slot, const NTL::ZZX& ptxt, long i) const
  { std::vector< NTL::ZZX > v; decode(v, ptxt); slot=v.at(i); }

  //! @brief Encodes a std::vector with 1 at position i and 0 everywhere else
  virtual void encodeUnitSelector(zzX& ptxt, long i) const = 0;
  ///@}

  ///@{
  //! @name Encoding+encryption/decryption+decoding
  template<class PTXT>
  void encrypt(Ctxt& ctxt, const FHEPubKey& key, const PTXT& ptxt) const
  {
    //OLD: assert(&getContext() == &ctxt.getContext());
    helib::assertEq(&getContext(), &ctxt.getContext(), "Cannot encrypt when ciphertext has different context than EncryptedArray");
    zzX pp;
    encode(pp, ptxt); // Convert array of slots into a plaintext polynomial
    key.Encrypt(ctxt, pp, getP2R()); // encrypt the plaintext polynomial
    // NOTE: If secret key, will call the overridden FHESecKey::Encrypt
  }

  virtual void decrypt(const Ctxt& ctxt, const FHESecKey& sKey, std::vector< long >& ptxt) const
  {throw helib::LogicError("EncryptedArrayBase::decrypt for undefined type");}
  virtual void decrypt(const Ctxt& ctxt, const FHESecKey& sKey, std::vector< NTL::ZZX >& ptxt) const
  {throw helib::LogicError("EncryptedArrayBase::decrypt for undefined type");}
  virtual void decrypt(const Ctxt& ctxt, const FHESecKey& sKey, PlaintextArray& ptxt) const
  {throw helib::LogicError("EncryptedArrayBase::decrypt for undefined type");}
  virtual void decrypt(const Ctxt& ctxt, const FHESecKey& sKey, std::vector<double>& ptxt) const
  {throw helib::LogicError("EncryptedArrayBase::decrypt for undefined type");}
  virtual void decrypt(const Ctxt& ctxt, const FHESecKey& sKey, std::vector<cx_double>& ptxt) const
  {throw helib::LogicError("EncryptedArrayBase::decrypt for undefined type");}

  // FIXME: Inefficient implementation, calls usual decrypt and returns one slot
  long decrypt1Slot(const Ctxt& ctxt, const FHESecKey& sKey, long i) const
  { std::vector< long > v; decrypt(ctxt, sKey, v); return v.at(i); }
  void decrypt1Slot(NTL::ZZX& slot, const Ctxt& ctxt, const FHESecKey& sKey, long i) const
  { std::vector< NTL::ZZX > v; decrypt(ctxt, sKey, v); slot = v.at(i); }
  ///@}

  //! @brief Linearized polynomials.
  //! L describes a linear map M by describing its action on the standard
  //! power basis: M(x^j mod G) = (L[j] mod G), for j = 0..d-1.  
  //! The result is a coefficient std::vector C for the linearized polynomial
  //! representing M: a polynoamial h in Z/(p^r)[X] of degree < d is sent to
  //! \f[
  //!  M(h(X) \bmod G)= \sum_{i=0}^{d-1}(C[j] \cdot h(X^{p^j}))\bmod G).
  //! \f]
  virtual void buildLinPolyCoeffs(std::vector<NTL::ZZX>& C, const std::vector<NTL::ZZX>& L) const {}

  // restore contexts mod p and mod G
  virtual void restoreContext() const {}
  virtual void restoreContextForG() const {}

  /* some non-virtual convenience functions */

  //! @brief Total size (# of slots) of hypercube
  long size() const { 
    return getPAlgebra().getNSlots(); 
  } 

  //! @brief Number of dimensions of hypercube
  long dimension() const { 
    return getPAlgebra().numOfGens(); 
  }

  //! @brief Size of given dimension
  long sizeOfDimension(long i) const {
    return getPAlgebra().OrderOf(i);
  }

  //! @brief Is rotations in given dimension a "native" operation?
  bool nativeDimension(long i) const {
    return getPAlgebra().SameOrd(i);
  }

  //! @brief returns coordinate of index k along the i'th dimension
  long coordinate(long i, long k) const {
    return getPAlgebra().coordinate(i, k); 
  }

  //! @brief adds offset to index k in the i'th dimension
  long addCoord(long i, long k, long offset) const {
    return getPAlgebra().addCoord(i, k, offset);
  }

  //! @brief rotate an array by offset in the i'th dimension
  //! (output should not alias input)
  template<class U> void rotate1D(std::vector<U>& out, const std::vector<U>& in,
                                  long i, long offset) const {
    //OLD: assert(lsize(in) == size());
    helib::assertEq(lsize(in), size(), "Input vector has wrong size (must equal EncryptedArray::size())");
    out.resize(in.size());
    for (long j = 0; j < size(); j++)
      out[addCoord(i, j, offset)] = in[j]; 
  }
};

/**
 * @class EncryptedArrayDerived
 * @brief Derived concrete implementation of EncryptedArrayBase
 */
template<class type> class EncryptedArrayDerived : public EncryptedArrayBase {
public:
  PA_INJECT(type)

private:
  const FHEcontext& context;
  const PAlgebraModDerived<type>& tab;

  // FIXME: all of these types should be copyable
  // out of context, but NTL 8.0 still does not copy
  // matrix copies out of context correctly, as it
  // relies on plain SetLength...I need to fix this 
  // in NTL
  //
  MappingData<type> mappingData; // MappingData is defined in PAlgebra.h

  NTL::Lazy< NTL::Mat<RE> > linPolyMatrix;

  NTL::Lazy< NTL::Pair< NTL::Mat<R>, NTL::Mat<R> > > normalBasisMatrices;
  // a is the matrix, b is its inverse

public:
  explicit
  EncryptedArrayDerived(const FHEcontext& _context, const RX& _G,
			const PAlgebraMod& _tab);

  EncryptedArrayDerived(const EncryptedArrayDerived& other) // copy constructor
    : context(other.context), tab(other.tab)
  {
    RBak bak; bak.save(); tab.restoreContext();
    REBak ebak; ebak.save(); other.mappingData.restoreContextForG();
    mappingData = other.mappingData;
    linPolyMatrix = other.linPolyMatrix;
    normalBasisMatrices = other.normalBasisMatrices;
  }

  EncryptedArrayDerived& operator=(const EncryptedArrayDerived& other) // assignment
  {
    if (this == &other) return *this;
    //OLD: assert(&context == &other.context);
    helib::assertEq(&context, &other.context, "Cannot assign a EncryptedArrays with different contexts");
    //OLD: assert(&tab == &other.tab);
    helib::assertEq(&tab, &other.tab, "Cannot assign a EncryptedArrays with different tabs");

    RBak bak; bak.save(); tab.restoreContext();
    mappingData = other.mappingData;
    linPolyMatrix = other.linPolyMatrix;
    normalBasisMatrices = other.normalBasisMatrices;
    return *this;
  }

  virtual EncryptedArrayBase* clone() const override { return new EncryptedArrayDerived(*this); }

  virtual PA_tag getTag() const override { return tag; }
  // tag is defined in PA_INJECT, see PAlgebra.h

  template<template <class> class T, class... Args>
  void dispatch(Args&&... args) const
  {
    T<type>::apply(*this, std::forward<Args>(args)...);
  }


  const RX& getG() const { return mappingData.getG(); }

  const NTL::Mat<R>& getNormalBasisMatrix() const {
    if (!normalBasisMatrices.built()) initNormalBasisMatrix(); 
    return normalBasisMatrices->a;
  }

  const NTL::Mat<R>& getNormalBasisMatrixInverse() const {
    if (!normalBasisMatrices.built()) initNormalBasisMatrix(); 
    return normalBasisMatrices->b;
  }

  void initNormalBasisMatrix() const;

  virtual void restoreContext() const override { tab.restoreContext(); }
  virtual void restoreContextForG() const override { mappingData.restoreContextForG(); }


  virtual const FHEcontext& getContext() const override { return context; }
  virtual const PAlgebra& getPAlgebra() const override { return tab.getZMStar(); }
  virtual const long getDegree() const override { return mappingData.getDegG(); }
  const PAlgebraModDerived<type>& getTab() const { return tab; }

  virtual void rotate(Ctxt& ctxt, long k) const override;
  virtual void shift(Ctxt& ctxt, long k) const override;
  virtual void rotate1D(Ctxt& ctxt, long i, long k, bool dc=false) const override;

  const long getP2R() const override {return getTab().getPPowR();}


  template<class U> void // avoid this being "hidden" by other rotate1D's
    rotate1D(std::vector<U>& out, const std::vector<U>& in, long i, long offset) const
    { EncryptedArrayBase::rotate1D(out, in, i, offset); }
  virtual void shift1D(Ctxt& ctxt, long i, long k) const override;


  virtual void encode(NTL::ZZX& ptxt, const std::vector< long >& array) const override
    { genericEncode(ptxt, array);  }

  virtual void encode(zzX& ptxt, const std::vector< long >& array) const override
    { genericEncode(ptxt, array);  }

  virtual void encode(NTL::ZZX& ptxt, const std::vector< NTL::ZZX >& array) const override
    {  genericEncode(ptxt, array); }

  virtual void encode(zzX& ptxt, const std::vector< zzX >& array) const override
    {  genericEncode(ptxt, array); }

  virtual void encode(NTL::ZZX& ptxt, const PlaintextArray& array) const override;
  virtual void encode(zzX& ptxt, const PlaintextArray& array) const override;

  virtual void encodeUnitSelector(zzX& ptxt, long i) const override;

  virtual void decode(std::vector< long  >& array, const NTL::ZZX& ptxt) const override
    { genericDecode(array, ptxt); }

  virtual void decode(std::vector< NTL::ZZX  >& array, const NTL::ZZX& ptxt) const override
    { genericDecode(array, ptxt); }

  virtual void decode(PlaintextArray& array, const NTL::ZZX& ptxt) const override;
  virtual void decode(PlaintextArray& array, const zzX& ptxt) const;

  virtual void random(std::vector< long  >& array) const override
    { genericRandom(array); } // choose at random and convert to std::vector<long>

  virtual void random(std::vector< NTL::ZZX  >& array) const override
    { genericRandom(array); } // choose at random and convert to std::vector<ZZX>

  virtual void decrypt(const Ctxt& ctxt, const FHESecKey& sKey, std::vector< long >& ptxt) const override
    { genericDecrypt(ctxt, sKey, ptxt);
      if (ctxt.getPtxtSpace()<getP2R()) {
	for (long i=0; i<(long)ptxt.size(); i++)
	  ptxt[i] %= ctxt.getPtxtSpace();
      }
    }

  virtual void decrypt(const Ctxt& ctxt, const FHESecKey& sKey, std::vector< NTL::ZZX >& ptxt) const override
    { genericDecrypt(ctxt, sKey, ptxt);
      if (ctxt.getPtxtSpace()<getP2R()) {
	for (long i=0; i<(long)ptxt.size(); i++)
	  PolyRed(ptxt[i], ctxt.getPtxtSpace(),/*abs=*/true);
      }
    }


  virtual void decrypt(const Ctxt& ctxt, const FHESecKey& sKey, PlaintextArray& ptxt) const override
  { genericDecrypt(ctxt, sKey, ptxt); 
    // FIXME: Reduce mod the ciphertext plaintext space as above
    }

  virtual void buildLinPolyCoeffs(std::vector<NTL::ZZX>& C, const std::vector<NTL::ZZX>& L) const override;

  /* the following are specialized methods, used to work over extension
     fields... they assume the modulus context is already set
   */

  void encode(zzX& ptxt, const std::vector< RX >& array) const;
  void decode(std::vector< RX  >& array, const zzX& ptxt) const;

  void encode(NTL::ZZX& ptxt, const std::vector< RX >& array) const;
  void decode(std::vector< RX  >& array, const NTL::ZZX& ptxt) const;

  void encode(RX& ptxt, const std::vector< RX >& array) const;
  void decode(std::vector< RX  >& array, const RX& ptxt) const;

  // Choose random polynomial of the right degree, coeffs in GF2 or zz_p
  void random(std::vector< RX  >& array) const
  { 
    array.resize(size()); 
    for (long i=0; i<size(); i++) NTL::random(array[i], getDegree());
  }

  void decrypt(const Ctxt& ctxt, const FHESecKey& sKey, std::vector< RX >& ptxt) const
    { genericDecrypt(ctxt, sKey, ptxt); }

  virtual void buildLinPolyCoeffs(std::vector<RX>& C, const std::vector<RX>& L) const;


private:

  /* helper template methods, to avoid repetitive code */

  template<class T> 
  void genericEncode(NTL::ZZX& ptxt, const T& array) const
  {
    RBak bak; bak.save(); tab.restoreContext();

    std::vector< RX > array1;
    convert(array1, array);
    encode(ptxt, array1);
  }

  template<class T> 
  void genericEncode(zzX& ptxt, const T& array) const
  {
    RBak bak; bak.save(); tab.restoreContext();

    std::vector< RX > array1;
    convert(array1, array);
    encode(ptxt, array1);
  }

  template<class T>
  void genericDecode(T& array, const NTL::ZZX& ptxt) const
  {
    RBak bak; bak.save(); tab.restoreContext();

    std::vector< RX > array1;
    decode(array1, ptxt);
    convert(array, array1);
  }

  template<class T>
  void genericRandom(T& array) const // T is std::vector<long> or std::vector<ZZX>
  {
    RBak bak; bak.save(); tab.restoreContext(); // backup NTL modulus

    std::vector< RX > array1;    // RX is GF2X or zz_pX
    random(array1);         // choose random coefficients from GF2/zz_p
    convert(array, array1); // convert to type T (see NumbTh.h)
  }

  template<class T>
  void genericDecrypt(const Ctxt& ctxt, const FHESecKey& sKey, 
                      T& array) const
  {
    //OLD: assert(&context == &ctxt.getContext());
    helib::assertEq(&context, &ctxt.getContext(), "Cannot decrypt when ciphertext has different context than EncryptedArray");
    NTL::ZZX pp;
    sKey.Decrypt(pp, ctxt);
    decode(array, pp);
  }
};

//! A different derived class to be used for the approximate-numbers scheme
class EncryptedArrayCx : public EncryptedArrayBase {
  const FHEcontext& context;
  const PAlgebraModCx& alMod;
  zzX iEncoded; // an encoded plaintext with i in all the slots

public:
  static double roundedSize(double x) {
    long rounded = ceil(fabs(x));
    if (rounded < 1) rounded = 1;
    return double(1L << NTL::NumBits(rounded-1));
  }

  double encodei(zzX& ptxt, long precision=-1) const; // encode i in all slots

  explicit EncryptedArrayCx(const FHEcontext& _context)
    : context(_context), alMod(context.alMod.getCx()) {clear(iEncoded);}
  EncryptedArrayCx(const FHEcontext& _context, const PAlgebraModCx& _alMod)
    : context(_context), alMod(_alMod) {clear(iEncoded);}

  // convertion between std::vectors of complex, real, and integers
  static void convert(std::vector<cx_double>& out,
                      const std::vector<double>& in) {
    resize(out,lsize(in));
    for (long i=0; i<lsize(in); i++) out[i] = in[i];
  }
  static void convert(std::vector<double>& out,
                      const std::vector<cx_double>& in) {
    resize(out,lsize(in));
    for (long i=0; i<lsize(in); i++) out[i] = in[i].real();
  }
  static void convert(std::vector<cx_double>& out,
                      const std::vector<long>& in) {
    resize(out,lsize(in));
    for (long i=0; i<lsize(in); i++) out[i] = in[i];
  }
  static void convert(std::vector<long>& out,
                      const std::vector<cx_double>& in) {
    resize(out,lsize(in));
    for (long i=0; i<lsize(in); i++) out[i] = std::round(in[i].real());
  }

  EncryptedArrayBase* clone() const override
  { return  new EncryptedArrayCx(*this); }

  const zzX& getiEncoded() const;
  PA_tag getTag() const override { return PA_cx_tag; }
  const FHEcontext& getContext() const override { return context; }
  const PAlgebra& getPAlgebra() const override { return alMod.getZMStar(); }
  const long getDegree() const override { return 2L; }

  void rotate(Ctxt& ctxt, long k) const override; 
  void shift(Ctxt& ctxt, long k) const override;
  void rotate1D(Ctxt& ctxt, long i, long k, bool dc=false) const override;
  void shift1D(Ctxt& ctxt, long i, long k) const override;

  const long getP2R() const override {return alMod.getPPowR();}

  // These EaCx-specific encoding routines return the
  // scaling factor that was used in the eocoding routine
  double encode(zzX& ptxt, const std::vector<cx_double>& array,
                double useThisSize, long precision=-1) const;
  double encode(zzX& ptxt, const std::vector<double>& array,
                double useThisSize, long precision=-1) const
  {
    std::vector<cx_double> tmp;
    convert(tmp, array);
    return encode(ptxt, tmp, useThisSize, precision);
  }
  double encode(zzX& ptxt, const std::vector<long>& array,
                double useThisSize, long precision=-1) const
  {
    std::vector<cx_double> tmp;
    convert(tmp, array);
    return encode(ptxt, tmp, useThisSize, precision);
  }
  double encode(zzX& ptxt, double aSingleNumber,
                double useThisSize=-1, long precision=-1) const;

  template<class PTXT>
  double encode(NTL::ZZX& ptxt, const PTXT& pt,
                double useThisSize=-1, long precision=-1) const
  { zzX tmp;
    double f = encode(tmp, pt, useThisSize, precision);
    ::convert(ptxt, tmp);
    return f;
  }

  void encryptOneNum(Ctxt& ctxt, const FHEPubKey& key, double num,
                     double useThisSize=-1, long precision=-1) const
  {
    //OLD: assert(&getContext() == &ctxt.getContext());
    helib::assertEq(&getContext(), &ctxt.getContext(), "Cannot decrypt when ciphertext has different context than EncryptedArray");
    if (useThisSize <= 0.0)
      useThisSize = roundedSize(num); // rounded to power of two
    zzX pp;  // Convert num into a plaintext polynomial
    double f = encode(pp, num, useThisSize, precision);

    key.CKKSencrypt(ctxt, pp, useThisSize, f); // encrypt resulting polynomial
  }

  template<class PTXT>
  void encrypt(Ctxt& ctxt, const FHEPubKey& key, const PTXT& ptxt,
               double useThisSize, long precision=-1) const
  {
    //OLD: assert(&getContext() == &ctxt.getContext());
    helib::assertEq(&getContext(), &ctxt.getContext(), "Cannot decrypt when ciphertext has different context than EncryptedArray");
    zzX pp;
    double f = encode(pp, ptxt, useThisSize, precision);
    // Convert into a polynomial
    key.CKKSencrypt(ctxt, pp, useThisSize, f); // encrypt the polynomial
  }
  
  template<class PTXT> void
  encrypt(Ctxt& ctxt, const FHEPubKey& key, const PTXT& ptxt) const
  { encrypt(ctxt, key, ptxt, -1.0, -1); }

  // The methods below override EncryptedArrayBase, they use
  // the default size=0 and precision=0, which yeild size=1
  // and precision=2^{-alMod.getR()-1}
  void encodeUnitSelector(zzX& ptxt, long i) const override {
    std::vector<cx_double> v(this->size(), cx_double(0.0));
    v.at(i) = cx_double(1.0, 0.0);
    encode(ptxt, v, /*size=*/1.0, /*default precision*/-1);
  } // The implicit scaling factor is encodeScalingFactor() below

  // A bound on the rounding error for encoding
  double encodeRoundingError() const {
    const FHEcontext& context = getContext();
    long m = context.zMStar.getM();
    return context.noiseBoundForUniform(0.5, m);
  }
  // The scaling factor to use when encoding/decoding plaintext elements
  long encodeScalingFactor(long precision=-1, double roundErr=-1.0) const {
    //OLD: assert(precision<NTL_SP_BOUND);
    helib::assertTrue<helib::InvalidArgument>(precision < NTL_SP_BOUND, "Precision exceeds max single precision bound");
    if (precision <= 0) precision=(1L<< alMod.getR());
    if (roundErr  <  0) roundErr = encodeRoundingError();
    long f = ceil(precision * roundErr);
    // We round the factor up to the next power of two
    return (1L<<NTL::NextPowerOfTwo(f));
  }

  void decode(std::vector<cx_double>& array,
              const zzX& ptxt, double scaling) const;

  void decode(std::vector<cx_double>& array,
              const NTL::ZZX& ptxt, double scaling) const
  { zzX tmp; ::convert(tmp, ptxt); decode(array, tmp, scaling); }

  void decode(std::vector<double>& array,
              const zzX& ptxt, double scaling) const
  { std::vector<cx_double> v; decode(v, ptxt, scaling); convert(array, v); }

  void decode(std::vector<double>& array,
              const NTL::ZZX& ptxt, double scaling) const
  { std::vector<cx_double> v; decode(v, ptxt, scaling); convert(array, v); }

  void random(std::vector<cx_double>& array, double rad=1.0) const;
  void random(std::vector<double>& array, double rad=1.0) const
  { std::vector<cx_double> v; random(v,rad); convert(array, v); }
  void random(std::vector<long>& array) const override
    { std::vector<cx_double> v; random(v,1.0); convert(array, v); }

  void decrypt(const Ctxt& ctxt,
               const FHESecKey& sKey, std::vector<cx_double>& ptxt) const override;
  void decrypt(const Ctxt& ctxt,
               const FHESecKey& sKey, std::vector<double>& ptxt) const override
  { std::vector<cx_double> v; decrypt(ctxt,sKey,v); convert(ptxt,v); }

  void extractRealPart(Ctxt& c) const;

  //! Note: If called with dcrt==nullptr, extractImPart will perform FFT's
  //! when encoding i as a DoubleCRT object. If called with dcrt!=nullptr,
  //! it assumes that dcrt points to an object that encodes i.
  void extractImPart(Ctxt& c, DoubleCRT* dcrt=nullptr) const;

  //! @name Linearized polynomials for EncryptedArrayCx
  ///@{
  //! buildLinPolyCoeffs returns in C two encoded constants such that the
  //! linear transformation(s) defined as L(1) = oneImage and L(i)=iImage
  //! can be computed as:      L(x) = C[0]*x + C[1]*conjugate(x).
  //! Once C is computed, we can apply this L to a cipehrtext by calling
  //! applyLinPolyLL(ctxt, C, 2).
  //! Alternatively, we can convert C to a vector of two DoubleCRT objects,
  //! then call applyLinPolyLL(ctxt, dcrtVec, 2). This lets us compute the
  //! DoubleCRT object just once, then use them many times.

  //! First variant: same linear transformation in all the slots
  double buildLinPolyCoeffs(std::vector<zzX>& C,
                            const cx_double& oneImage, const cx_double& iImage,
                            long precision=0) const;

  //! Second variant: different linear transformation in each slots
  double buildLinPolyCoeffs(std::vector<zzX>& C,
                            const std::vector<cx_double>&oneImages,
                            const std::vector<cx_double>&iImages,
                            long precision=0) const;
  ///@}
};


// plaintextAutomorph: Compute b(X) = a(X^k) mod Phi_m(X).
template <class RX, class RXModulus>
void plaintextAutomorph(RX& bb, const RX& a, long k, long m, const RXModulus& PhimX)
{
  // compute b(X) = a(X^k) mod (X^m-1)
  if (k == 1 || deg(a) <= 0) {
    bb = a;
    return;
  }

  RX b;
  b.SetLength(m);
  NTL::mulmod_precon_t precon = NTL::PrepMulModPrecon(k, m);
  for (long j = 0; j <= deg(a); j++) 
    b[NTL::MulModPrecon(j, k, m, precon)] = a[j]; // b[j*k mod m] = a[j]
  b.normalize();

  rem(bb, b, PhimX); // reduce modulo the m'th cyclotomic
}

// same as above, but k = g_i^j mod m.
// also works with i == ea.getPalgebra().numOfGens(),
// which means Frobenius

template<class RX, class type>
void plaintextAutomorph(RX& b, const RX& a, long i, long j, 
                        const EncryptedArrayDerived<type>& ea)
{
  const PAlgebra& zMStar = ea.getPAlgebra();
  const auto& F = ea.getTab().getPhimXMod();
  long k = zMStar.genToPow(i, j);
  long m = zMStar.getM();
  plaintextAutomorph(b, a, k, m, F);
}


//! @brief A "factory" for building EncryptedArrays
EncryptedArrayBase*
buildEncryptedArray(const FHEcontext& context, const PAlgebraMod& alMod,
                    const NTL::ZZX& G=NTL::ZZX::zero());

//! @class EncryptedArray
//! @brief A simple wrapper for a smart pointer to an EncryptedArrayBase.
//! This is the interface that higher-level code should use
class EncryptedArray {
private:
  const PAlgebraMod& alMod;
  cloned_ptr<EncryptedArrayBase> rep;

public:

  //! constructor: G defaults to the monomial X, PAlgebraMod from context
  EncryptedArray(const FHEcontext& context, const NTL::ZZX& G = NTL::ZZX(1, 1))
    : alMod(context.alMod), rep(buildEncryptedArray(context,context.alMod,G))
  { }
  //! constructor: G defaults to F0, PAlgebraMod explicitly given
  EncryptedArray(const FHEcontext& context, const PAlgebraMod& _alMod)
    : alMod(_alMod), rep(buildEncryptedArray(context,_alMod))
  { }

  // copy constructor: 

  EncryptedArray& operator=(const EncryptedArray& other) {
    if (this == &other) return *this;
    //OLD: assert(&alMod== &other.alMod);
    helib::assertEq(&alMod, &other.alMod, "Cannot assign EncryptedArrays with different algebras");
    rep = other.rep;
    return *this;
  }

  //! @brief downcast operator
  //! example: const EncryptedArrayDerived<PA_GF2>& rep = ea.getDerived(PA_GF2());
  template<class type> 
  const EncryptedArrayDerived<type>& getDerived(type) const
  { return dynamic_cast< const EncryptedArrayDerived<type>& >( *rep ); }

  const EncryptedArrayCx& getCx() const
  { return dynamic_cast<const EncryptedArrayCx&>( *rep ); }

  ///@{
  //! @name Direct access to EncryptedArrayBase methods

  PA_tag getTag() const { return rep->getTag(); }

  template<template <class> class T, class... Args>
  void dispatch(Args&&... args) const
  {
    switch (getTag()) {
      case PA_GF2_tag: {
        const EncryptedArrayDerived<PA_GF2> *p = 
          static_cast< const EncryptedArrayDerived<PA_GF2> *>(rep.get_ptr());
        p->dispatch<T>(std::forward<Args>(args)...);
        break;
      }
      case PA_zz_p_tag: {
        const EncryptedArrayDerived<PA_zz_p> *p = 
          static_cast< const EncryptedArrayDerived<PA_zz_p> *>(rep.get_ptr());
        p->dispatch<T>(std::forward<Args>(args)...);
        break;
      }
      default: throw helib::RuntimeError("EncryptedArray: bad tag");
    }
  }



  const FHEcontext& getContext() const { return rep->getContext(); }
  const PAlgebraMod& getAlMod() const { return alMod; }
  const PAlgebra& getPAlgebra() const { return rep->getPAlgebra(); }
  const long getDegree() const { return rep->getDegree(); }
  void rotate(Ctxt& ctxt, long k) const { rep->rotate(ctxt, k); }
  void shift(Ctxt& ctxt, long k) const { rep->shift(ctxt, k); }
  void rotate1D(Ctxt& ctxt, long i, long k, bool dc=false) const { rep->rotate1D(ctxt, i, k, dc); }
  void shift1D(Ctxt& ctxt, long i, long k) const { rep->shift1D(ctxt, i, k); }

  template<class PTXT, class ARRAY>
  void encode(PTXT& ptxt, const ARRAY& array) const 
    { rep->encode(ptxt, array); }

  void encodeUnitSelector(zzX& ptxt, long i) const
    { rep->encodeUnitSelector(ptxt, i); }

  template<class PTXT, class ARRAY>
  void decode(ARRAY& array, const PTXT& ptxt) const 
    { rep->decode(array, ptxt); }

  template<class T>
  void random(std::vector< T >& array) const
    { rep->random(array); }

  template<class T>
  void encrypt(Ctxt& ctxt, const FHEPubKey& pKey, const T& ptxt) const 
    { rep->encrypt(ctxt, pKey, ptxt); }

  template<class T>
  void decrypt(const Ctxt& ctxt, const FHESecKey& sKey, T& ptxt) const 
    { rep->decrypt(ctxt, sKey, ptxt); }

  void buildLinPolyCoeffs(std::vector<NTL::ZZX>& C, const std::vector<NTL::ZZX>& L) const
    { rep->buildLinPolyCoeffs(C, L); }

  void restoreContext() const { rep->restoreContext(); }
  void restoreContextForG() const { rep->restoreContextForG(); }

  long size() const { return rep->size(); } 
  long dimension() const { return rep->dimension(); }
  long sizeOfDimension(long i) const { return rep->sizeOfDimension(i); }
  long nativeDimension(long i) const {return rep->nativeDimension(i); }
  long coordinate(long i, long k) const { return rep->coordinate(i, k); }
  long addCoord(long i, long k, long offset) const { return rep->addCoord(i, k, offset); }


  //! @brief rotate an array by offset in the i'th dimension
  //! (output should not alias input)
  template<class U> void rotate1D(std::vector<U>& out, const std::vector<U>& in,
                                  long i, long offset) const {
    rep->rotate1D(out, in, i, offset);
  }
  ///@}
};



// NewPlaintaxtArray

class PlaintextArrayBase { // purely abstract interface
public:
  virtual ~PlaintextArrayBase() {}
  virtual void print(std::ostream& s) const = 0;
};


template<class type> class PlaintextArrayDerived : public PlaintextArrayBase {
public:
  PA_INJECT(type)

  std::vector< RX > data;

  virtual void print(std::ostream& s) const { s << data; }

};


class PlaintextArray {
private:

  NTL::CloneablePtr<PlaintextArrayBase> rep;

  template<class type>
  class ConstructorImpl {
  public:
    PA_INJECT(type)

    static void apply(const EncryptedArrayDerived<type>& ea, PlaintextArray& pa)
    {
      NTL::CloneablePtr< PlaintextArrayDerived<type> > ptr =
         NTL::MakeCloneable< PlaintextArrayDerived<type> >();
      ptr->data.resize(ea.size());
      pa.rep = ptr;
    }
  };

public:
  
  PlaintextArray(const EncryptedArray& ea)  
    { ea.dispatch<ConstructorImpl>(*this); }

  PlaintextArray(const PlaintextArray& other) : rep(other.rep.clone()) { }
  PlaintextArray& operator=(const PlaintextArray& other) 
    { rep = other.rep.clone(); return *this; }

  template<class type>
    std::vector<typename type::RX>& getData() 
    { return (dynamic_cast< PlaintextArrayDerived<type>& >(*rep)).data; }


  template<class type>
    const std::vector<typename type::RX>& getData() const
    { return (dynamic_cast< PlaintextArrayDerived<type>& >(*rep)).data; }


  void print(std::ostream& s) const { rep->print(s); }

};

inline 
std::ostream& operator<<(std::ostream& s, const PlaintextArray& pa)
{  pa.print(s); return s; }


void rotate(const EncryptedArray& ea, PlaintextArray& pa, long k);
void shift(const EncryptedArray& ea, PlaintextArray& pa, long k);

void encode(const EncryptedArray& ea, PlaintextArray& pa, const std::vector<long>& array);
void encode(const EncryptedArray& ea, PlaintextArray& pa, const std::vector<NTL::ZZX>& array);
void encode(const EncryptedArray& ea, PlaintextArray& pa, long val);
void encode(const EncryptedArray& ea, PlaintextArray& pa, const NTL::ZZX& val);

void random(const EncryptedArray& ea, PlaintextArray& pa);

void decode(const EncryptedArray& ea, std::vector<long>& array, const PlaintextArray& pa);
void decode(const EncryptedArray& ea, std::vector<NTL::ZZX>& array, const PlaintextArray& pa);

bool equals(const EncryptedArray& ea, const PlaintextArray& pa, const PlaintextArray& other);
bool equals(const EncryptedArray& ea, const PlaintextArray& pa, const std::vector<long>& other);
bool equals(const EncryptedArray& ea, const PlaintextArray& pa, const std::vector<NTL::ZZX>& other);

void add(const EncryptedArray& ea, PlaintextArray& pa, const PlaintextArray& other);
void sub(const EncryptedArray& ea, PlaintextArray& pa, const PlaintextArray& other);
void mul(const EncryptedArray& ea, PlaintextArray& pa, const PlaintextArray& other);
void negate(const EncryptedArray& ea, PlaintextArray& pa);


void frobeniusAutomorph(const EncryptedArray& ea, PlaintextArray& pa, long j);
void frobeniusAutomorph(const EncryptedArray& ea, PlaintextArray& pa, const NTL::Vec<long>& vec);

void applyPerm(const EncryptedArray& ea, PlaintextArray& pa, const NTL::Vec<long>& pi);

void power(const EncryptedArray& ea, PlaintextArray& pa, long e);




// Following are functions for performing "higher level"
// operations on "encrypted arrays".  There is really no
// reason for these to be members of the EncryptedArray class,
// so they are just declared as separate functions.

//! @brief A ctxt that encrypts \f$(x_1, ..., x_n)\f$ is replaced by an
//! encryption of \f$(y_1, ..., y_n)\f$, where \f$y_i = sum_{j\le i} x_j\f$.
void runningSums(const EncryptedArray& ea, Ctxt& ctxt);
// The implementation uses O(log n) shift operations.


//! @brief A ctxt that encrypts \f$(x_1, ..., x_n)\f$ is replaced by an
//! encryption of \f$(y, ..., y)\$, where \f$y = sum_{j=1}^n x_j.\f$
void totalSums(const EncryptedArray& ea, Ctxt& ctxt);


//! @brief Map all non-zero slots to 1, leaving zero slots as zero.
//! Assumes that r=1, and that all the slots contain elements from GF(p^d).
void mapTo01(const EncryptedArray& ea, Ctxt& ctxt);
// Implemented in eqtesting.cpp. We compute
//             x^{p^d-1} = x^{(1+p+...+p^{d-1})*(p-1)}
// by setting y=x^{p-1} and then outputting y * y^p * ... * y^{p^{d-1}},
// with exponentiation to powers of p done via Frobenius.


//! @brief (only for p=2, r=1), test if prefixes of bits in slots are all zero.
//! Set slot j of res[i] to 0 if bits 0..i of j'th slot in ctxt are all zero,
//! else sets slot j of res[i] to 1.
//! It is assumed that res and the res[i]'s are initialized by the caller.
void incrementalZeroTest(Ctxt* res[], const EncryptedArray& ea,
			 const Ctxt& ctxt, long n);
// Complexity: O(d + n log d) smart automorphisms
//             O(n d) 

/*************** End linear transformation functions ****************/
/********************************************************************/

///@{
/**
 * @name Apply linearized polynomials to a ciphertext.
 *
 * Example usage: The map L selects just the even coefficients
 * \code
 *     long d = ea.getDegree();
 *     std::vector<ZZX> L(d);
 *     for (long j = 0; j < d; j++)
 *       if (j % 2 == 0) L[j] = ZZX(j, 1);
 *
 *     std::vector<ZZX> C;
 *     ea.buildLinPolyCoeffs(C, L); 
 *     applyLinPoly1(ea, ctxt, C);
 * \endcode
 */

//! @brief Apply the same linear transformation to all the slots
//! @param C is the output of ea.buildLinPolyCoeffs;
void applyLinPoly1(const EncryptedArray& ea, Ctxt& ctxt, const std::vector<NTL::ZZX>& C);

//! @brief Apply different transformations to different slots
//! @param Cvec is a std::vector of length ea.size(), each entry of which
//!        is the output of ea.buildLinPolyCoeffs; 
void applyLinPolyMany(const EncryptedArray& ea, Ctxt& ctxt, 
                      const std::vector< std::vector<NTL::ZZX> >& Cvec);

//! @brief a low-level variant:
//! @param encodedCoeffs has all the linPoly coeffs encoded  in slots;
//!        different transformations can be encoded in different slots
template<class P>  // P can be ZZX or DoubleCRT
void applyLinPolyLL(Ctxt& ctxt, const std::vector<P>& encodedC, long d);
///@}

#endif // ifndef HELIB_ENCRYPTEDARRAY_H
