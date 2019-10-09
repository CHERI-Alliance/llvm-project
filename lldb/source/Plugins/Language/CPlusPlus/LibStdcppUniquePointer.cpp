//===-- LibStdcppUniquePointer.cpp ------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "LibStdcpp.h"

#include "lldb/Core/ValueObject.h"
#include "lldb/DataFormatters/FormattersHelpers.h"
#include "lldb/DataFormatters/TypeSynthetic.h"
#include "lldb/Utility/ConstString.h"

#include <memory>
#include <vector>

using namespace lldb;
using namespace lldb_private;
using namespace lldb_private::formatters;

namespace {

class LibStdcppUniquePtrSyntheticFrontEnd : public SyntheticChildrenFrontEnd {
public:
  explicit LibStdcppUniquePtrSyntheticFrontEnd(lldb::ValueObjectSP valobj_sp);

  size_t CalculateNumChildren() override;

  lldb::ValueObjectSP GetChildAtIndex(size_t idx) override;

  bool Update() override;

  bool MightHaveChildren() override;

  size_t GetIndexOfChildWithName(ConstString name) override;

  bool GetSummary(Stream &stream, const TypeSummaryOptions &options);

private:
  // The lifetime of a ValueObject and all its derivative ValueObjects
  // (children, clones, etc.) is managed by a ClusterManager. These
  // objects are only destroyed when every shared pointer to any of them
  // is destroyed, so we must not store a shared pointer to any ValueObject
  // derived from our backend ValueObject (since we're in the same cluster).
  ValueObject* m_ptr_obj = nullptr;
  ValueObject* m_obj_obj = nullptr;
  ValueObject* m_del_obj = nullptr;

  ValueObjectSP GetTuple();
};

} // end of anonymous namespace

LibStdcppUniquePtrSyntheticFrontEnd::LibStdcppUniquePtrSyntheticFrontEnd(
    lldb::ValueObjectSP valobj_sp)
    : SyntheticChildrenFrontEnd(*valobj_sp) {
  Update();
}

ValueObjectSP LibStdcppUniquePtrSyntheticFrontEnd::GetTuple() {
  ValueObjectSP valobj_backend_sp = m_backend.GetSP();

  if (!valobj_backend_sp)
    return nullptr;

  ValueObjectSP valobj_sp = valobj_backend_sp->GetNonSyntheticValue();
  if (!valobj_sp)
    return nullptr;

  ValueObjectSP obj_child_sp =
      valobj_sp->GetChildMemberWithName(ConstString("_M_t"), true);
  if (!obj_child_sp)
      return nullptr;

  ValueObjectSP obj_subchild_sp =
      obj_child_sp->GetChildMemberWithName(ConstString("_M_t"), true);

  // if there is a _M_t subchild, the tuple is found in the obj_subchild_sp
  // (for libstdc++ 6.0.23).
  if (obj_subchild_sp) {
    return obj_subchild_sp;
  }

  return obj_child_sp;
}

bool LibStdcppUniquePtrSyntheticFrontEnd::Update() {
  ValueObjectSP tuple_sp = GetTuple();

  if (!tuple_sp)
    return false;

  std::unique_ptr<SyntheticChildrenFrontEnd> tuple_frontend(
      LibStdcppTupleSyntheticFrontEndCreator(nullptr, tuple_sp));

  ValueObjectSP ptr_obj = tuple_frontend->GetChildAtIndex(0);
  if (ptr_obj)
    m_ptr_obj = ptr_obj->Clone(ConstString("pointer")).get();

  ValueObjectSP del_obj = tuple_frontend->GetChildAtIndex(1);
  if (del_obj)
    m_del_obj = del_obj->Clone(ConstString("deleter")).get();

  if (m_ptr_obj) {
    Status error;
    ValueObjectSP obj_obj = m_ptr_obj->Dereference(error);
    if (error.Success()) {
      m_obj_obj = obj_obj->Clone(ConstString("object")).get();
    }
  }

  return false;
}

bool LibStdcppUniquePtrSyntheticFrontEnd::MightHaveChildren() { return true; }

lldb::ValueObjectSP
LibStdcppUniquePtrSyntheticFrontEnd::GetChildAtIndex(size_t idx) {
  if (idx == 0)
    return m_ptr_obj->GetSP();
  if (idx == 1)
    return m_del_obj->GetSP();
  if (idx == 2)
    return m_obj_obj->GetSP();
  return lldb::ValueObjectSP();
}

size_t LibStdcppUniquePtrSyntheticFrontEnd::CalculateNumChildren() {
  if (m_del_obj)
    return 2;
  return 1;
}

size_t LibStdcppUniquePtrSyntheticFrontEnd::GetIndexOfChildWithName(
    ConstString name) {
  if (name == "ptr" || name == "pointer")
    return 0;
  if (name == "del" || name == "deleter")
    return 1;
  if (name == "obj" || name == "object" || name == "$$dereference$$")
    return 2;
  return UINT32_MAX;
}

bool LibStdcppUniquePtrSyntheticFrontEnd::GetSummary(
    Stream &stream, const TypeSummaryOptions &options) {
  if (!m_ptr_obj)
    return false;

  bool success;
  uint64_t ptr_value = m_ptr_obj->GetValueAsUnsigned(0, &success);
  if (!success)
    return false;
  if (ptr_value == 0)
    stream.Printf("nullptr");
  else
    stream.Printf("0x%" PRIx64, ptr_value);
  return true;
}

SyntheticChildrenFrontEnd *
lldb_private::formatters::LibStdcppUniquePtrSyntheticFrontEndCreator(
    CXXSyntheticChildren *, lldb::ValueObjectSP valobj_sp) {
  return (valobj_sp ? new LibStdcppUniquePtrSyntheticFrontEnd(valobj_sp)
                    : nullptr);
}

bool lldb_private::formatters::LibStdcppUniquePointerSummaryProvider(
    ValueObject &valobj, Stream &stream, const TypeSummaryOptions &options) {
  LibStdcppUniquePtrSyntheticFrontEnd formatter(valobj.GetSP());
  return formatter.GetSummary(stream, options);
}
