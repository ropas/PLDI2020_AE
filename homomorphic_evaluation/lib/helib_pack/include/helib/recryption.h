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
#ifndef HELIB_RECRYPTION_H
#define HELIB_RECRYPTION_H
/** @file recryption.h
 *  @brief Define some data structures to hold recryption data
 */

#include "NumbTh.h"

extern long thinRecrypt_initial_level;

class  PAlgebraMod;
class  EncryptedArray;
class  EvalMap;
class  ThinEvalMap;
class  PowerfulDCRT;
class  FHEcontext;
class  FHEPubKey;


//! @class RecryptData
//! @brief A structure to hold recryption-related data inside the FHEcontext
class RecryptData {
public:
  //! default Hamming weight of recryption key
  static constexpr long defSkHwt=100;

  //! Some data members that are only used for I/O
  NTL::Vec<long> mvec;     //! partition of m into co-prime factors

  //! skey encrypted wrt space p^{e-e'+r}
  long e, ePrime;

  //! Hamming weight of recryption secret key
  long skHwt;

  //! an optimization parameter
  long a;

  //! for plaintext space p^{e-e'+r}
  PAlgebraMod *alMod;

  //! for plaintext space p^{e-e'+r}
  EncryptedArray *ea;

  bool build_cache;


  //! linear maps
  EvalMap *firstMap, *secondMap;

  //! conversion between ZZX and Powerful
  PowerfulDCRT *p2dConv;

  //! linPolys for uppacking the slots
  std::vector<NTL::ZZX> unpackSlotEncoding;

  RecryptData() {
    skHwt=0; e=ePrime=0; a=0;
    alMod=NULL; ea=NULL; firstMap=NULL; secondMap=NULL; p2dConv=NULL;
    build_cache = false;
  }
  ~RecryptData();

  //! Initialize the recryption data in the context
  void init(const FHEcontext& context, const NTL::Vec<long>& mvec_,
            bool enableThick,/*init linear transforms for non-thin*/
            long t=0/*min Hwt for sk*/,            
            bool build_cache=false,
            bool minimal=false);

  bool operator==(const RecryptData& other) const;
  bool operator!=(const RecryptData& other) const {
    return !(operator==(other));
  }

  //! Helper function for computing the recryption parameters
  static long setAE(long& a, long& e, long& ePrime,
                    const FHEcontext& context, long t=0);
  /**
   * Fix the "ring constant" cM, a target norm s for the secret key,
   * and plaintext space mod p^r. We want to find e,e' that minimize
   * e-e', subject to the constraint
   *
   *    (1) (p^{e'}/2 + 2*p^r+1)(s+1)*cM <= (q-1)/2  = p^e/2
   *
   * Note that as we let e,e' tend to infinity the constraint above
   * degenerates to (s+1)*cM < p^{e-e'}, so the smallest value
   * of e-e' that we can hope for is
   *
   *    (2) e-e' = 1 + floor( log_p( (s+1)*cM) )
   *
   * The setAE procedure tries to minimize e-e' subject to (1), and
   * in addition subject to the constraint that e is "not too big".
   * Specifically, it tries to ensure p^e<2^{30}, and failing that it
   * uses the smallest e for which (2*p^r+1)(s+1)*cM*2 <= p^e, and the
   * largest e' for that value of e.
   *
   * Once e,e' are set, it splits p^{e'}/2=a+b with a,b about equal and
   * a divisible by p^r. Then it computes and returns the largest Hamming
   * weight for the key (that implies the norm s') for which constraint
   * (1) still holds.
   * NOTE: setAE returns the Hamming weight, *not* the norm s'. The norm
   * can be computed from the weight using sampleHWtBoundedEffectiveBound.
   **/
};


//! @class ThinRecryptData
//! @brief Same as above, but for "thin" bootstrapping, where the slots 
//! are assumed to contain constants
class ThinRecryptData : public RecryptData {
public:
  //! linear maps
  ThinEvalMap *coeffToSlot, *slotToCoeff;

  ThinRecryptData() : RecryptData() {coeffToSlot=NULL; slotToCoeff=NULL;}
  ~ThinRecryptData();

  //! Initialize the recryption data in the context
  void init(const FHEcontext& context, const NTL::Vec<long>& mvec_,
            bool alsoThick,/*init linear transforms also for non-thin*/
            long t=0/*min Hwt for sk*/, 
            bool build_cache=false,
            bool minimal=false);
};


#endif // HELIB_RECRYPTION_H
