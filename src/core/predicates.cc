/*
    File: predicates.cc
*/

/*
Copyright (c) 2014, Christian E. Schafmeister

CLASP is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

See directory 'clasp/licenses' for full details.

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
/* -^- */
//#define DEBUG_LEVEL_FULL

#include <clasp/core/foundation.h>
#include <clasp/core/object.h>
#include <clasp/core/lispList.h>
#include <clasp/core/metaClass.h>
#include <clasp/core/array.h>
#include <clasp/core/package.h>
#include <clasp/core/bignum.h>
#include <clasp/core/closPackage.h>
#include <clasp/core/pathname.h>
#include <clasp/core/hashTable.h>
#include <clasp/core/random.h>
#include <clasp/core/instance.h>
#include <clasp/core/funcallableInstance.h>
#include <clasp/core/readtable.h>
#include <clasp/core/lambdaListHandler.h>
#include <clasp/core/singleDispatchGenericFunction.h>
#include <clasp/core/numbers.h>
#include <clasp/core/evaluator.h>
#include <clasp/core/externalObject.h>
#include <clasp/core/lispStream.h>
#include <clasp/core/fileSystem.h>
#include <clasp/core/wrappers.h>

namespace core {

CL_DEFUN bool core__generalp(T_sp obj) {
  return gc::IsA<General_sp>(obj);
}

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(baseCharP)doc")
CL_DEFUN bool core__base_char_p(T_sp arg) {
  return (arg.characterp()&&clasp_base_char_p(arg.unsafe_character()));
};

CL_DEFUN bool core__bignump(T_sp obj) {
  return gc::IsA<Bignum_sp>(obj);
}

// XXX: this should be adjusted whenever unicode is implemented
CL_DEFUN bool core__base_string_p(T_sp obj) {
  return gc::IsA<Str8Ns_sp>(obj) || gc::IsA<SimpleBaseString_sp>(obj);
};

CL_DEFUN bool cl__stringp(T_sp obj) {
  return gc::IsA<SimpleString_sp>(obj) || gc::IsA<StrNs_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(Return true if argument is a simple-string)doc")
CL_DEFUN bool cl__simple_string_p(T_sp obj) {
  return gc::IsA<SimpleString_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(Return true if argument is a simple-string)doc")
CL_DEFUN bool core__extended_string_p(T_sp obj) {
  return gc::IsA<SimpleCharacterString_sp>(obj)||gc::IsA<StrWNs_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(doubleFloatP)doc")
CL_DEFUN bool core__double_float_p(T_sp obj) {
  return gc::IsA<DoubleFloat_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(functionP)doc")
CL_DEFUN bool cl__functionp(T_sp obj) {
  return gc::IsA<Function_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(interpretedFunctionP)doc")
CL_DEFUN bool core__interpreted_function_p(T_sp arg) {
  if ( gc::IsA<ClosureWithSlots_sp>(arg)){
    ClosureWithSlots_sp closure = gc::As_unsafe<ClosureWithSlots_sp>(arg);
    return closure->closureType == ClosureWithSlots_O::interpretedClosure;
  }
  return false;
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(See CLHS packagep)doc")
CL_DEFUN bool cl__packagep(T_sp obj) {
  return gc::IsA<Package_sp>(obj);
};

CL_DEFUN bool clos__classp(T_sp obj) {
  if (gc::IsA<Instance_sp>(obj)) {
    Instance_sp iobj = gc::As_unsafe<Instance_sp>(obj);
    if (iobj->_Class == _lisp->_Roots._TheStandardClass
        || iobj->_Class == _lisp->_Roots._TheClass
        || iobj->_Class == _lisp->_Roots._TheBuiltInClass
        || iobj->_Class == _lisp->_Roots._TheStructureClass
        || iobj->_Class == _lisp->_Roots._TheClbindCxxClass
        || iobj->_Class == _lisp->_Roots._TheDerivableCxxClass ) return true;
    return core__subclassp(iobj->_Class,_lisp->_Roots._TheClass);
  }
  return false;
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(Predicate for the object being an Instance (C++ class used for standard-object etc))doc")
CL_DEFUN bool core__instancep(T_sp obj) {
  return gc::IsA<Instance_sp>(obj) || gc::IsA<FuncallableInstance_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(lambda_list_handler_p)doc")
CL_DEFUN bool core__lambda_list_handler_p(T_sp obj) {
  return gc::IsA<LambdaListHandler_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(numberP)doc")
CL_DEFUN bool cl__numberp(T_sp obj) {
  return obj.fixnump()||obj.single_floatp()||gc::IsA<Number_sp>(obj);
};

CL_DEFUN bool cl__complexp(T_sp obj) {
  return gc::IsA<Complex_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(ratioP)doc")
CL_DEFUN bool core__ratio_p(T_sp obj) {
  return gc::IsA<Ratio_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(ratioP)doc")
CL_DEFUN bool cl__random_state_p(T_sp obj) {
  return gc::IsA<RandomState_sp>(obj);
};

CL_DEFUN bool core__source_pos_info_p(T_sp obj) {
  return gc::IsA<SourcePosInfo_sp>(obj);
};

CL_DEFUN bool cl__rationalp(T_sp obj) {
  return obj.fixnump()||gc::IsA<Rational_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(longFloatP)doc")
CL_DEFUN bool core__long_float_p(T_sp obj) {
  return gc::IsA<LongFloat_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(shortFloatP)doc")
CL_DEFUN bool core__short_float_p(T_sp obj) {
  return gc::IsA<ShortFloat_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(singleFloatP)doc")
CL_DEFUN bool core__single_float_p(T_sp obj) {
  return obj.single_floatp();
};

CL_DEFUN bool cl__realp(T_sp obj) {
  return obj.fixnump()||obj.single_floatp()||gc::IsA<Real_sp>(obj);
};

CL_DEFUN bool cl__floatp(T_sp obj) {
  return obj.single_floatp()||gc::IsA<Float_sp>(obj);
};

CL_DEFUN bool cl__vectorp(T_sp obj) {
  return gc::IsA<AbstractSimpleVector_sp>(obj)
    || (gc::IsA<MDArray_sp>(obj)&&gc::As_unsafe<MDArray_sp>(obj)->rank()==1);
};

CL_DEFUN bool cl__integerp(T_sp obj) {
  return gc::IsA<Integer_sp>(obj);
};

CL_DEFUN bool cl__keywordp(T_sp obj) {
  if (Symbol_sp s = obj.asOrNull<Symbol_O>()) {
    return s->isKeywordSymbol();
  }
  return false;
};


CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(bitVectorP)doc")
CL_DEFUN bool cl__bit_vector_p(T_sp obj) {
  return gc::IsA<SimpleBitVector_sp>(obj)||gc::IsA<BitVector_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(hashTableP)doc")
CL_DEFUN bool cl__hash_table_p(T_sp obj) {
  if (gc::IsA<HashTable_sp>(obj)) {
    return true;
  }
  return false;
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(readtablep)doc")
CL_DEFUN bool cl__readtablep(T_sp obj) {
  if (gc::IsA<Readtable_sp>(obj)) return true;
  T_sp result =  eval::funcall(eclector_readtable::_sym_readtablep,obj);
  return result.notnilp();
};

CL_DEFUN bool core__arrayp(T_sp obj) {
  return gc::IsA<Array_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(singleDispatchGenericFunctionP)doc")
CL_DEFUN bool core__single_dispatch_generic_function_p(T_sp obj) {
  return gc::IsA<SingleDispatchGenericFunctionClosure_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(activation_frame_p)doc")
CL_DEFUN bool core__activation_frame_p(T_sp obj) {
  return gc::IsA<ActivationFrame_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(externalObjectP)doc")
CL_DEFUN bool core__external_object_p(T_sp obj) {
  return gc::IsA<ExternalObject_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(simple_bit_vector_p)doc")
CL_DEFUN bool cl__simple_bit_vector_p(T_sp o) {
  return gc::IsA<SimpleBitVector_sp>(o);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(simple_vector_p)doc")
CL_DEFUN bool cl__simple_vector_p(T_sp o) {
  return gc::IsA<SimpleVector_sp>(o);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(compiled_function_p)doc")
CL_DEFUN bool cl__compiled_function_p(T_sp o) {
  if (Closure_sp fn = o.asOrNull<Closure_O>()) {
    return fn->compiledP();
  } else if (gc::IsA<FuncallableInstance_sp>(o)) {
    return true;
  }
  return false;
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(Return true if arg is a proper list)doc")
CL_DEFUN bool core__proper_list_p(T_sp arg) {
  T_sp fast, slow;
  bool test = true;
  fast = slow = arg;
  for (int n = 0; !fast.nilp(); n++, fast = oCdr(fast)) {
    if (!cl__listp(fast)) {
      test = false;
      break;
    }
    if (n & 1) {
      /* Circular list? */
      if (slow == fast) {
        test = false;
        break;
      }
      slow = oCdr(slow);
    }
  }
  return test;
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(global-entry-point-generator-p)doc")
CL_DEFUN bool core__global_entry_point_generator_p(T_sp obj) {
  return gc::IsA<GlobalEntryPointGenerator_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(local-entry-point-generator-p)doc")
CL_DEFUN bool core__local_entry_point_generator_p(T_sp obj) {
  return gc::IsA<LocalEntryPointGenerator_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(function-description-p)doc")
CL_DEFUN bool core__function_description_p(T_sp obj) {
  return gc::IsA<FunctionDescription_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(pathnamep)doc")
CL_DEFUN bool cl__pathnamep(T_sp obj) {
  return gc::IsA<Pathname_sp>(obj);
};

CL_LAMBDA(arg);
CL_DECLARE();
CL_DOCSTRING(R"doc(logicalPathnameP)doc")
CL_DEFUN bool core__logical_pathname_p(T_sp obj) {
  return gc::IsA<LogicalPathname_sp>(obj);
};



  SYMBOL_EXPORT_SC_(ClosPkg, classp);
};


namespace ext {
CL_NAME("EXT:LOCAL-FUNCTION-FORM-P");
CL_DEFUN bool local_function_form_p(core::T_sp form)
{
  return ((form).consp() &&
          (core::oCar(gc::As<core::Cons_sp>(form)) == cl::_sym_flet ||
           core::oCar(gc::As<core::Cons_sp>(form)) == cl::_sym_labels ));
}


};

namespace core {

CL_DEFUN bool core__cxxObjectP(T_sp obj)
{
  return gc::IsA<CxxObject_sp>(obj);
}
};
