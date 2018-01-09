//===- VPlan.h - Represent A Vectorizer Plan --------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
/// \file
/// This file contains the declarations of the Vectorization Plan base classes:
/// 1. VPBasicBlock and VPRegionBlock that inherit from a common pure virtual
///    VPBlockBase, together implementing a Hierarchical CFG;
/// 2. Specializations of GraphTraits that allow VPBlockBase graphs to be
///    treated as proper graphs for generic algorithms;
/// 3. Pure virtual VPRecipeBase serving as the base class for recipes contained
///    within VPBasicBlocks;
/// 4. VPInstruction, a concrete Recipe and VPUser modeling a single planned
///    instruction;
/// 5. The VPlan class holding a candidate for vectorization;
/// 6. The VPlanPrinter class providing a way to print a plan in dot format;
/// These are documented in docs/VectorizationPlan.rst.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_TRANSFORMS_VECTORIZE_VPLAN_H
#define LLVM_TRANSFORMS_VECTORIZE_VPLAN_H

#include "VPlanValue.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/GraphTraits.h"
#include "llvm/ADT/Optional.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/Twine.h"
#include "llvm/ADT/ilist.h"
#include "llvm/ADT/ilist_node.h"
#include "llvm/IR/IRBuilder.h"
#include <algorithm>
#include <cassert>
#include <cstddef>
#include <map>
#include <string>

// The (re)use of existing LoopVectorize classes is subject to future VPlan
// refactoring.
namespace {
class LoopVectorizationLegality;
class LoopVectorizationCostModel;
} // namespace

namespace llvm {

class BasicBlock;
class DominatorTree;
class InnerLoopVectorizer;
class LoopInfo;
class raw_ostream;
class Value;
class VPBasicBlock;
class VPRegionBlock;

/// In what follows, the term "input IR" refers to code that is fed into the
/// vectorizer whereas the term "output IR" refers to code that is generated by
/// the vectorizer.

/// VPIteration represents a single point in the iteration space of the output
/// (vectorized and/or unrolled) IR loop.
struct VPIteration {
  /// in [0..UF)
  unsigned Part;

  /// in [0..VF)
  unsigned Lane;
};

/// This is a helper struct for maintaining vectorization state. It's used for
/// mapping values from the original loop to their corresponding values in
/// the new loop. Two mappings are maintained: one for vectorized values and
/// one for scalarized values. Vectorized values are represented with UF
/// vector values in the new loop, and scalarized values are represented with
/// UF x VF scalar values in the new loop. UF and VF are the unroll and
/// vectorization factors, respectively.
///
/// Entries can be added to either map with setVectorValue and setScalarValue,
/// which assert that an entry was not already added before. If an entry is to
/// replace an existing one, call resetVectorValue and resetScalarValue. This is
/// currently needed to modify the mapped values during "fix-up" operations that
/// occur once the first phase of widening is complete. These operations include
/// type truncation and the second phase of recurrence widening.
///
/// Entries from either map can be retrieved using the getVectorValue and
/// getScalarValue functions, which assert that the desired value exists.
struct VectorizerValueMap {
  friend struct VPTransformState;

private:
  /// The unroll factor. Each entry in the vector map contains UF vector values.
  unsigned UF;

  /// The vectorization factor. Each entry in the scalar map contains UF x VF
  /// scalar values.
  unsigned VF;

  /// The vector and scalar map storage. We use std::map and not DenseMap
  /// because insertions to DenseMap invalidate its iterators.
  using VectorParts = SmallVector<Value *, 2>;
  using ScalarParts = SmallVector<SmallVector<Value *, 4>, 2>;
  std::map<Value *, VectorParts> VectorMapStorage;
  std::map<Value *, ScalarParts> ScalarMapStorage;

public:
  /// Construct an empty map with the given unroll and vectorization factors.
  VectorizerValueMap(unsigned UF, unsigned VF) : UF(UF), VF(VF) {}

  /// \return True if the map has any vector entry for \p Key.
  bool hasAnyVectorValue(Value *Key) const {
    return VectorMapStorage.count(Key);
  }

  /// \return True if the map has a vector entry for \p Key and \p Part.
  bool hasVectorValue(Value *Key, unsigned Part) const {
    assert(Part < UF && "Queried Vector Part is too large.");
    if (!hasAnyVectorValue(Key))
      return false;
    const VectorParts &Entry = VectorMapStorage.find(Key)->second;
    assert(Entry.size() == UF && "VectorParts has wrong dimensions.");
    return Entry[Part] != nullptr;
  }

  /// \return True if the map has any scalar entry for \p Key.
  bool hasAnyScalarValue(Value *Key) const {
    return ScalarMapStorage.count(Key);
  }

  /// \return True if the map has a scalar entry for \p Key and \p Instance.
  bool hasScalarValue(Value *Key, const VPIteration &Instance) const {
    assert(Instance.Part < UF && "Queried Scalar Part is too large.");
    assert(Instance.Lane < VF && "Queried Scalar Lane is too large.");
    if (!hasAnyScalarValue(Key))
      return false;
    const ScalarParts &Entry = ScalarMapStorage.find(Key)->second;
    assert(Entry.size() == UF && "ScalarParts has wrong dimensions.");
    assert(Entry[Instance.Part].size() == VF &&
           "ScalarParts has wrong dimensions.");
    return Entry[Instance.Part][Instance.Lane] != nullptr;
  }

  /// Retrieve the existing vector value that corresponds to \p Key and
  /// \p Part.
  Value *getVectorValue(Value *Key, unsigned Part) {
    assert(hasVectorValue(Key, Part) && "Getting non-existent value.");
    return VectorMapStorage[Key][Part];
  }

  /// Retrieve the existing scalar value that corresponds to \p Key and
  /// \p Instance.
  Value *getScalarValue(Value *Key, const VPIteration &Instance) {
    assert(hasScalarValue(Key, Instance) && "Getting non-existent value.");
    return ScalarMapStorage[Key][Instance.Part][Instance.Lane];
  }

  /// Set a vector value associated with \p Key and \p Part. Assumes such a
  /// value is not already set. If it is, use resetVectorValue() instead.
  void setVectorValue(Value *Key, unsigned Part, Value *Vector) {
    assert(!hasVectorValue(Key, Part) && "Vector value already set for part");
    if (!VectorMapStorage.count(Key)) {
      VectorParts Entry(UF);
      VectorMapStorage[Key] = Entry;
    }
    VectorMapStorage[Key][Part] = Vector;
  }

  /// Set a scalar value associated with \p Key and \p Instance. Assumes such a
  /// value is not already set.
  void setScalarValue(Value *Key, const VPIteration &Instance, Value *Scalar) {
    assert(!hasScalarValue(Key, Instance) && "Scalar value already set");
    if (!ScalarMapStorage.count(Key)) {
      ScalarParts Entry(UF);
      // TODO: Consider storing uniform values only per-part, as they occupy
      //       lane 0 only, keeping the other VF-1 redundant entries null.
      for (unsigned Part = 0; Part < UF; ++Part)
        Entry[Part].resize(VF, nullptr);
      ScalarMapStorage[Key] = Entry;
    }
    ScalarMapStorage[Key][Instance.Part][Instance.Lane] = Scalar;
  }

  /// Reset the vector value associated with \p Key for the given \p Part.
  /// This function can be used to update values that have already been
  /// vectorized. This is the case for "fix-up" operations including type
  /// truncation and the second phase of recurrence vectorization.
  void resetVectorValue(Value *Key, unsigned Part, Value *Vector) {
    assert(hasVectorValue(Key, Part) && "Vector value not set for part");
    VectorMapStorage[Key][Part] = Vector;
  }

  /// Reset the scalar value associated with \p Key for \p Part and \p Lane.
  /// This function can be used to update values that have already been
  /// scalarized. This is the case for "fix-up" operations including scalar phi
  /// nodes for scalarized and predicated instructions.
  void resetScalarValue(Value *Key, const VPIteration &Instance,
                        Value *Scalar) {
    assert(hasScalarValue(Key, Instance) &&
           "Scalar value not set for part and lane");
    ScalarMapStorage[Key][Instance.Part][Instance.Lane] = Scalar;
  }
};

/// This class is used to enable the VPlan to invoke a method of ILV. This is
/// needed until the method is refactored out of ILV and becomes reusable.
struct VPCallback {
  virtual ~VPCallback() {}
  virtual Value *getOrCreateVectorValues(Value *V, unsigned Part) = 0;
};

/// VPTransformState holds information passed down when "executing" a VPlan,
/// needed for generating the output IR.
struct VPTransformState {
  VPTransformState(unsigned VF, unsigned UF, LoopInfo *LI, DominatorTree *DT,
                   IRBuilder<> &Builder, VectorizerValueMap &ValueMap,
                   InnerLoopVectorizer *ILV, VPCallback &Callback)
      : VF(VF), UF(UF), Instance(), LI(LI), DT(DT), Builder(Builder),
        ValueMap(ValueMap), ILV(ILV), Callback(Callback) {}

  /// The chosen Vectorization and Unroll Factors of the loop being vectorized.
  unsigned VF;
  unsigned UF;

  /// Hold the indices to generate specific scalar instructions. Null indicates
  /// that all instances are to be generated, using either scalar or vector
  /// instructions.
  Optional<VPIteration> Instance;

  struct DataState {
    /// A type for vectorized values in the new loop. Each value from the
    /// original loop, when vectorized, is represented by UF vector values in
    /// the new unrolled loop, where UF is the unroll factor.
    typedef SmallVector<Value *, 2> PerPartValuesTy;

    DenseMap<VPValue *, PerPartValuesTy> PerPartOutput;
  } Data;

  /// Get the generated Value for a given VPValue and a given Part. Note that
  /// as some Defs are still created by ILV and managed in its ValueMap, this
  /// method will delegate the call to ILV in such cases in order to provide
  /// callers a consistent API.
  /// \see set.
  Value *get(VPValue *Def, unsigned Part) {
    // If Values have been set for this Def return the one relevant for \p Part.
    if (Data.PerPartOutput.count(Def))
      return Data.PerPartOutput[Def][Part];
    // Def is managed by ILV: bring the Values from ValueMap.
    return Callback.getOrCreateVectorValues(VPValue2Value[Def], Part);
  }

  /// Set the generated Value for a given VPValue and a given Part.
  void set(VPValue *Def, Value *V, unsigned Part) {
    if (!Data.PerPartOutput.count(Def)) {
      DataState::PerPartValuesTy Entry(UF);
      Data.PerPartOutput[Def] = Entry;
    }
    Data.PerPartOutput[Def][Part] = V;
  }

  /// Hold state information used when constructing the CFG of the output IR,
  /// traversing the VPBasicBlocks and generating corresponding IR BasicBlocks.
  struct CFGState {
    /// The previous VPBasicBlock visited. Initially set to null.
    VPBasicBlock *PrevVPBB = nullptr;

    /// The previous IR BasicBlock created or used. Initially set to the new
    /// header BasicBlock.
    BasicBlock *PrevBB = nullptr;

    /// The last IR BasicBlock in the output IR. Set to the new latch
    /// BasicBlock, used for placing the newly created BasicBlocks.
    BasicBlock *LastBB = nullptr;

    /// A mapping of each VPBasicBlock to the corresponding BasicBlock. In case
    /// of replication, maps the BasicBlock of the last replica created.
    SmallDenseMap<VPBasicBlock *, BasicBlock *> VPBB2IRBB;

    CFGState() = default;
  } CFG;

  /// Hold a pointer to LoopInfo to register new basic blocks in the loop.
  LoopInfo *LI;

  /// Hold a pointer to Dominator Tree to register new basic blocks in the loop.
  DominatorTree *DT;

  /// Hold a reference to the IRBuilder used to generate output IR code.
  IRBuilder<> &Builder;

  /// Hold a reference to the Value state information used when generating the
  /// Values of the output IR.
  VectorizerValueMap &ValueMap;

  /// Hold a reference to a mapping between VPValues in VPlan and original
  /// Values they correspond to.
  VPValue2ValueTy VPValue2Value;

  /// Hold a pointer to InnerLoopVectorizer to reuse its IR generation methods.
  InnerLoopVectorizer *ILV;

  VPCallback &Callback;
};

/// VPBlockBase is the building block of the Hierarchical Control-Flow Graph.
/// A VPBlockBase can be either a VPBasicBlock or a VPRegionBlock.
class VPBlockBase {
private:
  const unsigned char SubclassID; ///< Subclass identifier (for isa/dyn_cast).

  /// An optional name for the block.
  std::string Name;

  /// The immediate VPRegionBlock which this VPBlockBase belongs to, or null if
  /// it is a topmost VPBlockBase.
  VPRegionBlock *Parent = nullptr;

  /// List of predecessor blocks.
  SmallVector<VPBlockBase *, 1> Predecessors;

  /// List of successor blocks.
  SmallVector<VPBlockBase *, 1> Successors;

  /// Add \p Successor as the last successor to this block.
  void appendSuccessor(VPBlockBase *Successor) {
    assert(Successor && "Cannot add nullptr successor!");
    Successors.push_back(Successor);
  }

  /// Add \p Predecessor as the last predecessor to this block.
  void appendPredecessor(VPBlockBase *Predecessor) {
    assert(Predecessor && "Cannot add nullptr predecessor!");
    Predecessors.push_back(Predecessor);
  }

  /// Remove \p Predecessor from the predecessors of this block.
  void removePredecessor(VPBlockBase *Predecessor) {
    auto Pos = std::find(Predecessors.begin(), Predecessors.end(), Predecessor);
    assert(Pos && "Predecessor does not exist");
    Predecessors.erase(Pos);
  }

  /// Remove \p Successor from the successors of this block.
  void removeSuccessor(VPBlockBase *Successor) {
    auto Pos = std::find(Successors.begin(), Successors.end(), Successor);
    assert(Pos && "Successor does not exist");
    Successors.erase(Pos);
  }

protected:
  VPBlockBase(const unsigned char SC, const std::string &N)
      : SubclassID(SC), Name(N) {}

public:
  /// An enumeration for keeping track of the concrete subclass of VPBlockBase
  /// that are actually instantiated. Values of this enumeration are kept in the
  /// SubclassID field of the VPBlockBase objects. They are used for concrete
  /// type identification.
  using VPBlockTy = enum { VPBasicBlockSC, VPRegionBlockSC };

  using VPBlocksTy = SmallVectorImpl<VPBlockBase *>;

  virtual ~VPBlockBase() = default;

  const std::string &getName() const { return Name; }

  void setName(const Twine &newName) { Name = newName.str(); }

  /// \return an ID for the concrete type of this object.
  /// This is used to implement the classof checks. This should not be used
  /// for any other purpose, as the values may change as LLVM evolves.
  unsigned getVPBlockID() const { return SubclassID; }

  const VPRegionBlock *getParent() const { return Parent; }

  void setParent(VPRegionBlock *P) { Parent = P; }

  /// \return the VPBasicBlock that is the entry of this VPBlockBase,
  /// recursively, if the latter is a VPRegionBlock. Otherwise, if this
  /// VPBlockBase is a VPBasicBlock, it is returned.
  const VPBasicBlock *getEntryBasicBlock() const;
  VPBasicBlock *getEntryBasicBlock();

  /// \return the VPBasicBlock that is the exit of this VPBlockBase,
  /// recursively, if the latter is a VPRegionBlock. Otherwise, if this
  /// VPBlockBase is a VPBasicBlock, it is returned.
  const VPBasicBlock *getExitBasicBlock() const;
  VPBasicBlock *getExitBasicBlock();

  const VPBlocksTy &getSuccessors() const { return Successors; }
  VPBlocksTy &getSuccessors() { return Successors; }

  const VPBlocksTy &getPredecessors() const { return Predecessors; }
  VPBlocksTy &getPredecessors() { return Predecessors; }

  /// \return the successor of this VPBlockBase if it has a single successor.
  /// Otherwise return a null pointer.
  VPBlockBase *getSingleSuccessor() const {
    return (Successors.size() == 1 ? *Successors.begin() : nullptr);
  }

  /// \return the predecessor of this VPBlockBase if it has a single
  /// predecessor. Otherwise return a null pointer.
  VPBlockBase *getSinglePredecessor() const {
    return (Predecessors.size() == 1 ? *Predecessors.begin() : nullptr);
  }

  /// An Enclosing Block of a block B is any block containing B, including B
  /// itself. \return the closest enclosing block starting from "this", which
  /// has successors. \return the root enclosing block if all enclosing blocks
  /// have no successors.
  VPBlockBase *getEnclosingBlockWithSuccessors();

  /// \return the closest enclosing block starting from "this", which has
  /// predecessors. \return the root enclosing block if all enclosing blocks
  /// have no predecessors.
  VPBlockBase *getEnclosingBlockWithPredecessors();

  /// \return the successors either attached directly to this VPBlockBase or, if
  /// this VPBlockBase is the exit block of a VPRegionBlock and has no
  /// successors of its own, search recursively for the first enclosing
  /// VPRegionBlock that has successors and return them. If no such
  /// VPRegionBlock exists, return the (empty) successors of the topmost
  /// VPBlockBase reached.
  const VPBlocksTy &getHierarchicalSuccessors() {
    return getEnclosingBlockWithSuccessors()->getSuccessors();
  }

  /// \return the hierarchical successor of this VPBlockBase if it has a single
  /// hierarchical successor. Otherwise return a null pointer.
  VPBlockBase *getSingleHierarchicalSuccessor() {
    return getEnclosingBlockWithSuccessors()->getSingleSuccessor();
  }

  /// \return the predecessors either attached directly to this VPBlockBase or,
  /// if this VPBlockBase is the entry block of a VPRegionBlock and has no
  /// predecessors of its own, search recursively for the first enclosing
  /// VPRegionBlock that has predecessors and return them. If no such
  /// VPRegionBlock exists, return the (empty) predecessors of the topmost
  /// VPBlockBase reached.
  const VPBlocksTy &getHierarchicalPredecessors() {
    return getEnclosingBlockWithPredecessors()->getPredecessors();
  }

  /// \return the hierarchical predecessor of this VPBlockBase if it has a
  /// single hierarchical predecessor. Otherwise return a null pointer.
  VPBlockBase *getSingleHierarchicalPredecessor() {
    return getEnclosingBlockWithPredecessors()->getSinglePredecessor();
  }

  /// Sets a given VPBlockBase \p Successor as the single successor and \return
  /// \p Successor. The parent of this Block is copied to be the parent of
  /// \p Successor.
  VPBlockBase *setOneSuccessor(VPBlockBase *Successor) {
    assert(Successors.empty() && "Setting one successor when others exist.");
    appendSuccessor(Successor);
    Successor->appendPredecessor(this);
    Successor->Parent = Parent;
    return Successor;
  }

  /// Sets two given VPBlockBases \p IfTrue and \p IfFalse to be the two
  /// successors. The parent of this Block is copied to be the parent of both
  /// \p IfTrue and \p IfFalse.
  void setTwoSuccessors(VPBlockBase *IfTrue, VPBlockBase *IfFalse) {
    assert(Successors.empty() && "Setting two successors when others exist.");
    appendSuccessor(IfTrue);
    appendSuccessor(IfFalse);
    IfTrue->appendPredecessor(this);
    IfFalse->appendPredecessor(this);
    IfTrue->Parent = Parent;
    IfFalse->Parent = Parent;
  }

  void disconnectSuccessor(VPBlockBase *Successor) {
    assert(Successor && "Successor to disconnect is null.");
    removeSuccessor(Successor);
    Successor->removePredecessor(this);
  }

  /// The method which generates the output IR that correspond to this
  /// VPBlockBase, thereby "executing" the VPlan.
  virtual void execute(struct VPTransformState *State) = 0;

  /// Delete all blocks reachable from a given VPBlockBase, inclusive.
  static void deleteCFG(VPBlockBase *Entry);
};

/// VPRecipeBase is a base class modeling a sequence of one or more output IR
/// instructions.
class VPRecipeBase : public ilist_node_with_parent<VPRecipeBase, VPBasicBlock> {
  friend VPBasicBlock;

private:
  const unsigned char SubclassID; ///< Subclass identifier (for isa/dyn_cast).

  /// Each VPRecipe belongs to a single VPBasicBlock.
  VPBasicBlock *Parent = nullptr;

public:
  /// An enumeration for keeping track of the concrete subclass of VPRecipeBase
  /// that is actually instantiated. Values of this enumeration are kept in the
  /// SubclassID field of the VPRecipeBase objects. They are used for concrete
  /// type identification.
  using VPRecipeTy = enum {
    VPBlendSC,
    VPBranchOnMaskSC,
    VPInstructionSC,
    VPInterleaveSC,
    VPPredInstPHISC,
    VPReplicateSC,
    VPWidenIntOrFpInductionSC,
    VPWidenMemoryInstructionSC,
    VPWidenPHISC,
    VPWidenSC,
  };

  VPRecipeBase(const unsigned char SC) : SubclassID(SC) {}
  virtual ~VPRecipeBase() = default;

  /// \return an ID for the concrete type of this object.
  /// This is used to implement the classof checks. This should not be used
  /// for any other purpose, as the values may change as LLVM evolves.
  unsigned getVPRecipeID() const { return SubclassID; }

  /// \return the VPBasicBlock which this VPRecipe belongs to.
  VPBasicBlock *getParent() { return Parent; }
  const VPBasicBlock *getParent() const { return Parent; }

  /// The method which generates the output IR instructions that correspond to
  /// this VPRecipe, thereby "executing" the VPlan.
  virtual void execute(struct VPTransformState &State) = 0;

  /// Each recipe prints itself.
  virtual void print(raw_ostream &O, const Twine &Indent) const = 0;
};

/// This is a concrete Recipe that models a single VPlan-level instruction.
/// While as any Recipe it may generate a sequence of IR instructions when
/// executed, these instructions would always form a single-def expression as
/// the VPInstruction is also a single def-use vertex.
class VPInstruction : public VPUser, public VPRecipeBase {
public:
  /// VPlan opcodes, extending LLVM IR with idiomatics instructions.
  enum { Not = Instruction::OtherOpsEnd + 1 };

private:
  typedef unsigned char OpcodeTy;
  OpcodeTy Opcode;

  /// Utility method serving execute(): generates a single instance of the
  /// modeled instruction.
  void generateInstruction(VPTransformState &State, unsigned Part);

public:
  VPInstruction(unsigned Opcode, std::initializer_list<VPValue *> Operands)
      : VPUser(VPValue::VPInstructionSC, Operands),
        VPRecipeBase(VPRecipeBase::VPInstructionSC), Opcode(Opcode) {}

  /// Method to support type inquiry through isa, cast, and dyn_cast.
  static inline bool classof(const VPValue *V) {
    return V->getVPValueID() == VPValue::VPInstructionSC;
  }

  /// Method to support type inquiry through isa, cast, and dyn_cast.
  static inline bool classof(const VPRecipeBase *R) {
    return R->getVPRecipeID() == VPRecipeBase::VPInstructionSC;
  }

  unsigned getOpcode() const { return Opcode; }

  /// Generate the instruction.
  /// TODO: We currently execute only per-part unless a specific instance is
  /// provided.
  void execute(VPTransformState &State) override;

  /// Print the Recipe.
  void print(raw_ostream &O, const Twine &Indent) const override;

  /// Print the VPInstruction.
  void print(raw_ostream &O) const;
};

/// VPBasicBlock serves as the leaf of the Hierarchical Control-Flow Graph. It
/// holds a sequence of zero or more VPRecipe's each representing a sequence of
/// output IR instructions.
class VPBasicBlock : public VPBlockBase {
public:
  using RecipeListTy = iplist<VPRecipeBase>;

private:
  /// The VPRecipes held in the order of output instructions to generate.
  RecipeListTy Recipes;

public:
  VPBasicBlock(const Twine &Name = "", VPRecipeBase *Recipe = nullptr)
      : VPBlockBase(VPBasicBlockSC, Name.str()) {
    if (Recipe)
      appendRecipe(Recipe);
  }

  ~VPBasicBlock() override { Recipes.clear(); }

  /// Instruction iterators...
  using iterator = RecipeListTy::iterator;
  using const_iterator = RecipeListTy::const_iterator;
  using reverse_iterator = RecipeListTy::reverse_iterator;
  using const_reverse_iterator = RecipeListTy::const_reverse_iterator;

  //===--------------------------------------------------------------------===//
  /// Recipe iterator methods
  ///
  inline iterator begin() { return Recipes.begin(); }
  inline const_iterator begin() const { return Recipes.begin(); }
  inline iterator end() { return Recipes.end(); }
  inline const_iterator end() const { return Recipes.end(); }

  inline reverse_iterator rbegin() { return Recipes.rbegin(); }
  inline const_reverse_iterator rbegin() const { return Recipes.rbegin(); }
  inline reverse_iterator rend() { return Recipes.rend(); }
  inline const_reverse_iterator rend() const { return Recipes.rend(); }

  inline size_t size() const { return Recipes.size(); }
  inline bool empty() const { return Recipes.empty(); }
  inline const VPRecipeBase &front() const { return Recipes.front(); }
  inline VPRecipeBase &front() { return Recipes.front(); }
  inline const VPRecipeBase &back() const { return Recipes.back(); }
  inline VPRecipeBase &back() { return Recipes.back(); }

  /// \brief Returns a pointer to a member of the recipe list.
  static RecipeListTy VPBasicBlock::*getSublistAccess(VPRecipeBase *) {
    return &VPBasicBlock::Recipes;
  }

  /// Method to support type inquiry through isa, cast, and dyn_cast.
  static inline bool classof(const VPBlockBase *V) {
    return V->getVPBlockID() == VPBlockBase::VPBasicBlockSC;
  }

  void insert(VPRecipeBase *Recipe, iterator InsertPt) {
    assert(Recipe && "No recipe to append.");
    assert(!Recipe->Parent && "Recipe already in VPlan");
    Recipe->Parent = this;
    Recipes.insert(InsertPt, Recipe);
  }

  /// Augment the existing recipes of a VPBasicBlock with an additional
  /// \p Recipe as the last recipe.
  void appendRecipe(VPRecipeBase *Recipe) { insert(Recipe, end()); }

  /// The method which generates the output IR instructions that correspond to
  /// this VPBasicBlock, thereby "executing" the VPlan.
  void execute(struct VPTransformState *State) override;

private:
  /// Create an IR BasicBlock to hold the output instructions generated by this
  /// VPBasicBlock, and return it. Update the CFGState accordingly.
  BasicBlock *createEmptyBasicBlock(VPTransformState::CFGState &CFG);
};

/// VPRegionBlock represents a collection of VPBasicBlocks and VPRegionBlocks
/// which form a Single-Entry-Single-Exit subgraph of the output IR CFG.
/// A VPRegionBlock may indicate that its contents are to be replicated several
/// times. This is designed to support predicated scalarization, in which a
/// scalar if-then code structure needs to be generated VF * UF times. Having
/// this replication indicator helps to keep a single model for multiple
/// candidate VF's. The actual replication takes place only once the desired VF
/// and UF have been determined.
class VPRegionBlock : public VPBlockBase {
private:
  /// Hold the Single Entry of the SESE region modelled by the VPRegionBlock.
  VPBlockBase *Entry;

  /// Hold the Single Exit of the SESE region modelled by the VPRegionBlock.
  VPBlockBase *Exit;

  /// An indicator whether this region is to generate multiple replicated
  /// instances of output IR corresponding to its VPBlockBases.
  bool IsReplicator;

public:
  VPRegionBlock(VPBlockBase *Entry, VPBlockBase *Exit,
                const std::string &Name = "", bool IsReplicator = false)
      : VPBlockBase(VPRegionBlockSC, Name), Entry(Entry), Exit(Exit),
        IsReplicator(IsReplicator) {
    assert(Entry->getPredecessors().empty() && "Entry block has predecessors.");
    assert(Exit->getSuccessors().empty() && "Exit block has successors.");
    Entry->setParent(this);
    Exit->setParent(this);
  }

  ~VPRegionBlock() override {
    if (Entry)
      deleteCFG(Entry);
  }

  /// Method to support type inquiry through isa, cast, and dyn_cast.
  static inline bool classof(const VPBlockBase *V) {
    return V->getVPBlockID() == VPBlockBase::VPRegionBlockSC;
  }

  const VPBlockBase *getEntry() const { return Entry; }
  VPBlockBase *getEntry() { return Entry; }

  const VPBlockBase *getExit() const { return Exit; }
  VPBlockBase *getExit() { return Exit; }

  /// An indicator whether this region is to generate multiple replicated
  /// instances of output IR corresponding to its VPBlockBases.
  bool isReplicator() const { return IsReplicator; }

  /// The method which generates the output IR instructions that correspond to
  /// this VPRegionBlock, thereby "executing" the VPlan.
  void execute(struct VPTransformState *State) override;
};

/// VPlan models a candidate for vectorization, encoding various decisions take
/// to produce efficient output IR, including which branches, basic-blocks and
/// output IR instructions to generate, and their cost. VPlan holds a
/// Hierarchical-CFG of VPBasicBlocks and VPRegionBlocks rooted at an Entry
/// VPBlock.
class VPlan {
  friend class VPlanPrinter;

private:
  /// Hold the single entry to the Hierarchical CFG of the VPlan.
  VPBlockBase *Entry;

  /// Holds the VFs applicable to this VPlan.
  SmallSet<unsigned, 2> VFs;

  /// Holds the name of the VPlan, for printing.
  std::string Name;

  /// Holds a mapping between Values and their corresponding VPValue inside
  /// VPlan.
  Value2VPValueTy Value2VPValue;

public:
  VPlan(VPBlockBase *Entry = nullptr) : Entry(Entry) {}

  ~VPlan() {
    if (Entry)
      VPBlockBase::deleteCFG(Entry);
    for (auto &MapEntry : Value2VPValue)
      delete MapEntry.second;
  }

  /// Generate the IR code for this VPlan.
  void execute(struct VPTransformState *State);

  VPBlockBase *getEntry() { return Entry; }
  const VPBlockBase *getEntry() const { return Entry; }

  VPBlockBase *setEntry(VPBlockBase *Block) { return Entry = Block; }

  void addVF(unsigned VF) { VFs.insert(VF); }

  bool hasVF(unsigned VF) { return VFs.count(VF); }

  const std::string &getName() const { return Name; }

  void setName(const Twine &newName) { Name = newName.str(); }

  void addVPValue(Value *V) {
    assert(V && "Trying to add a null Value to VPlan");
    assert(!Value2VPValue.count(V) && "Value already exists in VPlan");
    Value2VPValue[V] = new VPValue();
  }

  VPValue *getVPValue(Value *V) {
    assert(V && "Trying to get the VPValue of a null Value");
    assert(Value2VPValue.count(V) && "Value does not exist in VPlan");
    return Value2VPValue[V];
  }

private:
  /// Add to the given dominator tree the header block and every new basic block
  /// that was created between it and the latch block, inclusive.
  static void updateDominatorTree(DominatorTree *DT,
                                  BasicBlock *LoopPreHeaderBB,
                                  BasicBlock *LoopLatchBB);
};

/// VPlanPrinter prints a given VPlan to a given output stream. The printing is
/// indented and follows the dot format.
class VPlanPrinter {
  friend inline raw_ostream &operator<<(raw_ostream &OS, VPlan &Plan);
  friend inline raw_ostream &operator<<(raw_ostream &OS,
                                        const struct VPlanIngredient &I);

private:
  raw_ostream &OS;
  VPlan &Plan;
  unsigned Depth;
  unsigned TabWidth = 2;
  std::string Indent;
  unsigned BID = 0;
  SmallDenseMap<const VPBlockBase *, unsigned> BlockID;

  VPlanPrinter(raw_ostream &O, VPlan &P) : OS(O), Plan(P) {}

  /// Handle indentation.
  void bumpIndent(int b) { Indent = std::string((Depth += b) * TabWidth, ' '); }

  /// Print a given \p Block of the Plan.
  void dumpBlock(const VPBlockBase *Block);

  /// Print the information related to the CFG edges going out of a given
  /// \p Block, followed by printing the successor blocks themselves.
  void dumpEdges(const VPBlockBase *Block);

  /// Print a given \p BasicBlock, including its VPRecipes, followed by printing
  /// its successor blocks.
  void dumpBasicBlock(const VPBasicBlock *BasicBlock);

  /// Print a given \p Region of the Plan.
  void dumpRegion(const VPRegionBlock *Region);

  unsigned getOrCreateBID(const VPBlockBase *Block) {
    return BlockID.count(Block) ? BlockID[Block] : BlockID[Block] = BID++;
  }

  const Twine getOrCreateName(const VPBlockBase *Block);

  const Twine getUID(const VPBlockBase *Block);

  /// Print the information related to a CFG edge between two VPBlockBases.
  void drawEdge(const VPBlockBase *From, const VPBlockBase *To, bool Hidden,
                const Twine &Label);

  void dump();

  static void printAsIngredient(raw_ostream &O, Value *V);
};

struct VPlanIngredient {
  Value *V;

  VPlanIngredient(Value *V) : V(V) {}
};

inline raw_ostream &operator<<(raw_ostream &OS, const VPlanIngredient &I) {
  VPlanPrinter::printAsIngredient(OS, I.V);
  return OS;
}

inline raw_ostream &operator<<(raw_ostream &OS, VPlan &Plan) {
  VPlanPrinter Printer(OS, Plan);
  Printer.dump();
  return OS;
}

//===--------------------------------------------------------------------===//
// GraphTraits specializations for VPlan/VPRegionBlock Control-Flow Graphs  //
//===--------------------------------------------------------------------===//

// Provide specializations of GraphTraits to be able to treat a VPBlockBase as a
// graph of VPBlockBase nodes...

template <> struct GraphTraits<VPBlockBase *> {
  using NodeRef = VPBlockBase *;
  using ChildIteratorType = SmallVectorImpl<VPBlockBase *>::iterator;

  static NodeRef getEntryNode(NodeRef N) { return N; }

  static inline ChildIteratorType child_begin(NodeRef N) {
    return N->getSuccessors().begin();
  }

  static inline ChildIteratorType child_end(NodeRef N) {
    return N->getSuccessors().end();
  }
};

template <> struct GraphTraits<const VPBlockBase *> {
  using NodeRef = const VPBlockBase *;
  using ChildIteratorType = SmallVectorImpl<VPBlockBase *>::const_iterator;

  static NodeRef getEntryNode(NodeRef N) { return N; }

  static inline ChildIteratorType child_begin(NodeRef N) {
    return N->getSuccessors().begin();
  }

  static inline ChildIteratorType child_end(NodeRef N) {
    return N->getSuccessors().end();
  }
};

// Provide specializations of GraphTraits to be able to treat a VPBlockBase as a
// graph of VPBlockBase nodes... and to walk it in inverse order. Inverse order
// for a VPBlockBase is considered to be when traversing the predecessors of a
// VPBlockBase instead of its successors.
template <> struct GraphTraits<Inverse<VPBlockBase *>> {
  using NodeRef = VPBlockBase *;
  using ChildIteratorType = SmallVectorImpl<VPBlockBase *>::iterator;

  static Inverse<VPBlockBase *> getEntryNode(Inverse<VPBlockBase *> B) {
    return B;
  }

  static inline ChildIteratorType child_begin(NodeRef N) {
    return N->getPredecessors().begin();
  }

  static inline ChildIteratorType child_end(NodeRef N) {
    return N->getPredecessors().end();
  }
};

} // end namespace llvm

#endif // LLVM_TRANSFORMS_VECTORIZE_VPLAN_H
